package tui

import "github.com/charmbracelet/lipgloss"

// Styles holds all lipgloss styles for the TUI picker.
type Styles struct {
	Header      lipgloss.Style // [hdi] ProjectName
	ModeTag     lipgloss.Style // [install] etc.
	SectionName lipgloss.Style // Bold + Cyan
	SubHeader   lipgloss.Style // Bold + Magenta
	Command     lipgloss.Style // Green
	Selected    lipgloss.Style // Bold White on dark background
	SelectedCopy lipgloss.Style // Bold Green on dark background (copy flash)
	Dim         lipgloss.Style // Faint
	FileSepName lipgloss.Style // Bold Yellow
	PlatformTag lipgloss.Style // Cyan
}

// DefaultStyles returns the standard TUI color styles.
func DefaultStyles() Styles {
	return Styles{
		Header:       lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("3")),
		ModeTag:      lipgloss.NewStyle().Faint(true),
		SectionName:  lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("6")),
		SubHeader:    lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("5")),
		Command:      lipgloss.NewStyle().Foreground(lipgloss.Color("2")),
		Selected:     lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("15")).Background(lipgloss.Color("236")),
		SelectedCopy: lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("2")).Background(lipgloss.Color("236")),
		Dim:          lipgloss.NewStyle().Faint(true),
		FileSepName:  lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("3")),
		PlatformTag:  lipgloss.NewStyle().Foreground(lipgloss.Color("6")),
	}
}
