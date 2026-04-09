package tui

import "github.com/charmbracelet/lipgloss"

// Color palette — Catppuccin Latte (light) / Mocha (dark).
// https://catppuccin.com/palette
//
//   Role map:
//     Green .... commands (the bulk of content)
//     Mauve .... accent — selection border, brand, filter prompt
//     Peach .... section headers (warm structural dividers)
//     Pink ..... sub-headers
//     Yellow ... title
//     Blue ..... filter chrome, platform tags, category tags
//     Teal ..... file separators
//
var (
	// Accent: Mauve — selection border, filter prompt, active pagination dot
	colorAccent = lipgloss.AdaptiveColor{Light: "#8839EF", Dark: "#CBA6F7"}

	// Commands: Green — readable at volume
	colorCmd = lipgloss.AdaptiveColor{Light: "#40A02B", Dark: "#A6E3A1"}

	// Section headers: Peach — warm structural dividers
	colorSection = lipgloss.AdaptiveColor{Light: "#FE640B", Dark: "#FAB387"}

	// Sub-headers: Pink
	colorSubHeader = lipgloss.AdaptiveColor{Light: "#EA76CB", Dark: "#F5C2E7"}

	// Header/title: Yellow
	colorTitle = lipgloss.AdaptiveColor{Light: "#DF8E1D", Dark: "#F9E2AF"}

	// Success: Green
	colorSuccess = lipgloss.AdaptiveColor{Light: "#40A02B", Dark: "#A6E3A1"}

	// Error/warning: Red
	colorError = lipgloss.AdaptiveColor{Light: "#D20F39", Dark: "#F38BA8"}

	// File separators: Teal — distinct from blue tags and peach headers
	colorFileSep = lipgloss.AdaptiveColor{Light: "#179299", Dark: "#94E2D5"}

	// Filter/interactive chrome: Blue
	colorPlatform = lipgloss.AdaptiveColor{Light: "#1E66F5", Dark: "#89B4FA"}

	// Selection background: Surface0 (Latte) / Surface0 (Mocha)
	colorSelBg = lipgloss.AdaptiveColor{Light: "#CCD0DA", Dark: "#313244"}

	// Muted/dim text: Overlay0
	colorDim = lipgloss.AdaptiveColor{Light: "#9CA0B0", Dark: "#6C7086"}

	// Bright foreground for selected items: Text
	colorSelFg = lipgloss.AdaptiveColor{Light: "#4C4F69", Dark: "#CDD6F4"}

	// Section header dash lines: Surface2
	colorSectionDash = lipgloss.AdaptiveColor{Light: "#ACB0BE", Dark: "#585B70"}
)
