package tui

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/bubbles/key"
	"github.com/charmbracelet/bubbles/table"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/grega/hdi/internal/needs"
	"github.com/grega/hdi/internal/platform"
)

// NeedsViewModel shows tool dependencies in a table.
type NeedsViewModel struct {
	table       table.Model
	toolInfos   []needs.ToolInfo
	projectName string
	done        bool
	found       int
	missing     int
}

// NewNeedsView creates a new needs view by collecting tools from the command set.
func NewNeedsView(cs *CommandSet, projectName string, width, height int) NeedsViewModel {
	// Collect tool names from commands
	var tools []string
	seen := make(map[string]bool)
	for _, item := range cs.Commands {
		tool := platform.ExtractToolName(item.Cmd)
		if tool == "" || seen[tool] {
			continue
		}
		seen[tool] = true
		tools = append(tools, tool)
	}

	// Check which tools are installed
	toolInfos := needs.CheckTools(tools)

	return newNeedsViewFromInfos(toolInfos, projectName, width, height)
}

// newNeedsViewFromInfos creates a NeedsViewModel from pre-checked tool infos.
func newNeedsViewFromInfos(toolInfos []needs.ToolInfo, projectName string, width, height int) NeedsViewModel {
	found := 0
	missing := 0

	// Build table rows
	rows := make([]table.Row, len(toolInfos))
	for i, t := range toolInfos {
		status := "✗"
		version := "not found"
		if t.Installed {
			status = "✓"
			version = t.Version
			if version == "" {
				version = "installed"
			}
			found++
		} else {
			missing++
		}
		rows[i] = table.Row{status, t.Name, version}
	}

	// Define columns
	toolWidth := 20
	if width > 60 {
		toolWidth = 30
	}
	columns := []table.Column{
		{Title: "", Width: 3},
		{Title: "Tool", Width: toolWidth},
		{Title: "Version", Width: 20},
	}

	t := table.New(
		table.WithColumns(columns),
		table.WithRows(rows),
		table.WithFocused(true),
		table.WithHeight(height-6), // reserve for header/footer
	)

	// Style the table
	s := table.DefaultStyles()
	s.Header = s.Header.
		BorderStyle(lipgloss.NormalBorder()).
		BorderForeground(colorSection).
		BorderBottom(true).
		Bold(true).
		Foreground(colorSection)
	s.Selected = s.Selected.
		Foreground(colorSelFg).
		Background(colorSelBg).
		Bold(false)
	s.Cell = s.Cell.Foreground(colorCmd)
	t.SetStyles(s)

	return NeedsViewModel{
		table:       t,
		toolInfos:   toolInfos,
		projectName: projectName,
		found:       found,
		missing:     missing,
	}
}

// Update handles messages for the needs view.
func (nv NeedsViewModel) Update(msg tea.Msg) (NeedsViewModel, tea.Cmd) {
	if msg, ok := msg.(tea.KeyMsg); ok {
		if key.Matches(msg, key.NewBinding(key.WithKeys("esc", "q"))) {
			nv.done = true
			return nv, nil
		}
	}

	var cmd tea.Cmd
	nv.table, cmd = nv.table.Update(msg)
	return nv, cmd
}

// View renders the needs table.
func (nv NeedsViewModel) View() string {
	var b strings.Builder

	b.WriteString("\n")
	b.WriteString(nv.table.View())
	b.WriteString("\n\n")

	// Summary
	dimStyle := lipgloss.NewStyle().Foreground(colorDim)
	warnStyle := lipgloss.NewStyle().Foreground(colorError)
	successStyle := lipgloss.NewStyle().Foreground(colorSuccess)

	if nv.missing == 0 {
		b.WriteString("  " + successStyle.Render(fmt.Sprintf("✓ All %d tools found", nv.found)))
	} else {
		b.WriteString("  " + dimStyle.Render(fmt.Sprintf("%d found, ", nv.found)) +
			warnStyle.Render(fmt.Sprintf("%d not found", nv.missing)))
	}
	b.WriteString("\n\n")
	b.WriteString("  " + dimStyle.Render("esc to return") + "\n")

	return b.String()
}

// SetSize updates the table dimensions.
func (nv *NeedsViewModel) SetSize(w, h int) {
	nv.table.SetHeight(h - 6)
}
