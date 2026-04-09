package tui

import (
	"os/exec"

	"github.com/charmbracelet/bubbles/key"
	"github.com/charmbracelet/bubbles/list"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/grega/hdi/internal/clipboard"
)

var categoryOrder = []string{"", "install", "run", "test", "deploy"}

var categoryLabels = map[string]string{
	"":        "all",
	"install": "install",
	"run":     "run",
	"test":    "test",
	"deploy":  "deploy",
}

// PickerModel wraps a bubbles list.Model with category cycling, skip logic,
// and command actions.
type PickerModel struct {
	list       list.Model
	commandSet *CommandSet
	category   string // current filter: "" = all
	delegate   *CommandDelegate
	keys       PickerKeyMap
}

type PickerKeyMap struct {
	Execute  key.Binding
	Copy     key.Binding
	CycleTab key.Binding
	Needs    key.Binding
	FullView key.Binding
}

func DefaultPickerKeyMap() PickerKeyMap {
	return PickerKeyMap{
		Execute: key.NewBinding(
			key.WithKeys("enter"),
			key.WithHelp("⏎", "execute"),
		),
		Copy: key.NewBinding(
			key.WithKeys("c"),
			key.WithHelp("c", "copy"),
		),
		CycleTab: key.NewBinding(
			key.WithKeys("tab"),
			key.WithHelp("⇥", "category"),
		),
		Needs: key.NewBinding(
			key.WithKeys("n"),
			key.WithHelp("n", "needs"),
		),
		FullView: key.NewBinding(
			key.WithKeys("f"),
			key.WithHelp("f", "full prose"),
		),
	}
}

func NewPicker(cs *CommandSet, width, height int, initialCategory string) PickerModel {
	delegate := NewCommandDelegate()

	items := cs.All

	l := list.New(items, delegate, width, height)
	l.SetShowTitle(false)
	l.SetShowStatusBar(true)
	l.SetShowFilter(true)
	l.SetFilteringEnabled(true)
	l.SetShowHelp(true)
	l.SetShowPagination(true)

	// Theme the list chrome
	l.Styles.FilterPrompt = lipgloss.NewStyle().Foreground(colorAccent).Bold(true)
	l.Styles.FilterCursor = lipgloss.NewStyle().Foreground(colorAccent)
	l.Styles.StatusBar = lipgloss.NewStyle().Foreground(colorDim).Padding(0, 0, 1, 2)
	l.Styles.StatusBarActiveFilter = lipgloss.NewStyle().Foreground(colorAccent)
	l.Styles.ActivePaginationDot = lipgloss.NewStyle().Foreground(colorAccent).SetString("•")
	l.Styles.InactivePaginationDot = lipgloss.NewStyle().Foreground(colorDim).SetString("•")
	l.Styles.NoItems = lipgloss.NewStyle().Foreground(colorDim).Padding(0, 0, 0, 4)
	l.StatusMessageLifetime = 2

	// Custom key map: remove esc from quit
	lk := l.KeyMap
	lk.Quit = key.NewBinding(
		key.WithKeys("q"),
		key.WithHelp("q", "quit"),
	)
	l.KeyMap = lk

	pk := DefaultPickerKeyMap()
	l.AdditionalShortHelpKeys = func() []key.Binding {
		return []key.Binding{pk.Execute, pk.Copy, pk.CycleTab}
	}
	l.AdditionalFullHelpKeys = func() []key.Binding {
		return []key.Binding{pk.Execute, pk.Copy, pk.CycleTab, pk.Needs, pk.FullView}
	}

	pm := PickerModel{
		list:       l,
		commandSet: cs,
		category:   initialCategory,
		delegate:   &delegate,
		keys:       pk,
	}

	if initialCategory != "" {
		pm.applyCategory(initialCategory)
	}

	// Ensure cursor starts on a selectable item
	pm.skipToSelectable(1)

	return pm
}

// Update handles messages for the picker.
func (pm PickerModel) Update(msg tea.Msg) (PickerModel, tea.Cmd) {
	prevIndex := pm.list.Index()

	switch msg := msg.(type) {
	case tea.KeyMsg:
		// Don't intercept keys while filtering
		if pm.list.FilterState() == list.Filtering {
			var cmd tea.Cmd
			pm.list, cmd = pm.list.Update(msg)
			return pm, cmd
		}

		switch {
		case key.Matches(msg, pm.keys.Execute):
			item, ok := pm.list.SelectedItem().(CommandItem)
			if !ok {
				break
			}
			return pm, tea.ExecProcess(
				exec.Command("sh", "-c", item.Cmd),
				func(err error) tea.Msg {
					exitCode := 0
					if err != nil {
						if exitErr, ok := err.(*exec.ExitError); ok {
							exitCode = exitErr.ExitCode()
						} else {
							exitCode = 1
						}
					}
					return execDoneMsg{cmd: item.Cmd, exitCode: exitCode}
				},
			)

		case key.Matches(msg, pm.keys.Copy):
			item, ok := pm.list.SelectedItem().(CommandItem)
			if !ok {
				break
			}
			clipboard.Copy(item.Cmd)
			cmd := pm.list.NewStatusMessage("✔ Copied: " + item.Cmd)
			return pm, cmd

		case key.Matches(msg, pm.keys.CycleTab):
			pm.cycleCategory()
			return pm, nil

		case key.Matches(msg, pm.keys.Needs):
			return pm, func() tea.Msg { return switchToNeedsMsg{} }

		case key.Matches(msg, pm.keys.FullView):
			return pm, func() tea.Msg { return switchToFullMsg{} }
		}
	}

	var cmd tea.Cmd
	pm.list, cmd = pm.list.Update(msg)

	// Skip logic: if cursor moved onto a non-selectable item, nudge it
	newIndex := pm.list.Index()
	if newIndex != prevIndex && !pm.isCurrentSelectable() {
		dir := 1
		if newIndex < prevIndex {
			dir = -1
		}
		pm.skipToSelectable(dir)
	}

	return pm, cmd
}

func (pm PickerModel) View() string {
	return pm.list.View()
}

func (pm *PickerModel) SetSize(w, h int) {
	pm.list.SetSize(w, h)
}

func (pm PickerModel) CategoryLabel() string {
	if label, ok := categoryLabels[pm.category]; ok {
		return label
	}
	return "all"
}

// skipToSelectable moves the cursor in the given direction (+1 or -1)
// until it lands on a selectable (CommandItem) row.
func (pm *PickerModel) skipToSelectable(dir int) {
	items := pm.list.VisibleItems()
	n := len(items)
	if n == 0 {
		return
	}

	idx := pm.list.Index()
	if idx < 0 {
		idx = 0
	}
	if idx >= n {
		idx = n - 1
	}

	// Already on a selectable item
	if isSelectable(items[idx]) {
		return
	}

	// Try the preferred direction first
	for i := idx + dir; i >= 0 && i < n; i += dir {
		if isSelectable(items[i]) {
			pm.list.Select(i)
			return
		}
	}

	// Reverse direction as fallback
	for i := idx - dir; i >= 0 && i < n; i -= dir {
		if isSelectable(items[i]) {
			pm.list.Select(i)
			return
		}
	}
}

// isCurrentSelectable checks if the currently selected item is a command.
func (pm PickerModel) isCurrentSelectable() bool {
	item := pm.list.SelectedItem()
	if item == nil {
		return false
	}
	return isSelectable(item)
}

func (pm *PickerModel) cycleCategory() {
	currentIdx := 0
	for i, cat := range categoryOrder {
		if cat == pm.category {
			currentIdx = i
			break
		}
	}

	for offset := 1; offset <= len(categoryOrder); offset++ {
		nextIdx := (currentIdx + offset) % len(categoryOrder)
		nextCat := categoryOrder[nextIdx]

		if nextCat == "" {
			pm.applyCategory("")
			return
		}
		if items, ok := pm.commandSet.ByCategory[nextCat]; ok && len(items) > 0 {
			pm.applyCategory(nextCat)
			return
		}
	}
}

func (pm *PickerModel) applyCategory(cat string) {
	pm.category = cat

	var items []list.Item
	if cat == "" {
		items = pm.commandSet.All
	} else if catItems, ok := pm.commandSet.ByCategory[cat]; ok {
		items = catItems
	} else {
		items = pm.commandSet.All
		pm.category = ""
	}

	pm.list.SetItems(items)
	pm.list.ResetSelected()

	if pm.list.FilterState() != list.Unfiltered {
		pm.list.ResetFilter()
	}

	// Ensure cursor lands on a selectable item
	pm.skipToSelectable(1)
}
