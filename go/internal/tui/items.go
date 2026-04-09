package tui

import (
	"regexp"
	"strings"

	"github.com/charmbracelet/bubbles/list"
	"github.com/grega/hdi/internal/config"
	"github.com/grega/hdi/internal/markdown"
)

// Item types for the mixed list.

// CommandItem represents a single executable command.
type CommandItem struct {
	Cmd        string
	Section    string
	SubSection string
	SourceFile string
	Category   string
}

func (i CommandItem) Title() string       { return i.Cmd }
func (i CommandItem) Description() string { return "" }
func (i CommandItem) FilterValue() string { return i.Cmd + " " + i.Section }
func (i CommandItem) IsSelectable() bool  { return true }

// SectionItem is a non-selectable section header.
type SectionItem struct {
	Name       string
	SourceFile string
	Category   string
}

func (i SectionItem) Title() string       { return i.Name }
func (i SectionItem) Description() string { return "" }
func (i SectionItem) FilterValue() string { return "" } // excluded from search
func (i SectionItem) IsSelectable() bool  { return false }

// SubHeaderItem is a non-selectable sub-heading within a section.
type SubHeaderItem struct {
	Name string
}

func (i SubHeaderItem) Title() string       { return i.Name }
func (i SubHeaderItem) Description() string { return "" }
func (i SubHeaderItem) FilterValue() string { return "" }
func (i SubHeaderItem) IsSelectable() bool  { return false }

// SpacerItem is a non-selectable blank line between sections.
type SpacerItem struct{}

func (i SpacerItem) Title() string       { return "" }
func (i SpacerItem) Description() string { return "" }
func (i SpacerItem) FilterValue() string { return "" }
func (i SpacerItem) IsSelectable() bool  { return false }

// FileSepItem is a non-selectable file separator.
type FileSepItem struct {
	Name string
}

func (i FileSepItem) Title() string       { return i.Name }
func (i FileSepItem) Description() string { return "" }
func (i FileSepItem) FilterValue() string { return "" }
func (i FileSepItem) IsSelectable() bool  { return false }

// Selectable is implemented by all item types to distinguish commands from chrome.
type Selectable interface {
	IsSelectable() bool
}

// isSelectable checks if a list.Item is a selectable command.
func isSelectable(item list.Item) bool {
	if s, ok := item.(Selectable); ok {
		return s.IsSelectable()
	}
	return false
}

// CommandSet holds all items organized for the TUI.
type CommandSet struct {
	// All contains the full mixed list (headers + commands + spacers).
	All []list.Item
	// Commands contains only the CommandItems (for needs view, etc.).
	Commands []CommandItem
	// ByCategory maps category keys to mixed lists with headers.
	ByCategory map[string][]list.Item
	// Categories is the ordered list of non-empty category keys found.
	Categories []string
}

// Category keyword patterns.
var (
	reInstall = regexp.MustCompile(`(?i)(` + kwInstall + `)`)
	reRun     = regexp.MustCompile(`(?i)(` + kwRun + `)`)
	reTest    = regexp.MustCompile(`(?i)(` + kwTest + `)`)
	reDeploy  = regexp.MustCompile(`(?i)(` + kwDeploy + `)`)
)

const (
	kwInstall = `prerequisite(s)?|require(ments)?|depend(encies)?|install(ing|ation)?|setup|set[. _-]up|getting[. _-]started|quick[. _-]start|quickstart|how[. _-]to|docker|migration|database[. _-]setup`
	kwRun     = `^usage|run(ning)?|start(ing)?|dev|develop(ment|ing)?|dev[. _-]server|launch(ing)?|command|scripts|makefile|make[. _-]targets`
	kwTest    = `test(s|ing)?`
	kwDeploy  = `deploy(ment|ing)?|ship(ping)?|release|publish(ing)?|provision(ing)?|rollout|ci[/-]?cd|pipeline`
)

func detectCategory(title string) string {
	if reInstall.MatchString(title) {
		return "install"
	}
	if reRun.MatchString(title) {
		return "run"
	}
	if reTest.MatchString(title) {
		return "test"
	}
	if reDeploy.MatchString(title) {
		return "deploy"
	}
	return ""
}

func categoryForMode(mode config.Mode) string {
	switch mode {
	case config.ModeInstall:
		return "install"
	case config.ModeRun:
		return "run"
	case config.ModeTest:
		return "test"
	case config.ModeDeploy:
		return "deploy"
	default:
		return ""
	}
}

// BuildCommandSet converts parsed markdown sections into a structured CommandSet
// with interleaved section headers, sub-headers, commands, and spacers.
func BuildCommandSet(sections []markdown.Section) *CommandSet {
	cs := &CommandSet{
		ByCategory: make(map[string][]list.Item),
	}

	prevSource := ""

	for i, sec := range sections {
		category := detectCategory(sec.Title)

		// File separator when source changes
		if prevSource != "" && sec.Source != "" && sec.Source != prevSource {
			cs.All = append(cs.All, FileSepItem{Name: baseName(sec.Source)})
		}
		prevSource = sec.Source

		// Spacer before sections (except the first)
		if i > 0 {
			last := cs.All[len(cs.All)-1]
			if _, isSep := last.(FileSepItem); !isSep {
				cs.All = append(cs.All, SpacerItem{})
			}
		}

		// Section header
		cs.All = append(cs.All, SectionItem{
			Name:       sec.Title,
			SourceFile: sec.Source,
			Category:   category,
		})

		hasCmds := false

		// Commands from heading backticks
		titleCmds := markdown.FindBacktickCommands(sec.Title, false)
		for _, cmd := range titleCmds {
			if cmd == "" {
				continue
			}
			item := CommandItem{
				Cmd:        cmd,
				Section:    sec.Title,
				SourceFile: sec.Source,
				Category:   category,
			}
			cs.All = append(cs.All, item)
			cs.Commands = append(cs.Commands, item)
			hasCmds = true
		}

		// Commands from body
		cmds := markdown.ExtractCommands(sec.Body, true)
		cmds = deduplicatePerGroup(cmds)

		currentSub := ""
		for _, entry := range cmds {
			if entry == "" {
				continue
			}
			if strings.HasPrefix(entry, markdown.SubHeaderMarker) {
				currentSub = entry[len(markdown.SubHeaderMarker):]
				cs.All = append(cs.All, SubHeaderItem{Name: currentSub})
				continue
			}
			item := CommandItem{
				Cmd:        entry,
				Section:    sec.Title,
				SubSection: currentSub,
				SourceFile: sec.Source,
				Category:   category,
			}
			cs.All = append(cs.All, item)
			cs.Commands = append(cs.Commands, item)
			hasCmds = true
		}

		// If no commands found, skip this section from the list
		if !hasCmds {
			// Remove the section header (and spacer) we just added
			for len(cs.All) > 0 {
				switch cs.All[len(cs.All)-1].(type) {
				case CommandItem:
					goto doneRemoving
				default:
					cs.All = cs.All[:len(cs.All)-1]
				}
			}
		doneRemoving:
		}
	}

	// Build per-category lists (with their own headers and spacers)
	cs.buildCategoryLists()

	return cs
}

// buildCategoryLists creates filtered lists per category, maintaining structure.
func (cs *CommandSet) buildCategoryLists() {
	catSeen := make(map[string]bool)

	// Group commands by category, tracking which sections have been emitted
	type sectionGroup struct {
		header SectionItem
		items  []list.Item // sub-headers + commands
	}

	catGroups := make(map[string][]sectionGroup)
	var currentHeader *SectionItem

	for _, item := range cs.All {
		switch v := item.(type) {
		case SectionItem:
			currentHeader = &v
		case SubHeaderItem:
			if currentHeader != nil && currentHeader.Category != "" {
				cat := currentHeader.Category
				groups := catGroups[cat]
				if len(groups) == 0 || groups[len(groups)-1].header.Name != currentHeader.Name {
					groups = append(groups, sectionGroup{header: *currentHeader})
				}
				groups[len(groups)-1].items = append(groups[len(groups)-1].items, v)
				catGroups[cat] = groups
			}
		case CommandItem:
			if v.Category != "" {
				cat := v.Category
				groups := catGroups[cat]
				if len(groups) == 0 || groups[len(groups)-1].header.Name != v.Section {
					if currentHeader != nil {
						groups = append(groups, sectionGroup{header: *currentHeader})
					}
				}
				groups[len(groups)-1].items = append(groups[len(groups)-1].items, v)
				catGroups[cat] = groups
				if !catSeen[cat] {
					catSeen[cat] = true
					cs.Categories = append(cs.Categories, cat)
				}
			}
		}
	}

	// Flatten groups into list items
	for cat, groups := range catGroups {
		var items []list.Item
		for i, g := range groups {
			if i > 0 {
				items = append(items, SpacerItem{})
			}
			items = append(items, g.header)
			items = append(items, g.items...)
		}
		cs.ByCategory[cat] = items
	}
}

func baseName(path string) string {
	i := strings.LastIndex(path, "/")
	if i >= 0 {
		return path[i+1:]
	}
	return path
}

func deduplicatePerGroup(cmds []string) []string {
	var result []string
	seen := make(map[string]bool)

	for _, cmd := range cmds {
		if cmd == "" {
			continue
		}
		if strings.HasPrefix(cmd, markdown.SubHeaderMarker) {
			result = append(result, cmd)
			seen = make(map[string]bool)
			continue
		}
		if !seen[cmd] {
			result = append(result, cmd)
			seen[cmd] = true
		}
	}
	return result
}
