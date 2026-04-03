package markdown

import (
	"strings"
	"testing"
)

func TestExtractFencedCommands(t *testing.T) {
	body := "```bash\nnpm install\nnpm start\n```\n"
	cmds := CleanCommands(ExtractCommands(body, false))
	if len(cmds) != 2 {
		t.Fatalf("expected 2 commands, got %d: %v", len(cmds), cmds)
	}
	if cmds[0] != "npm install" {
		t.Errorf("expected 'npm install', got %q", cmds[0])
	}
	if cmds[1] != "npm start" {
		t.Errorf("expected 'npm start', got %q", cmds[1])
	}
}

func TestSkipJSONBlock(t *testing.T) {
	body := "```json\n{\"key\": \"value\"}\n```\n\n```bash\nnpm install\n```\n"
	cmds := CleanCommands(ExtractCommands(body, false))
	if len(cmds) != 1 {
		t.Fatalf("expected 1 command, got %d: %v", len(cmds), cmds)
	}
	if cmds[0] != "npm install" {
		t.Errorf("expected 'npm install', got %q", cmds[0])
	}
}

func TestSkipYAMLBlock(t *testing.T) {
	body := "```yaml\nkey: value\n```\n\n```bash\nmake build\n```\n"
	cmds := CleanCommands(ExtractCommands(body, false))
	if len(cmds) != 1 {
		t.Fatalf("expected 1 command, got %d: %v", len(cmds), cmds)
	}
}

func TestConsoleMode(t *testing.T) {
	body := "```console\n$ npm install\ninstalling...\ndone\n$ npm start\n```\n"
	cmds := CleanCommands(ExtractCommands(body, false))
	if len(cmds) != 2 {
		t.Fatalf("expected 2 commands, got %d: %v", len(cmds), cmds)
	}
	if cmds[0] != "npm install" {
		t.Errorf("expected 'npm install', got %q", cmds[0])
	}
	if cmds[1] != "npm start" {
		t.Errorf("expected 'npm start', got %q", cmds[1])
	}
}

func TestPromptStripping(t *testing.T) {
	body := "```bash\n$ npm install\n% npm start\n```\n"
	cmds := CleanCommands(ExtractCommands(body, false))
	if len(cmds) != 2 {
		t.Fatalf("expected 2 commands, got %d: %v", len(cmds), cmds)
	}
	if cmds[0] != "npm install" {
		t.Errorf("expected 'npm install', got %q", cmds[0])
	}
	if cmds[1] != "npm start" {
		t.Errorf("expected 'npm start', got %q", cmds[1])
	}
}

func TestDollarVarNotMangled(t *testing.T) {
	body := "```bash\nexport PATH=$HOME/bin:$PATH\n```\n"
	cmds := CleanCommands(ExtractCommands(body, false))
	if len(cmds) != 1 {
		t.Fatalf("expected 1 command, got %d: %v", len(cmds), cmds)
	}
	if cmds[0] != "export PATH=$HOME/bin:$PATH" {
		t.Errorf("expected dollar var preserved, got %q", cmds[0])
	}
}

func TestLineContinuation(t *testing.T) {
	body := "```bash\ndocker build \\\n  -t myapp \\\n  .\n```\n"
	cmds := CleanCommands(ExtractCommands(body, false))
	if len(cmds) != 1 {
		t.Fatalf("expected 1 command, got %d: %v", len(cmds), cmds)
	}
	if !strings.Contains(cmds[0], "docker build") || !strings.Contains(cmds[0], "-t myapp") {
		t.Errorf("expected continuation to be joined, got %q", cmds[0])
	}
}

func TestInlineBacktickCommands(t *testing.T) {
	body := "Run `npm install` to install deps and `npm start` to start.\n"
	cmds := CleanCommands(ExtractCommands(body, false))
	if len(cmds) != 2 {
		t.Fatalf("expected 2 commands, got %d: %v", len(cmds), cmds)
	}
}

func TestFindBacktickCommandsRequireArgs(t *testing.T) {
	cmds := FindBacktickCommands("Use `npm install` and `Jest` for testing", true)
	if len(cmds) != 1 {
		t.Fatalf("expected 1 command, got %d: %v", len(cmds), cmds)
	}
	if cmds[0] != "npm install" {
		t.Errorf("expected 'npm install', got %q", cmds[0])
	}
}

func TestFindBacktickCommandsBarePrefix(t *testing.T) {
	cmds := FindBacktickCommands("### `make`", false)
	if len(cmds) != 1 {
		t.Fatalf("expected 1 command, got %d: %v", len(cmds), cmds)
	}
	if cmds[0] != "make" {
		t.Errorf("expected 'make', got %q", cmds[0])
	}
}

func TestSubHeaderMarkers(t *testing.T) {
	body := "### Development\n\n```bash\nnpm run dev\n```\n\n### Production\n\n```bash\nnpm run build\n```\n"
	cmds := ExtractCommands(body, true)
	clean := CleanCommands(cmds)

	hasDevMarker := false
	hasProdMarker := false
	for _, c := range clean {
		if c == SubHeaderMarker+"Development" {
			hasDevMarker = true
		}
		if c == SubHeaderMarker+"Production" {
			hasProdMarker = true
		}
	}
	if !hasDevMarker {
		t.Error("expected Development sub-header marker")
	}
	if !hasProdMarker {
		t.Error("expected Production sub-header marker")
	}
}

func TestIndentedCodeBlock(t *testing.T) {
	body := "Install with:\n\n    npm install\n    npm run build\n\nThen run it.\n"
	cmds := CleanCommands(ExtractCommands(body, false))
	if len(cmds) != 2 {
		t.Fatalf("expected 2 commands, got %d: %v", len(cmds), cmds)
	}
}

func TestIndentedCodeBlockNonCommand(t *testing.T) {
	// Indented block that doesn't look like a command should be skipped
	body := "Example output:\n\n    some random output\n    more output\n\nDone.\n"
	cmds := CleanCommands(ExtractCommands(body, false))
	if len(cmds) != 0 {
		t.Fatalf("expected 0 commands, got %d: %v", len(cmds), cmds)
	}
}

func TestTildeFence(t *testing.T) {
	body := "~~~bash\nmake build\n~~~\n"
	cmds := CleanCommands(ExtractCommands(body, false))
	if len(cmds) != 1 {
		t.Fatalf("expected 1 command, got %d: %v", len(cmds), cmds)
	}
	if cmds[0] != "make build" {
		t.Errorf("expected 'make build', got %q", cmds[0])
	}
}

func TestMixedFencesDontClose(t *testing.T) {
	// Tilde fence should not be closed by backtick fence
	body := "~~~bash\nnpm install\n```\nnpm start\n~~~\n"
	cmds := CleanCommands(ExtractCommands(body, false))
	// npm install and npm start should both be inside the tilde fence
	// The ``` line is treated as content (stripped to empty by TrimLeft)
	if len(cmds) != 2 {
		t.Fatalf("expected 2 commands, got %d: %v", len(cmds), cmds)
	}
}

func TestStripPrompt(t *testing.T) {
	tests := []struct {
		input, want string
	}{
		{"$ npm install", "npm install"},
		{"% npm install", "npm install"},
		{"  $ npm install", "npm install"},
		{"$HOME/bin", "$HOME/bin"},
		{"npm install", "npm install"},
	}
	for _, tt := range tests {
		got := StripPrompt(tt.input)
		if got != tt.want {
			t.Errorf("StripPrompt(%q) = %q, want %q", tt.input, got, tt.want)
		}
	}
}

func TestUnlabeledCodeBlock(t *testing.T) {
	body := "```\nnpm install\n```\n"
	cmds := CleanCommands(ExtractCommands(body, false))
	if len(cmds) != 1 {
		t.Fatalf("expected 1 command, got %d: %v", len(cmds), cmds)
	}
}
