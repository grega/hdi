package tui

import (
	"fmt"
	"os/exec"
	"strings"

	"github.com/charmbracelet/bubbles/key"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/grega/hdi/internal/clipboard"
	"github.com/grega/hdi/internal/config"
	"github.com/grega/hdi/internal/display"
)

// dashPool for section headers and selected command padding.
var dashPool = strings.Repeat("─", 200)
var doubleDashPool = strings.Repeat("═", 200)

// Model is the BubbleTea model for the interactive picker.
type Model struct {
	dl              *display.DisplayList
	cursor          int // index into CmdIndices
	viewportTop     int
	termWidth       int
	termHeight      int
	projectName     string
	mode            config.Mode
	platformDisplay string
	flashMsg        string // one-shot copy confirmation
	quitting        bool
	styles          Styles
	keys            KeyMap

	// Post-execution state
	execResult  *execResult
	waitingPost bool // waiting for keypress after exec
}

type execResult struct {
	cmd      string
	exitCode int
}

// execDoneMsg is sent after a command finishes execution.
type execDoneMsg struct {
	cmd      string
	exitCode int
}

// postKeyMsg is sent after user presses a key on the post-exec screen.
type postKeyMsg struct {
	quit bool
}

// New creates a new picker model.
func New(dl *display.DisplayList, projectName string, mode config.Mode, platformDisplay string) Model {
	return Model{
		dl:              dl,
		projectName:     projectName,
		mode:            mode,
		platformDisplay: platformDisplay,
		styles:          DefaultStyles(),
		keys:            DefaultKeyMap(),
	}
}

// Init initializes the model.
func (m Model) Init() tea.Cmd {
	return nil
}

// Update handles messages.
func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.termWidth = msg.Width
		m.termHeight = msg.Height
		m.viewportTop = adjustViewport(m.dl, m.selectedIdx(), m.viewportTop, m.termHeight)
		return m, nil

	case execDoneMsg:
		m.execResult = &execResult{cmd: msg.cmd, exitCode: msg.exitCode}
		m.waitingPost = true
		return m, nil

	case postKeyMsg:
		m.waitingPost = false
		m.execResult = nil
		if msg.quit {
			m.quitting = true
			return m, tea.Quit
		}
		return m, nil

	case tea.KeyMsg:
		if m.waitingPost {
			quit := msg.String() == "q" || msg.String() == "ctrl+c"
			m.waitingPost = false
			m.execResult = nil
			if quit {
				m.quitting = true
				return m, tea.Quit
			}
			return m, nil
		}

		numCmds := len(m.dl.CmdIndices)
		if numCmds == 0 {
			m.quitting = true
			return m, tea.Quit
		}

		switch {
		case key.Matches(msg, m.keys.Up):
			if m.cursor > 0 {
				m.cursor--
			}

		case key.Matches(msg, m.keys.Down):
			if m.cursor < numCmds-1 {
				m.cursor++
			}

		case key.Matches(msg, m.keys.NextSect):
			for _, sf := range m.dl.SectionFirstCmd {
				if sf > m.cursor {
					m.cursor = sf
					break
				}
			}

		case key.Matches(msg, m.keys.PrevSect):
			prev := -1
			for _, sf := range m.dl.SectionFirstCmd {
				if sf >= m.cursor {
					break
				}
				prev = sf
			}
			if prev >= 0 {
				m.cursor = prev
			}

		case key.Matches(msg, m.keys.NextFile):
			nextFile := -1
			for _, ff := range m.dl.FileFirstCmd {
				if ff > m.cursor {
					nextFile = ff
					break
				}
			}
			if nextFile >= 0 {
				m.cursor = nextFile
			} else if len(m.dl.FileFirstCmd) > 0 {
				m.cursor = 0
			}

		case key.Matches(msg, m.keys.Execute):
			selected := m.selectedIdx()
			cmd := m.dl.Lines[selected].Command
			return m, tea.ExecProcess(
				exec.Command("sh", "-c", cmd),
				func(err error) tea.Msg {
					exitCode := 0
					if err != nil {
						if exitErr, ok := err.(*exec.ExitError); ok {
							exitCode = exitErr.ExitCode()
						} else {
							exitCode = 1
						}
					}
					return execDoneMsg{cmd: cmd, exitCode: exitCode}
				},
			)

		case key.Matches(msg, m.keys.Copy):
			selected := m.selectedIdx()
			cmd := m.dl.Lines[selected].Command
			clipboard.Copy(cmd)
			m.flashMsg = "✔ Copied: " + cmd

		case key.Matches(msg, m.keys.Quit):
			m.quitting = true
			return m, tea.Quit
		}

		m.viewportTop = adjustViewport(m.dl, m.selectedIdx(), m.viewportTop, m.termHeight)
		// Clear flash after any non-copy key
		if !key.Matches(msg, m.keys.Copy) {
			m.flashMsg = ""
		}
	}

	return m, nil
}

// View renders the picker.
func (m Model) View() string {
	if m.quitting {
		return ""
	}

	// Post-execution screen
	if m.execResult != nil {
		return m.viewExecResult()
	}

	numCmds := len(m.dl.CmdIndices)
	if numCmds == 0 {
		header := m.renderHeader()
		return header + "\n\nhdi: no commands to pick from\nTry: hdi all --full\n"
	}

	selected := m.selectedIdx()
	termW := m.termWidth
	if termW == 0 {
		termW = 80
	}
	termH := m.termHeight
	if termH == 0 {
		termH = 24
	}
	if termH < 5 {
		termH = 5
	}

	renderWidth := m.dl.MaxContentWidth
	if renderWidth > termW {
		renderWidth = termW
	}

	var b strings.Builder
	nItems := len(m.dl.Lines)

	// Header
	b.WriteString(m.renderHeader())
	b.WriteString("\n\n")
	chrome := 4

	// Scroll-up indicator
	hasAbove := false
	if m.viewportTop > 0 {
		for i := 0; i < m.viewportTop; i++ {
			if m.dl.Lines[i].Type != display.LineEmpty {
				hasAbove = true
				break
			}
		}
	}
	avail := termH - chrome
	if hasAbove {
		b.WriteString("  " + m.styles.Dim.Render("▲ ···") + "\n")
		avail--
	}

	// Render visible entries
	rendered := 0
	hasBelow := false
	idx := m.viewportTop

	for idx < nItems {
		line := m.dl.Lines[idx]
		linesNeeded := screenLines(line.Type)

		// Suppress blank line at viewport top
		if idx == m.viewportTop {
			switch line.Type {
			case display.LineHeader, display.LineSubheader, display.LineFileSep:
				linesNeeded--
			}
		}

		// Reserve for "more below" indicator
		if idx != selected {
			reserve := 0
			if idx < nItems-1 {
				reserve = 1
			}
			if rendered+linesNeeded > avail-reserve && idx > m.viewportTop {
				hasBelow = true
				break
			}
		}
		if rendered+linesNeeded > avail && idx > m.viewportTop {
			hasBelow = true
			break
		}

		switch line.Type {
		case display.LineFileSep:
			if idx != m.viewportTop {
				b.WriteString("\n")
				rendered++
			}
			b.WriteString(m.renderFileSep(line.Text, renderWidth) + "\n")
			b.WriteString("\n")
			rendered++

		case display.LineHeader:
			if idx != m.viewportTop {
				b.WriteString("\n")
				rendered++
			}
			b.WriteString(m.renderSectionHeader(line.Text, renderWidth) + "\n")
			rendered++

		case display.LineSubheader:
			if idx != m.viewportTop {
				b.WriteString("\n")
				rendered++
			}
			b.WriteString("  " + m.styles.SubHeader.Render(line.Text) + "\n")
			rendered++

		case display.LineCommand:
			if idx == selected {
				b.WriteString(m.renderSelected(line.Text, renderWidth) + "\n")
			} else {
				b.WriteString("  " + m.styles.Command.Render("  "+line.Text) + "\n")
			}
			rendered++

		case display.LineEmpty:
			if line.Text != "" {
				b.WriteString("  " + m.styles.Dim.Render("  "+line.Text) + "\n")
			} else {
				b.WriteString("\n")
			}
			rendered++
		}

		idx++
	}

	// Scroll-down indicator
	if hasBelow {
		realBelow := false
		for bi := idx; bi < nItems; bi++ {
			if m.dl.Lines[bi].Type != display.LineEmpty {
				realBelow = true
				break
			}
		}
		if realBelow {
			b.WriteString("  " + m.styles.Dim.Render("▼ ···") + "\n")
		}
	}

	// Footer
	b.WriteString("\n")
	if m.flashMsg != "" {
		b.WriteString("  " + m.styles.Dim.Render(m.flashMsg) + "\n")
	} else {
		footer := "↑↓ navigate  ⇥ sections"
		if len(m.dl.FileFirstCmd) > 0 {
			footer += "  f files"
		}
		footer += "  ⏎ execute  c copy  q quit"
		b.WriteString("  " + m.styles.Dim.Render(footer) + "\n")
	}

	return b.String()
}

func (m Model) selectedIdx() int {
	if len(m.dl.CmdIndices) == 0 {
		return 0
	}
	return m.dl.CmdIndices[m.cursor]
}

func (m Model) renderHeader() string {
	hdr := m.styles.Header.Render(fmt.Sprintf("[hdi] %s", m.projectName))
	switch m.mode {
	case config.ModeInstall:
		hdr += "  " + m.styles.ModeTag.Render("[install]")
	case config.ModeRun:
		hdr += "  " + m.styles.ModeTag.Render("[run]")
	case config.ModeTest:
		hdr += "  " + m.styles.ModeTag.Render("[test]")
	case config.ModeDeploy:
		if m.platformDisplay != "" {
			hdr += "  " + m.styles.ModeTag.Render("[deploy → ") + m.styles.PlatformTag.Render(m.platformDisplay) + m.styles.ModeTag.Render("]")
		} else {
			hdr += "  " + m.styles.ModeTag.Render("[deploy]")
		}
	case config.ModeAll:
		hdr += "  " + m.styles.ModeTag.Render("[all]")
	case config.ModeContrib:
		hdr += "  " + m.styles.ModeTag.Render("[contrib]")
	}
	return hdr
}

func (m Model) renderSectionHeader(title string, width int) string {
	prefix := " ▸ " + title + " "
	prefixLen := len(prefix)
	target := width
	if target < prefixLen+4 {
		target = prefixLen + 4
	}
	n := target - prefixLen
	if n < 2 {
		n = 2
	}
	if n > len(dashPool) {
		n = len(dashPool)
	}
	return m.styles.SectionName.Render(prefix) + m.styles.Dim.Render(dashPool[:n])
}

func (m Model) renderFileSep(name string, width int) string {
	prefix := "  ══ " + name + " "
	prefixLen := len(prefix)
	target := width
	if target < prefixLen+4 {
		target = prefixLen + 4
	}
	n := target - prefixLen
	if n < 2 {
		n = 2
	}
	if n > len(doubleDashPool) {
		n = len(doubleDashPool)
	}
	return m.styles.Dim.Render("  ══ ") + m.styles.FileSepName.Render(name) + m.styles.Dim.Render(" "+doubleDashPool[:n])
}

func (m Model) renderSelected(text string, width int) string {
	padN := width - len(text) - 5
	if padN < 0 {
		padN = 0
	}
	pad := strings.Repeat(" ", padN)

	style := m.styles.Selected
	prefix := "▶ "
	if m.flashMsg != "" {
		style = m.styles.SelectedCopy
		prefix = "✔ "
	}
	return "  " + style.Render(prefix+text+" "+pad)
}

func (m Model) viewExecResult() string {
	var b strings.Builder

	greenStyle := m.styles.Command
	headerStyle := m.styles.Header

	b.WriteString(fmt.Sprintf("\n%s\n\n", greenStyle.Bold(true).Render("❯ "+m.execResult.cmd)))

	if m.execResult.exitCode == 0 {
		b.WriteString(fmt.Sprintf("%s\n", greenStyle.Render(fmt.Sprintf("✓ Done (exit %d)", m.execResult.exitCode))))
		// Warn about shell environment changes
		cmd := m.execResult.cmd
		if strings.Contains(cmd, "source ") || strings.Contains(cmd, ". ") || strings.Contains(cmd, "activate") {
			b.WriteString(m.styles.Dim.Render("  Tip: environment changes (eg. venv activation) don't persist outside hdi.") + "\n")
			b.WriteString(m.styles.Dim.Render("  You may prefer to run this command directly in your shell instead.") + "\n\n")
		}
	} else {
		b.WriteString(fmt.Sprintf("%s\n", headerStyle.Render(fmt.Sprintf("✗ Exited with code %d", m.execResult.exitCode))))
	}

	b.WriteString(m.styles.Dim.Render("  Press any key to return to picker, q to quit") + "\n")
	return b.String()
}
