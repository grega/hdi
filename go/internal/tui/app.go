package tui

import (
	"fmt"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/grega/hdi/internal/config"
	"github.com/grega/hdi/internal/markdown"
)

// View represents the active view in the app.
type View int

const (
	ViewPicker View = iota
	ViewExec
	ViewNeeds
	ViewFull
)

// Message types for view switching.
type switchToNeedsMsg struct{}
type switchToFullMsg struct{}

type execDoneMsg struct {
	cmd      string
	exitCode int
}

// AppModel is the top-level Bubble Tea model that routes between views.
type AppModel struct {
	activeView View
	picker     PickerModel
	execView   ExecViewModel
	needsView  *NeedsViewModel
	fullView   *FullViewModel

	// Shared data
	commandSet      *CommandSet
	sections        []markdown.Section
	projectName     string
	mode            config.Mode
	platformDisplay string

	width, height int
	styles        AppStyles
}

// AppStyles holds top-level styles.
type AppStyles struct {
	Header      lipgloss.Style
	ModeTag     lipgloss.Style
	PlatformTag lipgloss.Style
}

func defaultAppStyles() AppStyles {
	return AppStyles{
		Header:      lipgloss.NewStyle().Bold(true).Foreground(colorTitle),
		ModeTag:     lipgloss.NewStyle().Foreground(colorDim),
		PlatformTag: lipgloss.NewStyle().Foreground(colorPlatform),
	}
}

// AppConfig holds the parameters for creating a new AppModel.
type AppConfig struct {
	CommandSet      *CommandSet
	Sections        []markdown.Section
	ProjectName     string
	Mode            config.Mode
	PlatformDisplay string
	StartView       View // which view to show initially (default: ViewPicker)
}

// NewApp creates a new AppModel.
func NewApp(cfg AppConfig) AppModel {
	initialCategory := categoryForMode(cfg.Mode)

	picker := NewPicker(cfg.CommandSet, 80, 24, initialCategory)

	// Build title for the list
	title := fmt.Sprintf("[hdi] %s", cfg.ProjectName)
	picker.list.Title = title

	m := AppModel{
		activeView:      cfg.StartView,
		picker:          picker,
		commandSet:      cfg.CommandSet,
		sections:        cfg.Sections,
		projectName:     cfg.ProjectName,
		mode:            cfg.Mode,
		platformDisplay: cfg.PlatformDisplay,
		styles:          defaultAppStyles(),
	}

	// Initialize the starting view if not picker
	switch cfg.StartView {
	case ViewNeeds:
		nv := NewNeedsView(cfg.CommandSet, cfg.ProjectName, 80, 24)
		m.needsView = &nv
	case ViewFull:
		fv := NewFullView(cfg.Sections, 80, 24)
		m.fullView = &fv
	}

	return m
}

// Init initializes the app.
func (m AppModel) Init() tea.Cmd {
	return nil
}

// Update handles messages and routes to the active view.
func (m AppModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height

		// Reserve space for header
		headerHeight := 2
		contentHeight := m.height - headerHeight

		m.picker.SetSize(m.width, contentHeight)

		if m.needsView != nil {
			m.needsView.SetSize(m.width, contentHeight)
		}
		if m.fullView != nil {
			m.fullView.SetSize(m.width, contentHeight)
		}
		return m, nil

	case execDoneMsg:
		m.execView = NewExecView(msg.cmd, msg.exitCode)
		m.activeView = ViewExec
		return m, nil

	case switchToNeedsMsg:
		if m.needsView == nil {
			nv := NewNeedsView(m.commandSet, m.projectName, m.width, m.height-2)
			m.needsView = &nv
		}
		m.activeView = ViewNeeds
		return m, nil

	case switchToFullMsg:
		if m.fullView == nil {
			fv := NewFullView(m.sections, m.width, m.height-2)
			m.fullView = &fv
		}
		m.activeView = ViewFull
		return m, nil
	}

	switch m.activeView {
	case ViewPicker:
		var cmd tea.Cmd
		m.picker, cmd = m.picker.Update(msg)
		return m, cmd

	case ViewExec:
		ev, cmd := m.execView.Update(msg)
		m.execView = ev
		if m.execView.done {
			if m.execView.quit {
				return m, tea.Quit
			}
			m.activeView = ViewPicker
		}
		return m, cmd

	case ViewNeeds:
		if m.needsView != nil {
			nv, cmd := m.needsView.Update(msg)
			m.needsView = &nv
			if m.needsView.done {
				m.activeView = ViewPicker
			}
			return m, cmd
		}

	case ViewFull:
		if m.fullView != nil {
			fv, cmd := m.fullView.Update(msg)
			m.fullView = &fv
			if m.fullView.done {
				m.activeView = ViewPicker
			}
			return m, cmd
		}
	}

	return m, nil
}

// View renders the active view.
func (m AppModel) View() string {
	var b strings.Builder

	// Header
	b.WriteString(m.renderHeader())
	b.WriteString("\n")

	switch m.activeView {
	case ViewPicker:
		b.WriteString(m.picker.View())
	case ViewExec:
		b.WriteString(m.execView.View())
	case ViewNeeds:
		if m.needsView != nil {
			b.WriteString(m.needsView.View())
		}
	case ViewFull:
		if m.fullView != nil {
			b.WriteString(m.fullView.View())
		}
	}

	return b.String()
}

func (m AppModel) renderHeader() string {
	brandStyle := lipgloss.NewStyle().Bold(true).Foreground(colorAccent)
	nameStyle := m.styles.Header
	tagStyle := lipgloss.NewStyle().
		Foreground(colorPlatform).
		Bold(true)
	sepStyle := lipgloss.NewStyle().Foreground(colorDim)

	hdr := brandStyle.Render("hdi") + sepStyle.Render(" · ") + nameStyle.Render(m.projectName)

	// Show category/view tag
	var tag string
	switch m.activeView {
	case ViewPicker:
		catLabel := m.picker.CategoryLabel()
		if m.mode == config.ModeDeploy && m.platformDisplay != "" {
			tag = catLabel + " → " + m.platformDisplay
		} else {
			tag = catLabel
		}
	case ViewNeeds:
		tag = "needs"
	case ViewFull:
		tag = "full"
	case ViewExec:
		return hdr
	}

	if tag != "" {
		hdr += "  " + tagStyle.Render(tag)
	}
	return hdr
}
