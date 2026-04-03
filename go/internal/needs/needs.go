package needs

import (
	"fmt"
	"io"
	"os/exec"
	"regexp"
	"strings"

	"github.com/charmbracelet/lipgloss"
	"github.com/grega/hdi/internal/display"
	"github.com/grega/hdi/internal/platform"
	"github.com/grega/hdi/internal/render"
)

var reVersion = regexp.MustCompile(`[0-9]+\.[0-9]+[0-9.]*`)

// ToolInfo represents a discovered tool and its status.
type ToolInfo struct {
	Name      string `json:"tool"`
	Installed bool   `json:"installed"`
	Version   string `json:"version,omitempty"`
}

// CollectTools extracts unique tool names from the display list commands.
func CollectTools(dl *display.DisplayList) []string {
	var tools []string
	seen := make(map[string]bool)

	for _, line := range dl.Lines {
		if line.Type != display.LineCommand {
			continue
		}
		tool := platform.ExtractToolName(line.Command)
		if tool == "" || seen[tool] {
			continue
		}
		seen[tool] = true
		tools = append(tools, tool)
	}
	return tools
}

// CheckTools checks availability and version for each tool.
func CheckTools(tools []string) []ToolInfo {
	var results []ToolInfo
	for _, tool := range tools {
		info := ToolInfo{Name: tool}
		if _, err := exec.LookPath(tool); err == nil {
			info.Installed = true
			info.Version = getVersion(tool)
		}
		results = append(results, info)
	}
	return results
}

// Render prints the needs report to the writer.
func Render(w io.Writer, tools []ToolInfo, projectName string, styles render.Styles) {
	greenStyle := lipgloss.NewStyle().Foreground(lipgloss.Color("2"))
	yellowStyle := lipgloss.NewStyle().Foreground(lipgloss.Color("3"))

	fmt.Fprintf(w, "\n%s  %s\n\n",
		styles.Header.Render(fmt.Sprintf("[hdi] %s", projectName)),
		styles.Dim.Render("needs"))

	found := 0
	missing := 0

	for _, t := range tools {
		if t.Installed {
			if t.Version != "" {
				fmt.Fprintf(w, "  %s %-14s %s\n",
					greenStyle.Render("✓"), t.Name,
					styles.Dim.Render(fmt.Sprintf("(%s)", t.Version)))
			} else {
				fmt.Fprintf(w, "  %s %-14s\n", greenStyle.Render("✓"), t.Name)
			}
			found++
		} else {
			fmt.Fprintf(w, "  %s %-14s %s\n",
				yellowStyle.Render("✗"), t.Name,
				styles.Dim.Render("not found"))
			missing++
		}
	}

	fmt.Fprintln(w)
	if missing == 0 {
		fmt.Fprintf(w, "  %s\n\n", styles.Dim.Render(fmt.Sprintf("✓ All %d tools found", found)))
	} else {
		fmt.Fprintf(w, "  %s\n\n",
			styles.Dim.Render(fmt.Sprintf("%d found, ", found))+
				yellowStyle.Render(fmt.Sprintf("%d not found", missing)))
	}
}

func getVersion(tool string) string {
	// Try --version first
	if ver := tryVersionFlag(tool, "--version"); ver != "" {
		return ver
	}
	// Try -V
	return tryVersionFlag(tool, "-V")
}

func tryVersionFlag(tool, flag string) string {
	cmd := exec.Command(tool, flag)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return ""
	}
	// Take first 5 lines max
	lines := strings.SplitN(string(out), "\n", 6)
	text := strings.Join(lines[:min(len(lines), 5)], "\n")
	if m := reVersion.FindString(text); m != "" {
		return m
	}
	return ""
}
