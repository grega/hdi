package display

// LineType represents the type of a display list entry.
type LineType int

const (
	LineHeader    LineType = iota // Section heading
	LineSubheader                // Sub-section heading
	LineCommand                  // Executable command
	LineEmpty                    // Empty placeholder or separator
	LineFileSep                  // File separator (multiple source files)
)

// String returns the JSON-compatible type name.
func (lt LineType) String() string {
	switch lt {
	case LineHeader:
		return "header"
	case LineSubheader:
		return "subheader"
	case LineCommand:
		return "command"
	case LineEmpty:
		return "empty"
	case LineFileSep:
		return "filesep"
	default:
		return "unknown"
	}
}

// DisplayLine is a single entry in the flat display list.
type DisplayLine struct {
	Text    string   // What to display
	Type    LineType // Entry type
	Command string   // Raw command (only for LineCommand)
}

// DisplayList holds the flattened display structure for rendering.
type DisplayList struct {
	Lines           []DisplayLine
	CmdIndices      []int // Indices into Lines that are commands
	SectionFirstCmd []int // Cursor indices (into CmdIndices) of first cmd per section
	FileFirstCmd    []int // Cursor indices of first cmd after each file separator
	MaxContentWidth int   // Longest command width (for layout)
}
