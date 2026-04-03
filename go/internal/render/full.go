package render

import (
	"fmt"
	"io"
	"regexp"
	"strings"

	"github.com/grega/hdi/internal/markdown"
)

var (
	reFullATXSub    = regexp.MustCompile(`^#{2,}\s+(.*)`)
	reFullSetextU   = regexp.MustCompile(`^\s*(={3,}|-{3,})\s*$`)
	reFullBacktick  = regexp.MustCompile("`([^`]+)`")
	reFullCodeFence = regexp.MustCompile("^\\s*(`{3,}|~{3,})")
)

// Full renders sections with full prose text and commands.
func Full(w io.Writer, sections []markdown.Section, styles Styles, raw bool) {
	prevSource := ""
	width := 60 // default width for section headers

	for _, sec := range sections {
		// File separator when source changes
		if prevSource != "" && sec.Source != "" && sec.Source != prevSource {
			name := baseName(sec.Source)
			if raw {
				fmt.Fprintf(w, "\n--- %s ---\n", name)
			} else {
				fmt.Fprintf(w, "\n%s\n\n", fileSeparator(name, width, styles))
			}
		}
		prevSource = sec.Source

		content := stripTrailingBlanks(sec.Body)
		if content == "" {
			continue
		}

		if raw {
			fmt.Fprintf(w, "\n## %s\n\n%s\n\n", sec.Title, content)
			continue
		}

		fmt.Fprintf(w, "\n%s\n", sectionHeader(sec.Title, width, styles))

		lines := strings.Split(content, "\n")
		inCode := false
		codeBuf := ""
		fenceChar := byte(0)
		havePrev := false
		prevLine := ""

		renderLine := func(l string) {
			if strings.TrimSpace(l) == "" {
				fmt.Fprintln(w)
				return
			}
			// ATX sub-heading
			if m := reFullATXSub.FindStringSubmatch(l); m != nil {
				sub := m[1]
				sub = markdown.StripTrailingHashesExported(sub)
				sub = markdown.StripFormattingExported(sub)
				fmt.Fprintf(w, "  %s\n", styles.SubHeader.Render(sub))
				return
			}
			// Highlight backtick content
			formatted := highlightBackticks(l, styles)
			fmt.Fprintf(w, "  %s\n", formatted)
		}

		for _, line := range lines {
			// Fenced code blocks
			if m := reFullCodeFence.FindStringSubmatch(line); m != nil {
				fence := m[1]
				if havePrev && !inCode {
					renderLine(prevLine)
					havePrev = false
					prevLine = ""
				}
				if inCode {
					if fence[0] == fenceChar {
						// Render code buffer with inverted green
						codeStyle := styles.Command.Reverse(true)
						for _, cl := range strings.Split(strings.TrimRight(codeBuf, "\n"), "\n") {
							fmt.Fprintf(w, "%s\n", codeStyle.Render("  "+cl))
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

			// Setext heading detection
			if havePrev && reFullSetextU.MatchString(line) {
				sub := markdown.StripFormattingExported(prevLine)
				fmt.Fprintf(w, "  %s\n", styles.SubHeader.Render(sub))
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
}

// highlightBackticks replaces `code` with green-styled text.
func highlightBackticks(line string, styles Styles) string {
	return reFullBacktick.ReplaceAllStringFunc(line, func(match string) string {
		inner := match[1 : len(match)-1]
		return styles.Command.Render(inner)
	})
}

// stripTrailingBlanks removes trailing blank lines from content.
func stripTrailingBlanks(content string) string {
	lines := strings.Split(content, "\n")
	// Remove trailing empty/whitespace-only lines
	for len(lines) > 0 && strings.TrimSpace(lines[len(lines)-1]) == "" {
		lines = lines[:len(lines)-1]
	}
	if len(lines) == 0 {
		return ""
	}
	return strings.Join(lines, "\n")
}

func baseName(path string) string {
	i := strings.LastIndex(path, "/")
	if i >= 0 {
		return path[i+1:]
	}
	return path
}
