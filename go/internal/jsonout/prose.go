package jsonout

import (
	"regexp"
	"strings"

	"github.com/grega/hdi/internal/markdown"
)

var (
	reJSONCodeFence = regexp.MustCompile("^\\s*(`{3,}|~{3,})")
	reJSONATXSub    = regexp.MustCompile(`^#{2,6}\s+(.*)`)
	reJSONSetextU   = regexp.MustCompile(`^\s*(={3,}|-{3,})\s*$`)
	reJSONSkipLang  = regexp.MustCompile(`(?i)^(json|yaml|yml|toml|xml|csv|sql|html|css|text|plaintext|txt|output|log|env|ini|conf|properties|graphql|gql|proto|protobuf|hcl|markdown|md|mermaid|diff|patch|svg)$`)
)

// proseParse converts section body text into ModeEntry items for fullProse JSON.
func proseParse(content string) []ModeEntry {
	var entries []ModeEntry
	lines := strings.Split(content, "\n")

	inCode := false
	skipBlock := false
	fenceChar := byte(0)
	havePrev := false
	prevLine := ""

	emitProseLine := func(l string) {
		if isBlank(l) {
			entries = append(entries, ModeEntry{Type: "empty", Text: ""})
			return
		}
		if m := reJSONATXSub.FindStringSubmatch(l); m != nil {
			sub := m[1]
			sub = markdown.StripTrailingHashesExported(sub)
			sub = markdown.StripFormattingExported(sub)
			entries = append(entries, ModeEntry{Type: "subheader", Text: sub})
			return
		}
		entries = append(entries, ModeEntry{Type: "prose", Text: l})
	}

	for _, line := range lines {
		// Fenced code blocks
		if m := reJSONCodeFence.FindStringSubmatch(line); m != nil {
			fence := m[1]
			if havePrev && !inCode {
				emitProseLine(prevLine)
				havePrev = false
				prevLine = ""
			}
			if inCode {
				if fence[0] == fenceChar {
					inCode = false
					skipBlock = false
					fenceChar = 0
				}
			} else {
				inCode = true
				fenceChar = fence[0]
				skipBlock = false
				// Extract language
				rest := line[strings.Index(line, fence)+len(fence):]
				rest = strings.TrimLeft(rest, " \t")
				lang := strings.FieldsFunc(rest, func(r rune) bool {
					return r == ' ' || r == '\t'
				})
				if len(lang) > 0 {
					l := lang[0]
					end := 0
					for i, c := range l {
						if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_' || c == '-' {
							end = i + 1
						} else {
							break
						}
					}
					if end > 0 && reJSONSkipLang.MatchString(l[:end]) {
						skipBlock = true
					}
				}
			}
			continue
		}

		if inCode {
			if skipBlock {
				entries = append(entries, ModeEntry{Type: "prose", Text: line})
			} else {
				stripped := strings.TrimLeft(line, " \t")
				stripped = markdown.StripPrompt(stripped)
				entries = append(entries, ModeEntry{Type: "command", Text: stripped})
			}
			continue
		}

		// Setext heading detection
		if havePrev && reJSONSetextU.MatchString(line) {
			sub := markdown.StripFormattingExported(prevLine)
			entries = append(entries, ModeEntry{Type: "subheader", Text: sub})
			havePrev = false
			prevLine = ""
			continue
		}

		if havePrev {
			emitProseLine(prevLine)
		}
		prevLine = line
		havePrev = true
	}

	if havePrev {
		emitProseLine(prevLine)
	}

	return entries
}
