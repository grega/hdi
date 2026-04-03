package tui

import "github.com/charmbracelet/bubbles/key"

// KeyMap defines all key bindings for the picker.
type KeyMap struct {
	Up        key.Binding
	Down      key.Binding
	NextSect  key.Binding
	PrevSect  key.Binding
	NextFile  key.Binding
	Execute   key.Binding
	Copy      key.Binding
	Quit      key.Binding
}

// DefaultKeyMap returns the standard key bindings.
func DefaultKeyMap() KeyMap {
	return KeyMap{
		Up: key.NewBinding(
			key.WithKeys("up", "k"),
			key.WithHelp("↑/k", "up"),
		),
		Down: key.NewBinding(
			key.WithKeys("down", "j"),
			key.WithHelp("↓/j", "down"),
		),
		NextSect: key.NewBinding(
			key.WithKeys("tab", "right"),
			key.WithHelp("⇥", "next section"),
		),
		PrevSect: key.NewBinding(
			key.WithKeys("shift+tab", "left"),
			key.WithHelp("⇧⇥", "prev section"),
		),
		NextFile: key.NewBinding(
			key.WithKeys("f"),
			key.WithHelp("f", "next file"),
		),
		Execute: key.NewBinding(
			key.WithKeys("enter"),
			key.WithHelp("⏎", "execute"),
		),
		Copy: key.NewBinding(
			key.WithKeys("c"),
			key.WithHelp("c", "copy"),
		),
		Quit: key.NewBinding(
			key.WithKeys("q", "esc", "ctrl+c"),
			key.WithHelp("q", "quit"),
		),
	}
}
