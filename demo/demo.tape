# VHS demo tape for hdi
# Run: vhs demo.tape
# Requires: brew install vhs

Output ./demo/demo.gif

Set Shell "bash"
Set FontSize 18
Set Width 800
Set Height 500
Set Padding 20
Set TypingSpeed 60ms
Set Theme "Catppuccin Mocha"

# ── Setup (hidden) ──────────────────────────────────────────────────────────

Hide
Type "export PATH=$PWD/demo/sinatra-app/bin:$PATH" Enter
Type "clear" Enter
Sleep 300ms
Type "cd demo/sinatra-app" Enter
Sleep 300ms
Show

# ── Scene 1: Main interactive picker ────────────────────────────────────────

Type "hdi"
Sleep 300ms
Enter
Sleep 2.5s

# Navigate down through commands
Down
Sleep 500ms
Down
Sleep 500ms
Down
Sleep 500ms

# Navigate back up
Up
Sleep 500ms
Up
Sleep 1.5s

# Cursor is now on "bundle install" — execute it
Enter
Sleep 2.5s

# Quit after execution
Type "q"
Sleep 2s

Hide
Type "clear" Enter
Show

# ── Scene 2: Install mode ──────────────────────────────────────────────────

Type "hdi i"
Sleep 200ms
Enter
Sleep 2s

Type "q"
Sleep 1.5s

# ── Scene 3: Run mode ──────────────────────────────────────────────────────

Type "hdi r"
Sleep 200ms
Enter
Sleep 2s

Type "q"
Sleep 1.5s

# ── Scene 4: Test mode ─────────────────────────────────────────────────────

Type "hdi t"
Sleep 200ms
Enter
Sleep 2s

Type "q"
Sleep 2s
