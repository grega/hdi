package jsonout

import (
	"encoding/json"
	"io"
	"os"
	"path/filepath"

	"github.com/grega/hdi/internal/config"
	"github.com/grega/hdi/internal/display"
	"github.com/grega/hdi/internal/markdown"
	"github.com/grega/hdi/internal/needs"
	"github.com/grega/hdi/internal/platform"
)

// Output is the top-level JSON structure.
type Output struct {
	Modes     map[string][]ModeEntry `json:"modes"`
	FullProse map[string][]ModeEntry `json:"fullProse"`
	Needs     []needs.ToolInfo       `json:"needs"`
	Platforms []platform.Platform    `json:"platforms"`
}

// ModeEntry represents a single item in a mode's display list.
type ModeEntry struct {
	Type string `json:"type"`
	Text string `json:"text"`
}

// Render produces the full JSON output.
func Render(w io.Writer, readmePath string) error {
	content, err := os.ReadFile(readmePath)
	if err != nil {
		return err
	}
	src := string(content)

	modes := []string{"default", "install", "run", "test", "deploy", "all"}

	out := Output{
		Modes:     make(map[string][]ModeEntry),
		FullProse: make(map[string][]ModeEntry),
	}

	// Build modes and fullProse
	for _, mode := range modes {
		m := modeFromString(mode)
		pattern := markdown.PatternForMode(m)
		sections := markdown.ParseSections(src, pattern, readmePath)

		// modes: display list entries
		dl := display.BuildDisplayList(sections)
		var entries []ModeEntry
		for _, line := range dl.Lines {
			if line.Type == display.LineEmpty && line.Text == "" {
				continue
			}
			entries = append(entries, ModeEntry{
				Type: line.Type.String(),
				Text: line.Text,
			})
		}
		if entries == nil {
			entries = []ModeEntry{}
		}
		out.Modes[mode] = entries

		// fullProse: prose + commands
		out.FullProse[mode] = buildFullProse(sections)
	}

	// Needs: use "all" pattern
	allPattern := markdown.PatternForMode(config.ModeAll)
	allSections := markdown.ParseSections(src, allPattern, readmePath)
	allDL := display.BuildDisplayList(allSections)
	tools := needs.CollectTools(allDL)
	toolInfos := needs.CheckTools(tools)
	if toolInfos == nil {
		toolInfos = []needs.ToolInfo{}
	}
	out.Needs = toolInfos

	// Platforms: use "deploy" pattern
	deployPattern := markdown.PatternForMode(config.ModeDeploy)
	deploySections := markdown.ParseSections(src, deployPattern, readmePath)
	deployDL := display.BuildDisplayList(deploySections)

	det := &platform.Detector{}
	dir := filepath.Dir(readmePath)
	det.DetectFromFiles(dir)
	det.DetectFromCommands(deployDL)

	var bodies []string
	for _, sec := range deploySections {
		bodies = append(bodies, sec.Body)
	}
	det.DetectFromProse(bodies)

	platforms := det.Platforms()
	if platforms == nil {
		platforms = []platform.Platform{}
	}
	out.Platforms = platforms

	enc := json.NewEncoder(w)
	enc.SetIndent("", "  ")
	enc.SetEscapeHTML(false)
	return enc.Encode(out)
}

func modeFromString(s string) config.Mode {
	switch s {
	case "install":
		return config.ModeInstall
	case "run":
		return config.ModeRun
	case "test":
		return config.ModeTest
	case "deploy":
		return config.ModeDeploy
	case "all":
		return config.ModeAll
	default:
		return config.ModeDefault
	}
}

func buildFullProse(sections []markdown.Section) []ModeEntry {
	var entries []ModeEntry

	for _, sec := range sections {
		content := sec.Body
		// Strip trailing blank lines
		content = stripTrailingBlanks(content)
		if content == "" {
			continue
		}

		entries = append(entries, ModeEntry{Type: "header", Text: sec.Title})
		entries = append(entries, proseParse(content)...)
	}

	if entries == nil {
		entries = []ModeEntry{}
	}
	return entries
}

func stripTrailingBlanks(s string) string {
	lines := splitLines(s)
	for len(lines) > 0 && isBlank(lines[len(lines)-1]) {
		lines = lines[:len(lines)-1]
	}
	if len(lines) == 0 {
		return ""
	}
	result := ""
	for i, l := range lines {
		if i > 0 {
			result += "\n"
		}
		result += l
	}
	return result
}

func splitLines(s string) []string {
	if s == "" {
		return nil
	}
	lines := make([]string, 0)
	for len(s) > 0 {
		idx := indexByte(s, '\n')
		if idx < 0 {
			lines = append(lines, s)
			break
		}
		lines = append(lines, s[:idx])
		s = s[idx+1:]
	}
	return lines
}

func indexByte(s string, b byte) int {
	for i := 0; i < len(s); i++ {
		if s[i] == b {
			return i
		}
	}
	return -1
}

func isBlank(s string) bool {
	for _, c := range s {
		if c != ' ' && c != '\t' && c != '\r' {
			return false
		}
	}
	return true
}
