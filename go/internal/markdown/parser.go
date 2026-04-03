package markdown

import (
	"regexp"
	"strings"
)

// Section represents a matched section from a markdown document.
type Section struct {
	Title  string
	Body   string
	Source string // file path this section was extracted from
}

var (
	reATXHeading    = regexp.MustCompile(`^(#{1,6})\s+(.*)`)
	reSetextUnder   = regexp.MustCompile(`^\s*(={3,}|-{3,})\s*$`)
	reBoldPseudo    = regexp.MustCompile(`^\s*\*\*([^*]+)\*\*\s*$`)
	reCodeFence     = regexp.MustCompile("^\\s*(`{3,}|~{3,})")
	reTrailingHash  = regexp.MustCompile(`^(.*[^#\s])\s*#+$`)
	reBold          = regexp.MustCompile(`\*\*([^*]+)\*\*`)
	reItalicStar    = regexp.MustCompile(`\*([^*]+)\*`)
	reBoldUnder     = regexp.MustCompile(`__([^_]+)__`)
	reItalicUnder   = regexp.MustCompile(`_([^_]+)_`)
)

// StripFormattingExported removes bold and italic markdown markers from text.
// Exported for use by the render package.
func StripFormattingExported(text string) string {
	return stripFormatting(text)
}

// StripTrailingHashesExported removes trailing ATX closing hashes.
// Exported for use by the render package.
func StripTrailingHashesExported(text string) string {
	return stripTrailingHashes(text)
}

// stripFormatting removes bold and italic markdown markers from text.
func stripFormatting(text string) string {
	for reBold.MatchString(text) {
		text = reBold.ReplaceAllString(text, "$1")
	}
	for reItalicStar.MatchString(text) {
		text = reItalicStar.ReplaceAllString(text, "$1")
	}
	for reBoldUnder.MatchString(text) {
		text = reBoldUnder.ReplaceAllString(text, "$1")
	}
	for reItalicUnder.MatchString(text) {
		text = reItalicUnder.ReplaceAllString(text, "$1")
	}
	return text
}

// stripTrailingHashes removes trailing ATX closing hashes from heading text.
func stripTrailingHashes(text string) string {
	if m := reTrailingHash.FindStringSubmatch(text); m != nil {
		return m[1]
	}
	return text
}

// ParseSections extracts sections whose headings match pattern from markdown content.
// source is the file path used for Section.Source.
func ParseSections(content string, pattern *regexp.Regexp, source string) []Section {
	var sections []Section

	inSection := false
	sectionLevel := 0
	headingText := ""
	body := ""

	inCode := false
	fenceChar := byte(0)

	lines := strings.Split(content, "\n")
	// Remove trailing empty string from split if content ends with newline
	if len(lines) > 0 && lines[len(lines)-1] == "" {
		lines = lines[:len(lines)-1]
	}

	havePrev := false
	prevLine := ""

	// handleHeading processes a heading at the given level.
	// Returns true if a new section was started.
	handleHeading := func(text string, level int) bool {
		text = stripTrailingHashes(text)
		text = stripFormatting(text)

		startedNew := false

		if inSection {
			if level <= sectionLevel {
				sections = append(sections, Section{Title: headingText, Body: body, Source: source})
				inSection = false
				body = ""
			} else if pattern.MatchString(text) {
				// Deeper child heading also matches - save parent body first
				sections = append(sections, Section{Title: headingText, Body: body, Source: source})
				inSection = false
				body = ""
			}
		}

		if pattern.MatchString(text) {
			inSection = true
			sectionLevel = level
			headingText = text
			body = ""
			startedNew = true
		}

		return startedNew
	}

	for i := 0; i < len(lines); i++ {
		line := lines[i]

		// Track fenced code blocks
		if m := reCodeFence.FindStringSubmatch(line); m != nil {
			fence := m[1]
			if inCode {
				if fence[0] == fenceChar {
					inCode = false
					fenceChar = 0
				}
			} else {
				inCode = true
				fenceChar = fence[0]
			}
			// Include fence lines in body if we're in a section
			if havePrev {
				if inSection {
					body += prevLine + "\n"
				}
				havePrev = false
				prevLine = ""
			}
			if inSection {
				body += line + "\n"
			}
			continue
		}

		// Inside a code block - skip heading detection, just accumulate body
		if inCode {
			if havePrev {
				if inSection {
					body += prevLine + "\n"
				}
				havePrev = false
				prevLine = ""
			}
			if inSection {
				body += line + "\n"
			}
			continue
		}

		// Check for setext underline
		if havePrev && reSetextUnder.MatchString(line) {
			m := reSetextUnder.FindStringSubmatch(line)
			setextChar := m[1][0]
			level := 2
			if setextChar == '=' {
				level = 1
			}
			startedNew := handleHeading(prevLine, level)
			// Keep non-matching setext sub-headings in body (as ATX) for sub-grouping
			if inSection && !startedNew {
				if level == 1 {
					body += "# " + prevLine + "\n"
				} else {
					body += "## " + prevLine + "\n"
				}
			}
			havePrev = false
			prevLine = ""
			continue
		}

		// Process the buffered previous line
		if havePrev {
			if m := reATXHeading.FindStringSubmatch(prevLine); m != nil {
				hashes := m[1]
				level := len(hashes)
				text := m[2]
				startedNew := handleHeading(text, level)
				// Keep non-matching ATX sub-headings in body for sub-grouping
				if inSection && !startedNew {
					body += prevLine + "\n"
				}
			} else if m := reBoldPseudo.FindStringSubmatch(prevLine); m != nil {
				boldText := m[1]
				startedNew := false
				if !inSection || sectionLevel == 7 {
					startedNew = handleHeading(boldText, 7)
				}
				if inSection && !startedNew {
					body += prevLine + "\n"
				}
			} else if inSection {
				body += prevLine + "\n"
			}
		}

		prevLine = line
		havePrev = true
	}

	// Process final buffered line
	if havePrev && !inCode {
		if m := reATXHeading.FindStringSubmatch(prevLine); m != nil {
			hashes := m[1]
			level := len(hashes)
			text := m[2]
			startedNew := handleHeading(text, level)
			if inSection && !startedNew {
				body += prevLine + "\n"
			}
		} else if m := reBoldPseudo.FindStringSubmatch(prevLine); m != nil {
			boldText := m[1]
			startedNew := false
			if !inSection || sectionLevel == 7 {
				startedNew = handleHeading(boldText, 7)
			}
			if inSection && !startedNew {
				body += prevLine + "\n"
			}
		} else if inSection {
			body += prevLine + "\n"
		}
	}

	if inSection {
		sections = append(sections, Section{Title: headingText, Body: body, Source: source})
	}

	return sections
}
