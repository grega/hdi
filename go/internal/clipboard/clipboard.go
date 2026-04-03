package clipboard

import (
	"os/exec"
	"strings"
)

// Copy copies text to the system clipboard.
// Tries pbcopy (macOS), wl-copy (Wayland), xclip, xsel in order.
func Copy(text string) error {
	cmds := []struct {
		name string
		args []string
	}{
		{"pbcopy", nil},
		{"wl-copy", nil},
		{"xclip", []string{"-selection", "clipboard"}},
		{"xsel", []string{"--clipboard"}},
	}

	for _, c := range cmds {
		if _, err := exec.LookPath(c.name); err != nil {
			continue
		}
		cmd := exec.Command(c.name, c.args...)
		cmd.Stdin = strings.NewReader(text)
		return cmd.Run()
	}
	return nil // silently fail if no clipboard tool available
}
