package render

import (
	"fmt"
	"io"
	"strings"

	"github.com/charmbracelet/lipgloss"
	"github.com/grega/hdi/internal/display"
)

// Styles holds all lipgloss styles for rendering.
type Styles struct {
	Header      lipgloss.Style
	SectionName lipgloss.Style
	SubHeader   lipgloss.Style
	Command     lipgloss.Style
	Dim         lipgloss.Style
	FileSepName lipgloss.Style
	FileSepDash lipgloss.Style
	Reset       lipgloss.Style
}

// DefaultStyles returns the standard color styles.
func DefaultStyles(renderer *lipgloss.Renderer) Styles {
	return Styles{
		Header:      renderer.NewStyle().Bold(true).Foreground(lipgloss.Color("3")),   // Yellow
		SectionName: renderer.NewStyle().Bold(true).Foreground(lipgloss.Color("6")),   // Cyan
		SubHeader:   renderer.NewStyle().Bold(true).Foreground(lipgloss.Color("5")),   // Magenta
		Command:     renderer.NewStyle().Foreground(lipgloss.Color("2")),              // Green
		Dim:         renderer.NewStyle().Faint(true),
		FileSepName: renderer.NewStyle().Bold(true).Foreground(lipgloss.Color("3")),   // Yellow
		FileSepDash: renderer.NewStyle().Faint(true),
	}
}

// sectionHeader formats a section header with trailing dashes.
func sectionHeader(title string, width int, styles Styles) string {
	prefix := " ▸ " + title + " "
	// Use rune count for display width (▸ is 1 column)
	prefixCols := runeWidth(prefix)
	n := width - prefixCols
	if n < 2 {
		n = 2
	}
	if n > 200 {
		n = 200
	}
	return styles.SectionName.Render(prefix) + styles.Dim.Render(strings.Repeat("─", n))
}

// fileSeparator formats a file separator with double-line dashes.
func fileSeparator(name string, width int, styles Styles) string {
	prefix := "  ══ " + name + " "
	prefixCols := runeWidth(prefix)
	n := width - prefixCols
	if n < 2 {
		n = 2
	}
	if n > 200 {
		n = 200
	}
	return styles.Dim.Render("  ══ ") + styles.FileSepName.Render(name) + styles.Dim.Render(" "+strings.Repeat("═", n))
}

// runeWidth returns the display column width of a string,
// assuming all runes are 1 column wide (true for the ASCII + box-drawing chars we use).
func runeWidth(s string) int {
	n := 0
	for range s {
		n++
	}
	return n
}

// Static renders the display list in non-interactive mode with colors.
func Static(w io.Writer, dl *display.DisplayList, styles Styles) {
	width := dl.MaxContentWidth

	for _, line := range dl.Lines {
		switch line.Type {
		case display.LineFileSep:
			fmt.Fprintf(w, "\n%s\n\n", fileSeparator(line.Text, width, styles))
		case display.LineHeader:
			fmt.Fprintf(w, "\n%s\n", sectionHeader(line.Text, width, styles))
		case display.LineSubheader:
			fmt.Fprintf(w, "\n  %s\n", styles.SubHeader.Render(line.Text))
		case display.LineCommand:
			fmt.Fprintf(w, "  %s\n", styles.Command.Render(line.Text))
		case display.LineEmpty:
			if line.Text != "" {
				fmt.Fprintf(w, "  %s\n", styles.Dim.Render(line.Text))
			}
		}
	}
}

// Raw renders the display list in plain markdown format (no ANSI colors).
func Raw(w io.Writer, dl *display.DisplayList) {
	for _, line := range dl.Lines {
		switch line.Type {
		case display.LineFileSep:
			fmt.Fprintf(w, "\n--- %s ---\n", line.Text)
		case display.LineHeader:
			fmt.Fprintf(w, "\n## %s\n", line.Text)
		case display.LineSubheader:
			fmt.Fprintf(w, "\n### %s\n", line.Text)
		case display.LineCommand:
			fmt.Fprintf(w, "%s\n", line.Text)
		case display.LineEmpty:
			if line.Text != "" {
				fmt.Fprintf(w, "  %s\n", line.Text)
			}
		}
	}
}
