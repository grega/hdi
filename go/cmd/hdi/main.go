package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/grega/hdi/internal/config"
	"github.com/grega/hdi/internal/display"
	"github.com/grega/hdi/internal/jsonout"
	"github.com/grega/hdi/internal/markdown"
	"github.com/grega/hdi/internal/needs"
	"github.com/grega/hdi/internal/platform"
	"github.com/grega/hdi/internal/readme"
	"github.com/grega/hdi/internal/render"
	"github.com/grega/hdi/internal/tui"
)

const helpText = `hdi - "How do I..." - Extracts setup/run/test commands from a README.

Usage:
  hdi                           Interactive picker - shows all sections (default)
  hdi install                   Just install/setup commands (aliases: setup, i)
  hdi run                       Just run/start commands (aliases: start, r)
  hdi test                      Just test commands (alias: t)
  hdi deploy                    Just deploy/release commands and platform detection (alias: d)
  hdi all                       Show all matched sections (currently the default mode)
  hdi contrib                   Show commands from contributor/development docs (alias: c)
  hdi needs                     Check if required tools are installed (alias: n)
  hdi [mode] --no-interactive   Print commands without the picker (alias: --ni)
  hdi [mode] --full             Include prose around commands
  hdi [mode] --raw              Plain markdown output (no colour, good for piping)
  hdi --json                    Structured JSON output (includes all sections)
  hdi [mode] /path              Scan a specific directory
  hdi [mode] /path/to/file.md   Parse a specific markdown file

Interactive controls:
  ↑/↓  k/j           Navigate commands
  Tab                Cycle category (all/install/run/test/deploy)
  /                  Filter/search commands
  Enter              Execute the highlighted command
  c                  Copy highlighted command to clipboard
  n                  Show tool dependencies
  f                  Show full prose view
  ?                  Toggle help
  q / Esc / Ctrl+C   Quit
`

func main() {
	cfg := config.Config{
		Mode:        config.ModeDefault,
		Interactive: config.InteractiveAuto,
		Dir:         ".",
	}

	if err := parseArgs(&cfg, os.Args[1:]); err != nil {
		fmt.Fprintf(os.Stderr, "hdi: %s\n", err)
		fmt.Fprintln(os.Stderr, "Try: hdi --help")
		os.Exit(1)
	}

	if err := run(cfg); err != nil {
		if msg := err.Error(); msg != "" {
			fmt.Fprintln(os.Stderr, msg)
		}
		os.Exit(1)
	}
}

func parseArgs(cfg *config.Config, args []string) error {
	for _, arg := range args {
		switch arg {
		case "install", "setup", "i":
			cfg.Mode = config.ModeInstall
		case "run", "start", "r":
			cfg.Mode = config.ModeRun
		case "test", "t":
			cfg.Mode = config.ModeTest
		case "deploy", "d":
			cfg.Mode = config.ModeDeploy
		case "all", "a":
			cfg.Mode = config.ModeAll
		case "needs", "n":
			cfg.Mode = config.ModeNeeds
		case "contrib", "c":
			cfg.Mode = config.ModeContrib
		case "--full", "-f":
			cfg.Full = true
		case "--raw":
			cfg.Raw = true
			cfg.Interactive = config.InteractiveNo
		case "--json":
			cfg.JSON = true
			cfg.Interactive = config.InteractiveNo
		case "--no-interactive", "--ni":
			cfg.Interactive = config.InteractiveNo
		case "--version", "-v":
			fmt.Printf("hdi %s\n", config.Version)
			os.Exit(0)
		case "--help", "-h":
			fmt.Print(helpText)
			os.Exit(0)
		default:
			info, err := os.Stat(arg)
			if err == nil && info.IsDir() {
				cfg.Dir = arg
			} else if err == nil && !info.IsDir() && (strings.HasSuffix(arg, ".md") || strings.HasSuffix(arg, ".rst")) {
				cfg.File = arg
			} else {
				return fmt.Errorf("unknown argument: %s", arg)
			}
		}
	}

	// Resolve interactive mode
	if cfg.Interactive == config.InteractiveAuto {
		if isTerminal(os.Stdin) && isTerminal(os.Stdout) && !cfg.Full {
			cfg.Interactive = config.InteractiveYes
		} else {
			cfg.Interactive = config.InteractiveNo
		}
	}

	// Benchmark mode
	if os.Getenv("_HDI_BENCH_PICKER") == "1" {
		cfg.Interactive = config.InteractiveYes
	}

	return nil
}

func run(cfg config.Config) error {
	// JSON mode is handled separately (reparses all modes)
	if cfg.JSON {
		return runJSON(cfg)
	}

	// Discover README
	readmePath := ""
	if cfg.File != "" {
		readmePath = cfg.File
	} else {
		readmePath = readme.FindREADME(cfg.Dir)
	}

	if readmePath == "" && cfg.Mode != config.ModeContrib {
		renderer := lipgloss.DefaultRenderer()
		styles := render.DefaultStyles(renderer)
		fmt.Fprintf(os.Stderr, "%s\n", styles.Header.Render(fmt.Sprintf("hdi: no README found in %s", cfg.Dir)))
		fmt.Fprintf(os.Stderr, "%s\n", styles.Dim.Render("Looked for README.md, readme.md, Readme.md, README.rst"))
		fmt.Fprintf(os.Stderr, "%s\n", styles.Dim.Render("Try: hdi --help"))
		return fmt.Errorf("")
	}

	// Build keyword pattern
	pattern := markdown.PatternForMode(cfg.Mode)

	// Parse sections
	var sections []markdown.Section

	if cfg.Mode != config.ModeContrib && readmePath != "" {
		content, err := os.ReadFile(readmePath)
		if err != nil {
			return fmt.Errorf("hdi: cannot read %s: %w", readmePath, err)
		}
		sections = markdown.ParseSections(string(content), pattern, readmePath)
	}

	// Parse contributor docs
	if cfg.File == "" {
		contribFiles := readme.FindContribDocs(cfg.Dir)
		if cfg.Mode == config.ModeContrib && len(contribFiles) == 0 {
			return fmt.Errorf("hdi: no contributor docs found in %s\nLooked for CONTRIBUTING.md, DEVELOPMENT.md, DEVELOPERS.md, HACKING.md", cfg.Dir)
		}
		for _, cf := range contribFiles {
			content, err := os.ReadFile(cf)
			if err != nil {
				continue
			}
			contribSections := markdown.ParseSections(string(content), pattern, cf)
			sections = append(sections, contribSections...)
		}
	}

	if len(sections) == 0 {
		if cfg.Mode == config.ModeContrib {
			return fmt.Errorf("hdi: no matching sections found in contributor docs")
		}
		return fmt.Errorf("hdi: no matching sections found in %s\nTry: hdi all --full", readmePath)
	}

	// Resolve project name
	projectDir := cfg.Dir
	if cfg.File != "" {
		projectDir = filepath.Dir(cfg.File)
	}
	absDir, err := filepath.Abs(projectDir)
	if err != nil {
		absDir = projectDir
	}
	projectName := filepath.Base(absDir)

	// Build display list
	dl := display.BuildDisplayList(sections)

	// Platform detection (deploy mode)
	var platformDisplay string
	if cfg.Mode == config.ModeDeploy {
		platformDisplay = detectAndFormatPlatforms(cfg, dl)
	}

	// Needs mode
	if cfg.Mode == config.ModeNeeds {
		return runNeeds(dl, sections, projectName, cfg)
	}

	// Interactive mode
	if cfg.Interactive == config.InteractiveYes && !cfg.Full {
		return runInteractive(cfg, sections, projectName, platformDisplay)
	}

	// Non-interactive rendering
	renderer := lipgloss.DefaultRenderer()
	styles := render.DefaultStyles(renderer)

	if !cfg.Raw {
		header := styles.Header.Render(fmt.Sprintf("[hdi] %s", projectName))
		modeTag := renderModeTag(cfg.Mode, platformDisplay, styles)
		if modeTag != "" {
			header += "  " + modeTag
		}
		fmt.Printf("%s\n\n", header)
	}

	if cfg.Full {
		render.Full(os.Stdout, sections, styles, cfg.Raw)
	} else if cfg.Raw {
		render.Raw(os.Stdout, dl)
	} else {
		render.Static(os.Stdout, dl, styles)
	}

	if !cfg.Raw {
		fmt.Println()
		if !cfg.Full {
			fmt.Printf("  %s\n\n", styles.Dim.Render("─ add --full for prose, or: install | run | deploy | all"))
		}
	}

	return nil
}

func renderModeTag(mode config.Mode, platformDisplay string, styles render.Styles) string {
	switch mode {
	case config.ModeInstall:
		return styles.Dim.Render("[install]")
	case config.ModeRun:
		return styles.Dim.Render("[run]")
	case config.ModeTest:
		return styles.Dim.Render("[test]")
	case config.ModeDeploy:
		if platformDisplay != "" {
			return styles.Dim.Render("[deploy → ") + styles.SectionName.Render(platformDisplay) + styles.Dim.Render("]")
		}
		return styles.Dim.Render("[deploy]")
	case config.ModeAll:
		return styles.Dim.Render("[all]")
	case config.ModeContrib:
		return styles.Dim.Render("[contrib]")
	}
	return ""
}

// isTerminal checks if a file is a terminal.
func isTerminal(f *os.File) bool {
	info, err := f.Stat()
	if err != nil {
		return false
	}
	return (info.Mode() & os.ModeCharDevice) != 0
}

func runJSON(cfg config.Config) error {
	readmePath := ""
	if cfg.File != "" {
		readmePath = cfg.File
	} else {
		readmePath = readme.FindREADME(cfg.Dir)
	}
	if readmePath == "" {
		return fmt.Errorf("hdi: no README found in %s", cfg.Dir)
	}
	return jsonout.Render(os.Stdout, readmePath)
}

func runNeeds(dl *display.DisplayList, sections []markdown.Section, projectName string, cfg config.Config) error {
	// If interactive, use the new TUI with needs view
	if cfg.Interactive == config.InteractiveYes {
		cs := tui.BuildCommandSet(sections)
		if len(cs.All) == 0 {
			return fmt.Errorf("hdi: no tool references found in commands\nTry: hdi all --full")
		}
		app := tui.NewApp(tui.AppConfig{
			CommandSet:  cs,
			Sections:    sections,
			ProjectName: projectName,
			Mode:        cfg.Mode,
			StartView:   tui.ViewNeeds,
		})
		p := tea.NewProgram(app)
		_, err := p.Run()
		return err
	}

	tools := needs.CollectTools(dl)
	if len(tools) == 0 {
		return fmt.Errorf("hdi: no tool references found in commands\nTry: hdi all --full")
	}
	toolInfos := needs.CheckTools(tools)
	renderer := lipgloss.DefaultRenderer()
	styles := render.DefaultStyles(renderer)
	needs.Render(os.Stdout, toolInfos, projectName, styles)
	return nil
}

func runInteractive(cfg config.Config, sections []markdown.Section, projectName string, platformDisplay string) error {
	cs := tui.BuildCommandSet(sections)

	if len(cs.All) == 0 {
		renderer := lipgloss.DefaultRenderer()
		styles := render.DefaultStyles(renderer)
		if platformDisplay != "" {
			fmt.Printf("%s  %s\n\n",
				styles.Header.Render(fmt.Sprintf("[hdi] %s", projectName)),
				styles.Dim.Render(fmt.Sprintf("[deploy → %s]", platformDisplay)))
		}
		fmt.Fprintf(os.Stderr, "%s\n", styles.Header.Render("hdi: no commands to pick from"))
		fmt.Fprintf(os.Stderr, "%s\n", styles.Dim.Render("Try: hdi all --full"))
		return fmt.Errorf("")
	}

	app := tui.NewApp(tui.AppConfig{
		CommandSet:      cs,
		Sections:        sections,
		ProjectName:     projectName,
		Mode:            cfg.Mode,
		PlatformDisplay: platformDisplay,
	})
	p := tea.NewProgram(app)
	_, err := p.Run()
	return err
}

func detectAndFormatPlatforms(cfg config.Config, dl *display.DisplayList) string {
	det := &platform.Detector{}

	projectDir := cfg.Dir
	if cfg.File != "" {
		projectDir = filepath.Dir(cfg.File)
	}

	det.DetectFromFiles(projectDir)
	det.DetectFromCommands(dl)

	// For prose detection, we need section bodies - re-parse
	readmePath := ""
	if cfg.File != "" {
		readmePath = cfg.File
	} else {
		readmePath = readme.FindREADME(cfg.Dir)
	}
	if readmePath != "" {
		content, err := os.ReadFile(readmePath)
		if err == nil {
			pattern := markdown.PatternForMode(config.ModeDeploy)
			sections := markdown.ParseSections(string(content), pattern, readmePath)
			var bodies []string
			for _, sec := range sections {
				bodies = append(bodies, sec.Body)
			}
			det.DetectFromProse(bodies)
		}
	}

	return det.FormatDisplay()
}
