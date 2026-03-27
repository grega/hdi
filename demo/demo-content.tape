# Shared demo steps for hdi
# This file is sourced by theme-specific tapes
# Uses the `../hdi` build through $PWD below (ie. not `hdi` installed via Homebrew) so that the demo always shows the latest version of hdi

Set Shell "bash"
Set FontSize 36
Set Width 1600
Set Height 1000
Set Padding 40
Set TypingSpeed 60ms

# ── Setup (hidden) ──────────────────────────────────────────────────────────

Hide
Type "export PATH=$PWD:$PWD/demo/sinatra-app/bin:$PATH" Enter
Type "clear" Enter
Sleep 300ms
Type "cd demo/sinatra-app" Enter
Sleep 300ms
Show

# ── Scene 1: Main interactive picker ────────────────────────────────────────

Type "hdi"
Sleep 1s
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

# Copy the command to clipboard
Type "c"
Sleep 2.5s

Up
Sleep 2.5s

# Cursor is now on "bundle install" - execute it
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
Sleep 1.5s

# ── Scene 5: Check mode ─────────────────────────────────────────────────────

Type "hdi c"
Sleep 200ms
Enter
Sleep 3s
Type "q"
Sleep 1.5s
