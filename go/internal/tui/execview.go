package tui

import (
	"fmt"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// ExecViewModel shows the result after command execution.
type ExecViewModel struct {
	cmd      string
	exitCode int
	done     bool
	quit     bool
}

// NewExecView creates a new exec result view.
func NewExecView(cmd string, exitCode int) ExecViewModel {
	return ExecViewModel{
		cmd:      cmd,
		exitCode: exitCode,
	}
}

// Update handles key presses on the exec result screen.
func (ev ExecViewModel) Update(msg tea.Msg) (ExecViewModel, tea.Cmd) {
	if msg, ok := msg.(tea.KeyMsg); ok {
		ev.done = true
		if msg.String() == "q" || msg.String() == "ctrl+c" {
			ev.quit = true
			return ev, tea.Quit
		}
	}
	return ev, nil
}

// View renders the exec result screen.
func (ev ExecViewModel) View() string {
	var b strings.Builder

	greenStyle := lipgloss.NewStyle().Foreground(colorSuccess)
	errorStyle := lipgloss.NewStyle().Bold(true).Foreground(colorError)
	dimStyle := lipgloss.NewStyle().Foreground(colorDim)

	b.WriteString(fmt.Sprintf("\n%s\n\n", greenStyle.Bold(true).Render("❯ "+ev.cmd)))

	if ev.exitCode == 0 {
		b.WriteString(fmt.Sprintf("%s\n", greenStyle.Render(fmt.Sprintf("✓ Done (exit %d)", ev.exitCode))))
		// Warn about shell environment changes
		if strings.Contains(ev.cmd, "source ") || strings.Contains(ev.cmd, ". ") || strings.Contains(ev.cmd, "activate") {
			b.WriteString(dimStyle.Render("  Tip: environment changes (eg. venv activation) don't persist outside hdi.") + "\n")
			b.WriteString(dimStyle.Render("  You may prefer to run this command directly in your shell instead.") + "\n\n")
		}
	} else {
		b.WriteString(fmt.Sprintf("%s\n", errorStyle.Render(fmt.Sprintf("✗ Exited with code %d", ev.exitCode))))
	}

	b.WriteString(dimStyle.Render("  Press any key to return to picker, q to quit") + "\n")
	return b.String()
}
