package tui

import (
	"fmt"
	"io"
	"strings"

	"github.com/charmbracelet/bubbles/key"
	"github.com/charmbracelet/bubbles/list"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/charmbracelet/x/ansi"
)


// CommandDelegate renders a mixed list of commands, section headers,
// sub-headers, spacers, and file separators.
type CommandDelegate struct {
	Styles  DelegateStyles
	CopyKey key.Binding
	ExecKey key.Binding
}

// DelegateStyles defines the visual styles.
type DelegateStyles struct {
	NormalCmd   lipgloss.Style
	SelectedCmd lipgloss.Style
	CopyCmd     lipgloss.Style
	DimmedCmd   lipgloss.Style
	Section     lipgloss.Style
	SectionDash lipgloss.Style
	SubHeader   lipgloss.Style
	FileSep     lipgloss.Style
	FileSepDash lipgloss.Style
}

// NewCommandDelegate creates a delegate with hdi's visual style.
func NewCommandDelegate() CommandDelegate {
	return CommandDelegate{
		Styles: DelegateStyles{
			NormalCmd: lipgloss.NewStyle().Foreground(colorCmd).Padding(0, 0, 0, 4),
			SelectedCmd: lipgloss.NewStyle().
				Border(lipgloss.NormalBorder(), false, false, false, true).
				BorderForeground(colorAccent).
				Foreground(colorSelFg).
				Background(colorSelBg).
				Bold(true).
				Padding(0, 0, 0, 3),
			CopyCmd: lipgloss.NewStyle().
				Border(lipgloss.NormalBorder(), false, false, false, true).
				BorderForeground(colorSuccess).
				Foreground(colorSuccess).
				Background(colorSelBg).
				Bold(true).
				Padding(0, 0, 0, 3),
			DimmedCmd:   lipgloss.NewStyle().Foreground(colorDim).Padding(0, 0, 0, 4),
			Section:     lipgloss.NewStyle().Bold(true).Foreground(colorSection),
			SectionDash: lipgloss.NewStyle().Foreground(colorSectionDash),
			SubHeader:   lipgloss.NewStyle().Bold(true).Foreground(colorSubHeader).Padding(0, 0, 0, 2),
			FileSep:     lipgloss.NewStyle().Bold(true).Foreground(colorFileSep),
			FileSepDash: lipgloss.NewStyle().Foreground(colorDim),
		},
		CopyKey: key.NewBinding(key.WithKeys("c"), key.WithHelp("c", "copy")),
		ExecKey: key.NewBinding(key.WithKeys("enter"), key.WithHelp("⏎", "execute")),
	}
}

func (d CommandDelegate) Height() int  { return 1 }
func (d CommandDelegate) Spacing() int { return 0 }

func (d CommandDelegate) Update(msg tea.Msg, m *list.Model) tea.Cmd {
	return nil
}

// Render renders a single item based on its type.
func (d CommandDelegate) Render(w io.Writer, m list.Model, index int, item list.Item) {
	if m.Width() <= 0 {
		return
	}

	width := m.Width()

	switch v := item.(type) {
	case SectionItem:
		d.renderSection(w, v.Name, width)
	case SubHeaderItem:
		d.renderSubHeader(w, v.Name, width)
	case SpacerItem:
		// blank line — just emit nothing, the row height handles it
		return
	case FileSepItem:
		d.renderFileSep(w, v.Name, width)
	case CommandItem:
		d.renderCommand(w, m, index, v)
	}
}

func (d CommandDelegate) renderSection(w io.Writer, name string, width int) {
	prefix := " ▸ " + name + " "
	prefixCols := runeWidth(prefix)
	n := width - prefixCols - 2
	if n < 2 {
		n = 2
	}
	if n > 200 {
		n = 200
	}
	fmt.Fprint(w, d.Styles.Section.Render(prefix)+d.Styles.SectionDash.Render(strings.Repeat("─", n)))
}

func (d CommandDelegate) renderSubHeader(w io.Writer, name string, width int) {
	fmt.Fprint(w, d.Styles.SubHeader.Render(name))
}

func (d CommandDelegate) renderFileSep(w io.Writer, name string, width int) {
	prefix := "  ══ " + name + " "
	prefixCols := runeWidth(prefix)
	n := width - prefixCols - 2
	if n < 2 {
		n = 2
	}
	if n > 200 {
		n = 200
	}
	fmt.Fprint(w, d.Styles.FileSepDash.Render("  ══ ")+d.Styles.FileSep.Render(name)+d.Styles.FileSepDash.Render(" "+strings.Repeat("═", n)))
}

// runeWidth returns the display column width of a string.
func runeWidth(s string) int {
	n := 0
	for range s {
		n++
	}
	return n
}

func (d CommandDelegate) renderCommand(w io.Writer, m list.Model, index int, ci CommandItem) {
	isSelected := index == m.Index()
	isFiltering := m.FilterState() == list.Filtering
	emptyFilter := isFiltering && m.FilterValue() == ""

	cmdText := ci.Cmd
	maxWidth := m.Width() - 6
	if maxWidth < 20 {
		maxWidth = 20
	}
	cmdText = ansi.Truncate(cmdText, maxWidth, "…")

	var line string
	if emptyFilter {
		line = d.Styles.DimmedCmd.Render(cmdText)
	} else if isSelected && !isFiltering {
		line = d.Styles.SelectedCmd.Render(cmdText)
	} else {
		line = d.Styles.NormalCmd.Render(cmdText)
	}

	fmt.Fprint(w, line)
}

func (d CommandDelegate) ShortHelp() []key.Binding {
	return []key.Binding{d.ExecKey, d.CopyKey}
}

func (d CommandDelegate) FullHelp() [][]key.Binding {
	return [][]key.Binding{{d.ExecKey, d.CopyKey}}
}
