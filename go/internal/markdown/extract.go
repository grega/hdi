package markdown

import (
	"regexp"
	"strings"
)

// SubHeaderMarker is the prefix byte used to mark sub-header entries in
// extracted command lists, matching the Bash version's \x01 marker.
const SubHeaderMarker = "\x01"

var (
	reSkipLang = regexp.MustCompile(`(?i)^(json|yaml|yml|toml|xml|csv|sql|html|css|text|plaintext|txt|output|log|env|ini|conf|properties|graphql|gql|proto|protobuf|hcl|markdown|md|mermaid|diff|patch|svg)$`)

	reConsoleLang = regexp.MustCompile(`(?i)^(console|terminal)$`)

	cmdPrefixes = `yarn|npm|npx|pnpm|pnpx|bunx|node|bun|deno|corepack` +
		`|python3?|pip3?|pipenv|poetry|uv|conda|mamba` +
		`|ruby|gem|bundle|rake|rails` +
		`|cargo|rustup` +
		`|go|zig` +
		`|java|javac|mvn|gradle|sbt|lein|clj|mill` +
		`|dotnet` +
		`|swift|flutter|dart` +
		`|elixir|mix|iex` +
		`|php|composer|perl|lua` +
		`|cabal|stack` +
		`|docker|docker-compose|podman` +
		`|make|cmake|just|task|bazel|pants` +
		`|bash|sh|zsh` +
		`|curl|wget|git|sudo|apt|apt-get|brew|yum|dnf|pacman` +
		`|kubectl|terraform|ansible|helm` +
		`|nix|mise|asdf|rtx|fnm|nvm|volta` +
		`|ng|vue|vite|turbo|nx`

	reCmdSpace      = regexp.MustCompile(`(?i)^(` + cmdPrefixes + `) `)
	reCmdEnd        = regexp.MustCompile(`(?i)^(` + cmdPrefixes + `)( |$)`)
	reIndentedCmd   = regexp.MustCompile(`(?i)^\s*(\$\s+)?(` + cmdPrefixes + `)( |$)`)
	rePrompt        = regexp.MustCompile(`^\s*[$%]\s+(.*)`)
	reATXSub        = regexp.MustCompile(`^#{2,6}\s+(.*)`)
	reBoldPseudoSub = regexp.MustCompile(`^\s*\*\*([^*]+)\*\*\s*$`)
	reIndented      = regexp.MustCompile(`^( {4,}|\t)`)
	reBackslashCont = regexp.MustCompile(`\\[\s]*$`)
	reBacktick      = regexp.MustCompile("`([^`]+)`")
)

// StripPrompt removes a leading $ or % prompt prefix from a line.
// The regex requires whitespace after $ so "$HOME/bin" is never mangled.
func StripPrompt(line string) string {
	if m := rePrompt.FindStringSubmatch(line); m != nil {
		return m[1]
	}
	return line
}

// FindBacktickCommands extracts commands from inline backticks in text.
// If requireArgs is true, the prefix must be followed by a space.
// If false, bare prefixes are allowed (for headings like `make`).
func FindBacktickCommands(text string, requireArgs bool) []string {
	pat := reCmdSpace
	if !requireArgs {
		pat = reCmdEnd
	}

	var results []string
	matches := reBacktick.FindAllStringSubmatch(text, -1)
	for _, m := range matches {
		content := m[1]
		if pat.MatchString(content) {
			results = append(results, content)
		}
	}
	return results
}

// extractLang extracts the language identifier from a code fence opening line.
func extractLang(line string, fence string) string {
	rest := line[strings.Index(line, fence)+len(fence):]
	rest = strings.TrimLeft(rest, " \t")
	// Take first word, strip non-alphanumeric suffix
	lang := strings.FieldsFunc(rest, func(r rune) bool {
		return r == ' ' || r == '\t'
	})
	if len(lang) == 0 {
		return ""
	}
	// Strip trailing non-alphanumeric/dash/underscore chars
	l := lang[0]
	end := 0
	for i, c := range l {
		if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_' || c == '-' {
			end = i + 1
		} else {
			break
		}
	}
	return l[:end]
}

// ExtractCommands pulls command strings from a section body.
// When grouped is true, sub-headings produce marker lines prefixed with SubHeaderMarker.
func ExtractCommands(body string, grouped bool) []string {
	var commands []string
	inCode := false
	skipBlock := false
	fenceChar := byte(0)
	continuationBuf := ""
	consoleMode := false
	var indentedBuf []string

	lines := strings.Split(body, "\n")

	flushIndented := func() {
		if len(indentedBuf) == 0 {
			return
		}
		joined := strings.Join(indentedBuf, "\n")
		if reIndentedCmd.MatchString(joined) {
			for _, iline := range indentedBuf {
				if strings.TrimSpace(iline) == "" {
					continue
				}
				commands = append(commands, StripPrompt(iline))
			}
		}
		indentedBuf = nil
	}

	for _, line := range lines {
		// Check for code fence
		if m := reCodeFence.FindStringSubmatch(line); m != nil {
			fence := m[1]
			if inCode {
				// Only close if same fence character
				if fence[0] == fenceChar {
					// Flush pending continuation
					if continuationBuf != "" {
						commands = append(commands, continuationBuf)
						continuationBuf = ""
					}
					inCode = false
					if !skipBlock && len(commands) > 0 {
						// Add separator (empty string) between code blocks
						commands = append(commands, "")
					}
					skipBlock = false
					fenceChar = 0
					consoleMode = false
				}
			} else {
				inCode = true
				fenceChar = fence[0]
				lang := extractLang(line, fence)
				if lang != "" {
					if reSkipLang.MatchString(lang) {
						skipBlock = true
					} else if reConsoleLang.MatchString(lang) {
						consoleMode = true
					}
				}
			}
			continue
		}

		if inCode && !skipBlock {
			stripped := strings.TrimLeft(line, " \t")
			if consoleMode {
				// In console mode, only extract lines with $ or % prompts
				if rePrompt.MatchString(stripped) {
					stripped = StripPrompt(stripped)
				} else {
					continue
				}
			} else {
				stripped = StripPrompt(stripped)
			}
			// Handle backslash line continuations
			if reBackslashCont.MatchString(stripped) {
				// Remove trailing backslash and whitespace
				s := strings.TrimRight(stripped, " \t")
				s = strings.TrimRight(s, "\\")
				continuationBuf += s + " "
			} else if continuationBuf != "" {
				commands = append(commands, continuationBuf+stripped)
				continuationBuf = ""
			} else {
				commands = append(commands, stripped)
			}
		} else if !inCode {
			// Detect sub-headings and bold pseudo-headings for display grouping
			if grouped {
				if m := reATXSub.FindStringSubmatch(line); m != nil {
					label := m[1]
					label = stripTrailingHashes(label)
					label = stripBoldItalic(label)
					commands = append(commands, SubHeaderMarker+label)
					// Fall through to check inline backtick commands in heading text
				} else if m := reBoldPseudoSub.FindStringSubmatch(line); m != nil {
					commands = append(commands, SubHeaderMarker+m[1])
					continue
				}
			}

			// Detect indented code blocks (4+ spaces or tab)
			if reIndented.MatchString(line) && strings.TrimSpace(line) != "" {
				dedented := line
				if strings.HasPrefix(line, "\t") {
					dedented = strings.TrimPrefix(line, "\t")
				} else {
					// Remove up to 4 leading spaces
					dedented = strings.TrimPrefix(line, "    ")
				}
				indentedBuf = append(indentedBuf, dedented)
				continue
			}

			// Flush indented buffer when we leave indented block
			flushIndented()

			// Check for inline backtick commands
			cmds := FindBacktickCommands(line, true)
			commands = append(commands, cmds...)
		}
	}

	// Flush any remaining indented buffer
	flushIndented()

	return commands
}

// stripBoldItalic removes **bold** and *italic* markers.
func stripBoldItalic(text string) string {
	for reBold.MatchString(text) {
		text = reBold.ReplaceAllString(text, "$1")
	}
	for reItalicStar.MatchString(text) {
		text = reItalicStar.ReplaceAllString(text, "$1")
	}
	return text
}

// CleanCommands removes trailing empty strings from a command slice
// and filters out pure separator entries.
func CleanCommands(cmds []string) []string {
	var result []string
	for _, c := range cmds {
		if c == "" {
			continue
		}
		result = append(result, c)
	}
	return result
}
