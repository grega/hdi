# Redesign hdi TUI with Charmbracelet Bubbles

## Context

hdi's original TUI was a hand-rolled picker built on bubbletea + lipgloss. It manually managed a flat `DisplayList` of heterogeneous line types (headers, subheaders, commands, separators), a custom viewport with scroll tracking, and cursor management that skipped non-command lines. The Bubbles component library provides battle-tested, composable components (List, Table, Viewport, Help, Spinner, etc.) that handle all of this natively.

## Current Implementation (Option A: Mixed item types in `list.Model`)

### Core: `bubbles/list` with mixed item types

The `list.Model` contains a mixed list of item types: section headers, sub-headers, spacers, file separators, and commands. Only commands are selectable — the cursor skips over structural items automatically.

**Item types** (all implement `list.Item` + a `Selectable` interface):

```go
CommandItem   // selectable — executable command
SectionItem   // non-selectable — rendered as " ▸ Title ──────────"
SubHeaderItem // non-selectable — rendered as styled sub-heading
SpacerItem    // non-selectable — blank row between sections
FileSepItem   // non-selectable — rendered as "══ filename.md ════"
```

The visual result preserves the original hdi hierarchy:
```
 ▸ Installation ──────────────────
    brew install grega/tap/hdi
    brew update

 ▸ Running ───────────────────────
 ▶ npm run dev
    npm run build

 ▸ Testing ───────────────────────
    npm test
```

**Skip logic**: after every `list.Update()`, if the cursor moved onto a non-selectable item, `skipToSelectable(dir)` nudges it in the direction of travel.

**Filtering**: structural items return `""` from `FilterValue()`, so fuzzy search naturally shows only commands. When filtering is active, headers/spacers are excluded by the list.

**Data model** — `CommandSet` holds both the mixed list and per-category variants:
```go
type CommandSet struct {
    All        []list.Item          // mixed: headers + commands + spacers
    Commands   []CommandItem        // just commands (for needs view, etc.)
    ByCategory map[string][]list.Item // per-category mixed lists
    Categories []string
}
```

Category switching (`Tab`) calls `list.SetItems()` with the appropriate subset. Each subset has its own section headers and spacers, so the structure is preserved within categories.

### Features we get for free from `list.Model`

- **Fuzzy search** (`/` key)
- **Pagination** with dot indicators
- **Viewport/scroll management**
- **Status bar** for flash messages (copy confirmation)
- **Help overlay** (`?` toggle)
- **Window resize handling**

### Known trade-offs of Option A

- Section headers count toward the item count and pagination
- The skip logic adds some complexity to Update
- Fixed height of 1 per item means visual breaks between sections use a spacer row rather than flexible whitespace
- The list's built-in item counter includes non-selectable items

## Alternative: Option B (compose from smaller components)

If Option A's trade-offs become too limiting, we can drop `list.Model` entirely and compose from individual Bubbles components:

- `viewport.Model` — scrollable content with full rendering control (variable row heights, flexible whitespace, exact layout matching the original hdi)
- `textinput.Model` — filter input (the `sahilm/fuzzy` package is already a transitive dependency via bubbles/list)
- `help.Model` — keybinding help overlay
- `key` — keybinding definitions
- `lipgloss` — all styling

This gives pixel-perfect control over headers, spacing, and rules — exactly like the original hdi layout. We'd reuse the cursor-skips-headers pattern from the old code (tracking `cmdIndices` separately). The fuzzy search would be new code but straightforward with `sahilm/fuzzy`.

**What we'd reimplement**: pagination, status messages, item counting. Each piece is simple and the total code would be comparable to Option A.

**When to switch**: if the spacing/layout constraints of `list.Model` become a significant UX issue, or if the skip logic causes edge cases with pagination boundaries.

## Other Components

### `bubbles/help` replaces manual footer

The list's built-in `help.Model` provides `ShortHelp()` / `FullHelp()` via the `?` toggle. Custom keybindings are injected through `AdditionalShortHelpKeys` and `AdditionalFullHelpKeys`.

### `bubbles/table` for NeedsView

`hdi needs` uses a `table.Model` with columns for status, tool name, and version. Accessible from the picker via `n` key, or directly via `hdi needs`. Esc returns to picker.

### `bubbles/viewport` for FullView

`hdi --full` prose output is an interactive scrollable `viewport.Model` with pre-rendered lipgloss content. Accessible from picker via `F` key. j/k/arrows scroll, Esc returns.

### Components NOT used (and why)

| Component | Why not |
|-----------|---------|
| TextInput | List has built-in filter input |
| TextArea | No multi-line input use case |
| FilePicker | README discovery is automatic; `--file` is a CLI escape hatch |
| Progress | Command duration is unpredictable; spinner is better |
| Timer/Stopwatch | No use case |
| Paginator | List includes its own |

## App Architecture

```
AppModel (view router)
├── PickerModel  (list.Model + skip logic + category state)  ← primary view
├── ExecViewModel                                             ← after Enter
├── NeedsViewModel  (table.Model)                             ← 'n' key
└── FullViewModel   (viewport.Model)                          ← 'F' key
```

Standard bubbletea multi-view pattern: `AppModel.Update()` routes to active view, `AppModel.View()` delegates to active view's render.

### Theme

A unified color palette in `theme.go` using `AdaptiveColor` for light/dark terminal support:
- Accent (coral/crimson) — brand, filter prompt, active pagination
- Commands (mint/forest) — executable text
- Sections (lavender/purple) — structural headers
- Sub-headers (rose/fuchsia)
- Title (gold/amber) — project name
- Success/error — green/red
- File separators (peach/orange)
- Selection background (deep purple / pale lavender)

## Key Interaction Changes

| Current | New | Why |
|---------|-----|-----|
| Tab = jump to next section | Tab = cycle category filter | Category switching is more useful; `/` search replaces section jump |
| Shift+Tab = prev section | (removed) | Search is better |
| f = jump to next file | (removed) | Search covers this |
| No search capability | `/` = fuzzy filter | Killer feature from List |
| No help overlay | `?` = toggle full help | Free from List + Help |
| Mode locked at launch | Tab cycles modes live | More flexible |
| n/F not available | `n` = needs, `f` = full prose | In-app view switching |

## Data Pipeline

```
Current:  README -> Section -> DisplayList (flat lines) -> tui.Model (manual viewport)
New:      README -> Section -> CommandSet (mixed items)  -> list.Model (Bubbles handles display)
```

`DisplayList` and `render/` package remain unchanged for non-interactive output modes (static, raw, JSON).

## File Structure

### TUI package (`go/internal/tui/`)
- `app.go` — top-level AppModel (view routing, shared state, header rendering)
- `picker.go` — PickerModel wrapping list.Model, skip logic, category cycling
- `delegate.go` — custom delegate rendering all item types (sections, commands, spacers, etc.)
- `items.go` — item types, CommandSet builder, category detection
- `execview.go` — post-execution result screen
- `needsview.go` — table-based tool dependency display
- `fullview.go` — viewport-based prose view
- `theme.go` — unified color palette with AdaptiveColor

### Modified from original
- `go/cmd/hdi/main.go` — wires `CommandSet` into `runInteractive()`, non-interactive paths unchanged
- `go/internal/render/static.go` — fixed dash rendering (byte/rune slicing bug)

### Deleted
- `model.go` — replaced by app.go + picker.go
- `viewport.go` — replaced by list's built-in viewport
- `keymap.go` — keybindings now inline in picker.go
- `styles.go` — styles now inline in delegate.go + theme.go

### Unchanged
- `go/internal/markdown/` — all parsing
- `go/internal/display/` — DisplayList for non-interactive paths
- `go/internal/render/` — static/raw/full non-interactive rendering
- `go/internal/platform/` — detection
- `go/internal/clipboard/` — clipboard support
- `go/internal/needs/` — tool checking logic
- `go/internal/jsonout/` — JSON output
- `go/internal/readme/` — README discovery

## Bugs Fixed

- **Dash divider corruption**: `dashPool[:n]` sliced a multi-byte string (`─` = 3 bytes UTF-8) by byte index, producing `�` when `n` wasn't a multiple of 3. Fixed by using `strings.Repeat("─", n)` with rune-counted widths.
