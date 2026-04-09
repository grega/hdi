package tui

import (
	"fmt"
	"regexp"
	"strings"

	"github.com/charmbracelet/bubbles/key"
	"github.com/charmbracelet/bubbles/viewport"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/grega/hdi/internal/markdown"
)

var (
	reFullATXSub    = regexp.MustCompile(`^#{2,}\s+(.*)`)
	reFullSetextU   = regexp.MustCompile(`^\s*(={3,}|-{3,})\s*$`)
	reFullBacktick  = regexp.MustCompile("`([^`]+)`")
	reFullCodeFence = regexp.MustCompile("^\\s*(`{3,}|~{3,})")
)

// FullViewModel shows rendered prose in a scrollable viewport.
type FullViewModel struct {
	viewport viewport.Model
	done     bool
}

// NewFullView creates a new full prose view from sections.
func NewFullView(sections []markdown.Section, width, height int) FullViewModel {
	content := renderFullProse(sections, width)

	vp := viewport.New(width, height-2) // reserve for footer
	vp.SetContent(content)

	return FullViewModel{
		viewport: vp,
	}
}

// Update handles messages for the full view.
func (fv FullViewModel) Update(msg tea.Msg) (FullViewModel, tea.Cmd) {
	if msg, ok := msg.(tea.KeyMsg); ok {
		if key.Matches(msg, key.NewBinding(key.WithKeys("esc", "q", "f"))) {
			fv.done = true
			return fv, nil
		}
	}

	var cmd tea.Cmd
	fv.viewport, cmd = fv.viewport.Update(msg)
	return fv, cmd
}

// View renders the full prose viewport with a footer.
func (fv FullViewModel) View() string {
	dimStyle := lipgloss.NewStyle().Foreground(colorDim)
	pctStyle := lipgloss.NewStyle().Foreground(colorAccent)
	footer := dimStyle.Render("  ↑/↓ scroll  f back  q quit    ") +
		pctStyle.Render(fmt.Sprintf("%3.f%%", fv.viewport.ScrollPercent()*100))
	return fv.viewport.View() + "\n" + footer
}

// SetSize updates the viewport dimensions.
func (fv *FullViewModel) SetSize(w, h int) {
	fv.viewport.Width = w
	fv.viewport.Height = h - 2
}

// renderFullProse pre-renders all sections into a styled string for the viewport.
func renderFullProse(sections []markdown.Section, width int) string {
	var b strings.Builder

	sectionStyle := lipgloss.NewStyle().Bold(true).Foreground(colorSection)
	subHeaderStyle := lipgloss.NewStyle().Bold(true).Foreground(colorSubHeader)
	cmdStyle := lipgloss.NewStyle().Foreground(colorCmd)
	dimStyle := lipgloss.NewStyle().Foreground(colorDim)
	fileSepStyle := lipgloss.NewStyle().Bold(true).Foreground(colorFileSep)

	prevSource := ""

	for _, sec := range sections {
		// File separator when source changes
		if prevSource != "" && sec.Source != "" && sec.Source != prevSource {
			name := baseName(sec.Source)
			sepWidth := width - runeWidth("  ══ "+name+" ") - 2
			if sepWidth < 2 {
				sepWidth = 2
			}
			if sepWidth > 200 {
				sepWidth = 200
			}
			b.WriteString("\n" + dimStyle.Render("  ══ ") + fileSepStyle.Render(name) + dimStyle.Render(" "+strings.Repeat("═", sepWidth)) + "\n\n")
		}
		prevSource = sec.Source

		content := stripTrailingBlanks(sec.Body)
		if content == "" {
			continue
		}

		// Section header
		prefix := " ▸ " + sec.Title + " "
		n := width - runeWidth(prefix) - 2
		if n < 2 {
			n = 2
		}
		if n > 200 {
			n = 200
		}
		b.WriteString("\n" + sectionStyle.Render(prefix) + dimStyle.Render(strings.Repeat("─", n)) + "\n")

		// Render body content
		lines := strings.Split(content, "\n")
		inCode := false
		codeBuf := ""
		fenceChar := byte(0)
		havePrev := false
		prevLine := ""

		renderLine := func(l string) {
			if strings.TrimSpace(l) == "" {
				b.WriteString("\n")
				return
			}
			if m := reFullATXSub.FindStringSubmatch(l); m != nil {
				sub := m[1]
				sub = markdown.StripTrailingHashesExported(sub)
				sub = markdown.StripFormattingExported(sub)
				b.WriteString("  " + subHeaderStyle.Render(sub) + "\n")
				return
			}
			formatted := highlightBackticks(l, cmdStyle)
			b.WriteString("  " + formatted + "\n")
		}

		for _, line := range lines {
			if m := reFullCodeFence.FindStringSubmatch(line); m != nil {
				fence := m[1]
				if havePrev && !inCode {
					renderLine(prevLine)
					havePrev = false
					prevLine = ""
				}
				if inCode {
					if fence[0] == fenceChar {
						for _, cl := range strings.Split(strings.TrimRight(codeBuf, "\n"), "\n") {
							b.WriteString("  " + cl + "\n")
						}
						codeBuf = ""
						inCode = false
						fenceChar = 0
					}
				} else {
					inCode = true
					fenceChar = fence[0]
				}
				continue
			}

			if inCode {
				codeBuf += "  " + line + "\n"
				continue
			}

			if havePrev && reFullSetextU.MatchString(line) {
				sub := markdown.StripFormattingExported(prevLine)
				b.WriteString("  " + subHeaderStyle.Render(sub) + "\n")
				havePrev = false
				prevLine = ""
				continue
			}

			if havePrev {
				renderLine(prevLine)
			}
			prevLine = line
			havePrev = true
		}

		if havePrev {
			renderLine(prevLine)
		}
	}

	return b.String()
}

// highlightBackticks replaces `code` with styled text.
func highlightBackticks(line string, cmdStyle lipgloss.Style) string {
	return reFullBacktick.ReplaceAllStringFunc(line, func(match string) string {
		inner := match[1 : len(match)-1]
		return cmdStyle.Render(inner)
	})
}

// stripTrailingBlanks removes trailing blank lines from content.
func stripTrailingBlanks(content string) string {
	lines := strings.Split(content, "\n")
	for len(lines) > 0 && strings.TrimSpace(lines[len(lines)-1]) == "" {
		lines = lines[:len(lines)-1]
	}
	if len(lines) == 0 {
		return ""
	}
	return strings.Join(lines, "\n")
}
