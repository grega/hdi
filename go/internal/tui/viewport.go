package tui

import "github.com/grega/hdi/internal/display"

// screenLines returns the number of terminal lines needed for a display entry.
// Headers and subheaders need 2 (blank + text), file separators need 3.
func screenLines(lt display.LineType) int {
	switch lt {
	case display.LineFileSep:
		return 3
	case display.LineHeader, display.LineSubheader:
		return 2
	default:
		return 1
	}
}

// adjustViewport calculates the viewport top position so the selected item is visible.
func adjustViewport(dl *display.DisplayList, selected int, viewportTop int, termHeight int) int {
	if termHeight < 5 {
		termHeight = 5
	}

	chrome := 3 // header(1) + footer gap(1) + footer(1)
	nItems := len(dl.Lines)

	// Check if everything fits without scrolling
	// First header/subheader at viewport top has blank line suppressed
	total := 0
	for i := 0; i < nItems; i++ {
		total += screenLines(dl.Lines[i].Type)
	}
	if nItems > 0 {
		switch dl.Lines[0].Type {
		case display.LineHeader, display.LineSubheader, display.LineFileSep:
			total--
		}
	}
	if total+chrome <= termHeight {
		return 0
	}

	// If selected is at or above viewport top, include section context
	if selected <= viewportTop {
		viewportTop = selected
		// Walk back through consecutive headers/subheaders/fileseps
		for viewportTop > 0 {
			prevType := dl.Lines[viewportTop-1].Type
			if prevType == display.LineHeader || prevType == display.LineSubheader || prevType == display.LineFileSep {
				viewportTop--
			} else {
				break
			}
		}
	}

	// Account for scroll indicators in available space
	aboveCost := 0
	if viewportTop > 0 {
		for idx := 0; idx < viewportTop; idx++ {
			if dl.Lines[idx].Type != display.LineEmpty {
				aboveCost = 1
				break
			}
		}
	}
	avail := termHeight - chrome - aboveCost

	// Check if selected is below the visible area
	row := 0
	for idx := viewportTop; idx < nItems; idx++ {
		lines := screenLines(dl.Lines[idx].Type)
		if idx == viewportTop {
			switch dl.Lines[idx].Type {
			case display.LineHeader, display.LineSubheader, display.LineFileSep:
				lines--
			}
		}
		if idx == selected {
			if row+lines > avail {
				break
			}
			return viewportTop // fits
		}
		row += lines
	}

	// Scroll down: work backwards from selected to find new viewport top
	budget := termHeight - chrome - 1 // -1 for "more above" indicator

	// Reserve 1 for "more below" if meaningful content exists after selected
	hasAfter := false
	for idx := selected + 1; idx < nItems; idx++ {
		if dl.Lines[idx].Type != display.LineEmpty {
			hasAfter = true
			break
		}
	}
	if hasAfter {
		budget--
	}

	used := screenLines(dl.Lines[selected].Type)
	newTop := selected

	for idx := selected - 1; idx >= 0; idx-- {
		lines := screenLines(dl.Lines[idx].Type)
		if used+lines > budget {
			// Check if suppression at viewport top saves enough
			saving := 0
			switch dl.Lines[idx].Type {
			case display.LineHeader, display.LineSubheader, display.LineFileSep:
				saving = 1
			}
			if idx == 0 {
				saving++
			}
			if saving > 0 && used+lines-saving <= budget {
				used += lines - saving
				newTop = idx
			}
			break
		}
		used += lines
		newTop = idx
	}

	return newTop
}
