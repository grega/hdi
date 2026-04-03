package display

import (
	"path/filepath"
	"strings"

	"github.com/grega/hdi/internal/markdown"
)

// BuildDisplayList constructs a flat display list from parsed sections.
func BuildDisplayList(sections []markdown.Section) *DisplayList {
	dl := &DisplayList{}
	prevSource := ""
	fileRecorded := true // true initially so we don't record first file

	for _, sec := range sections {
		// File separator when source file changes
		if prevSource != "" && sec.Source != "" && sec.Source != prevSource {
			dl.Lines = append(dl.Lines, DisplayLine{
				Text: filepath.Base(sec.Source),
				Type: LineFileSep,
			})
			fileRecorded = false
		}
		prevSource = sec.Source

		// Section header
		dl.Lines = append(dl.Lines, DisplayLine{
			Text: sec.Title,
			Type: LineHeader,
		})

		hasCmds := false
		sectionRecorded := false

		// Extract commands from backtick-wrapped text in the heading itself
		titleCmds := markdown.FindBacktickCommands(sec.Title, false)
		for _, tcmd := range titleCmds {
			if tcmd == "" {
				continue
			}
			hasCmds = true
			cmdIdx := len(dl.Lines)
			dl.CmdIndices = append(dl.CmdIndices, cmdIdx)
			if !sectionRecorded {
				dl.SectionFirstCmd = append(dl.SectionFirstCmd, len(dl.CmdIndices)-1)
				sectionRecorded = true
			}
			if !fileRecorded {
				dl.FileFirstCmd = append(dl.FileFirstCmd, len(dl.CmdIndices)-1)
				fileRecorded = true
			}
			dl.Lines = append(dl.Lines, DisplayLine{
				Text:    tcmd,
				Type:    LineCommand,
				Command: tcmd,
			})
			if len(tcmd)+4 > dl.MaxContentWidth {
				dl.MaxContentWidth = len(tcmd) + 4
			}
		}

		// Extract commands with sub-group markers
		cmds := markdown.ExtractCommands(sec.Body, true)

		// Deduplicate commands within each sub-group
		cmds = deduplicatePerGroup(cmds)

		// Build display entries from the flat command list with markers
		pendingLabel := ""
		for _, entry := range cmds {
			if entry == "" {
				continue
			}
			if strings.HasPrefix(entry, markdown.SubHeaderMarker) {
				pendingLabel = entry[len(markdown.SubHeaderMarker):]
				continue
			}
			// Emit the sub-header only when its group has commands
			if pendingLabel != "" {
				dl.Lines = append(dl.Lines, DisplayLine{
					Text: pendingLabel,
					Type: LineSubheader,
				})
				pendingLabel = ""
			}
			hasCmds = true
			cmdIdx := len(dl.Lines)
			dl.CmdIndices = append(dl.CmdIndices, cmdIdx)
			if !sectionRecorded {
				dl.SectionFirstCmd = append(dl.SectionFirstCmd, len(dl.CmdIndices)-1)
				sectionRecorded = true
			}
			if !fileRecorded {
				dl.FileFirstCmd = append(dl.FileFirstCmd, len(dl.CmdIndices)-1)
				fileRecorded = true
			}
			dl.Lines = append(dl.Lines, DisplayLine{
				Text:    entry,
				Type:    LineCommand,
				Command: entry,
			})
			if len(entry)+4 > dl.MaxContentWidth {
				dl.MaxContentWidth = len(entry) + 4
			}
		}

		if !hasCmds {
			dl.Lines = append(dl.Lines, DisplayLine{
				Text: "(no commands - use --full to see prose)",
				Type: LineEmpty,
			})
		}

		// Blank separator
		dl.Lines = append(dl.Lines, DisplayLine{
			Text: "",
			Type: LineEmpty,
		})
	}

	return dl
}

// deduplicatePerGroup removes duplicate commands within each sub-group.
// Sub-header markers reset the seen set.
func deduplicatePerGroup(cmds []string) []string {
	var result []string
	seen := make(map[string]bool)

	for _, cmd := range cmds {
		if cmd == "" {
			continue
		}
		// Sub-header marker - reset per-group seen list
		if strings.HasPrefix(cmd, markdown.SubHeaderMarker) {
			result = append(result, cmd)
			seen = make(map[string]bool)
			continue
		}
		if !seen[cmd] {
			result = append(result, cmd)
			seen[cmd] = true
		}
	}
	return result
}
