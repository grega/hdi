# hdi (Go)

Go port of [hdi](https://github.com/grega/hdi) using the [Charm BubbleTea](https://github.com/charmbracelet/bubbletea) framework.

This is a feature-complete reimplementation of the Bash version with full parity across all modes, output formats, and the interactive picker.

## Build

```bash
go build -o hdi ./cmd/hdi/
```

Or using the Makefile:

```bash
make build
```

## Usage

Same CLI interface as the Bash version:

```
hdi                           Interactive picker (default)
hdi install                   Install/setup commands (aliases: setup, i)
hdi run                       Run/start commands (aliases: start, r)
hdi test                      Test commands (alias: t)
hdi deploy                    Deploy commands + platform detection (alias: d)
hdi all                       All matched sections (alias: a)
hdi contrib                   Contributor doc commands (alias: c)
hdi needs                     Check required tools (alias: n)

hdi [mode] --full             Include prose around commands
hdi [mode] --raw              Plain markdown (no colour)
hdi [mode] --no-interactive   Non-interactive output (alias: --ni)
hdi --json                    Structured JSON output
hdi [mode] /path              Scan specific directory
hdi [mode] /path/file.md      Parse specific file
```

## Tests

```bash
make test
```

This runs:
- **Unit tests** (`internal/markdown/`) - parser and extractor
- **Integration tests** (`internal/`) - 75 tests running the compiled binary against the same fixtures used by the Bash version's BATS test suite

## Architecture

```
cmd/hdi/              CLI entry point and argument parsing
internal/
  config/             Mode, flags, and version constants
  markdown/           Markdown section parser and command extractor
    keywords.go       Keyword regex patterns per mode
    parser.go         Section extraction (ATX, setext, bold headings)
    extract.go        Command extraction (fenced, inline, indented, console)
  display/            Flat display list builder with deduplication
  readme/             README and contributor doc discovery
  render/             Non-interactive renderers (static, full, raw)
  tui/                BubbleTea interactive picker
    model.go          Elm architecture model (Init, Update, View)
    keymap.go         Key bindings (bubbles/key)
    styles.go         Lip Gloss styles
    viewport.go       Viewport/scroll management
  jsonout/            JSON output generation
  platform/           Deploy platform detection (files, commands, prose)
  needs/              Tool availability checking
  clipboard/          Cross-platform clipboard (pbcopy/wl-copy/xclip/xsel)
```

## Dependencies

- [bubbletea](https://github.com/charmbracelet/bubbletea) - TUI framework
- [bubbles](https://github.com/charmbracelet/bubbles) - key bindings
- [lipgloss](https://github.com/charmbracelet/lipgloss) - terminal styling
- Go standard library for everything else
