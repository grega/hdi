# ═══════════════════════════════════════════════════════════════════════════════
# ── Interactive picker (inline mode) ─────────────────────────────────────────
# ═══════════════════════════════════════════════════════════════════════════════
#
# Draws inline below the cursor. On each redraw, moves up by the exact
# number of lines previously drawn, then clears downward. On quit,
# clears the picker area entirely so the terminal is left clean.

PICKER_LINES=0  # tracks how many lines the last draw_picker call printed
FLASH_MSG=""    # one-shot message shown in footer, cleared on next draw

draw_picker() {
  local selected="$1"

  # If we've drawn before, erase the previous output
  if (( PICKER_LINES > 0 )); then
    # Move up PICKER_LINES, then clear from cursor to end of screen
    printf '\033[%dA\033[J' "$PICKER_LINES"
  fi

  local count=0

  # Header
  printf "%s%s[hdi] %s%s" "$BOLD" "$YELLOW" "$PROJECT_NAME" "$RESET"
  case "$MODE" in
    install) printf "  %s[install]%s" "$DIM" "$RESET" ;;
    run)     printf "  %s[run]%s" "$DIM" "$RESET" ;;
    test)    printf "  %s[test]%s" "$DIM" "$RESET" ;;
    all)     printf "  %s[all]%s" "$DIM" "$RESET" ;;
  esac
  printf "\n"
  (( count += 1 ))

  for idx in "${!DISPLAY_LINES[@]}"; do
    local line="${DISPLAY_LINES[$idx]}"
    local type="${LINE_TYPES[$idx]}"

    case "$type" in
      header)
        printf "\n%s%s ▸ %s%s\n" "$BOLD" "$CYAN" "$line" "$RESET"
        (( count += 2 ))
        ;;
      subheader)
        printf "\n  %s%s%s%s\n" "$BOLD" "$MAGENTA" "$line" "$RESET"
        (( count += 2 ))
        ;;
      command)
        if (( idx == selected )) && [[ -n "$FLASH_MSG" ]]; then
          printf "  %s%s✔ %s %s\n" "$BG_SELECT" "$GREEN$BOLD" "$line" "$RESET"
        elif (( idx == selected )); then
          printf "  %s%s▶ %s %s\n" "$BG_SELECT" "$WHITE$BOLD" "$line" "$RESET"
        else
          printf "  %s  %s%s\n" "$GREEN" "$line" "$RESET"
        fi
        (( count += 1 ))
        ;;
      empty)
        if [[ -n "$line" ]]; then
          printf "  %s  %s%s\n" "$DIM" "$line" "$RESET"
        else
          printf "\n"
        fi
        (( count += 1 ))
        ;;
    esac
  done

  # Footer
  if [[ -n "$FLASH_MSG" ]]; then
    printf "\n%s  %s%s\n" "$DIM" "$FLASH_MSG" "$RESET"
  else
    printf "\n%s  ↑↓ navigate  ⇥ sections  ⏎ execute  c copy  q quit%s\n" "$DIM" "$RESET"
  fi
  (( count += 2 ))  # blank line + footer line

  PICKER_LINES=$count
}

# Erase the picker from the terminal
clear_picker() {
  if (( PICKER_LINES > 0 )); then
    printf '\033[%dA\033[J' "$PICKER_LINES"
    PICKER_LINES=0
  fi
}

run_interactive() {
  local num_cmds=${#CMD_INDICES[@]}

  if (( num_cmds == 0 )); then
    echo "${YELLOW}hdi: no commands to pick from${RESET}" >&2
    echo "${DIM}Try: hdi all --full${RESET}" >&2
    exit 1
  fi

  local cursor=0
  local selected="${CMD_INDICES[$cursor]}"

# Save terminal state (global so cleanup trap can access after function returns)
  SAVED_TTY=$(stty -g)

  cleanup() {
    stty "$SAVED_TTY" 2>/dev/null
    printf '%s' "$SHOW_CURSOR"
    # Clear any remaining picker output
    if (( PICKER_LINES > 0 )); then
      printf '\033[%dA\033[J' "$PICKER_LINES"
    fi
  }
  
  trap cleanup EXIT TERM

  printf '%s' "$HIDE_CURSOR"
  draw_picker "$selected"

  # ── Read a single raw byte from the terminal ──────────────────────────────
  read_byte() {
    dd bs=1 count=1 2>/dev/null < /dev/tty
  }

  # ── Read a single keypress, resolving escape sequences ────────────────────
  KEY=""
  read_key() {
    stty raw -echo < /dev/tty

    local byte
    byte=$(read_byte)

    if [[ "$byte" == $'\x1b' ]]; then
      local byte2
      stty raw -echo min 0 time 3 < /dev/tty
      byte2=$(read_byte)

      if [[ "$byte2" == "[" ]]; then
        stty raw -echo min 1 time 0 < /dev/tty
        local byte3
        byte3=$(read_byte)
        case "$byte3" in
          A) KEY="up" ;;
          B) KEY="down" ;;
          C) KEY="right" ;;
          D) KEY="left" ;;
          Z) KEY="shift-tab" ;;
          *) KEY="" ;;
        esac
      elif [[ -z "$byte2" ]]; then
        KEY="esc"
      else
        KEY=""
      fi
    elif [[ "$byte" == "" ]] || [[ "$byte" == $'\n' ]] || [[ "$byte" == $'\r' ]]; then
      KEY="enter"
    elif [[ "$byte" == $'\t' ]]; then
      KEY="tab"
    elif [[ "$byte" == $'\x03' ]]; then
      KEY="ctrl-c"
    else
      KEY="$byte"
    fi

    stty "$SAVED_TTY" 2>/dev/null
  }

  while true; do
    read_key

    case "$KEY" in
      up|k)
        if (( cursor > 0 )); then
          (( cursor -= 1 ))
          selected="${CMD_INDICES[$cursor]}"
        fi
        ;;

      down|j)
        if (( cursor < num_cmds - 1 )); then
          (( cursor += 1 ))
          selected="${CMD_INDICES[$cursor]}"
        fi
        ;;

      tab|right)
        for _sf in "${SECTION_FIRST_CMD[@]}"; do
          if (( _sf > cursor )); then
            cursor=$_sf
            selected="${CMD_INDICES[$cursor]}"
            break
          fi
        done
        ;;

      shift-tab|left)
        local _prev=-1
        for _sf in "${SECTION_FIRST_CMD[@]}"; do
          (( _sf >= cursor )) && break
          _prev=$_sf
        done
        if (( _prev >= 0 )); then
          cursor=$_prev
          selected="${CMD_INDICES[$cursor]}"
        fi
        ;;

      enter)
        local cmd="${LINE_CMDS[$selected]}"

        # Clear picker, show cursor, restore tty
        clear_picker
        printf '%s' "$SHOW_CURSOR"
        stty "$SAVED_TTY" 2>/dev/null

        printf "%s%s❯ %s%s\n\n" "$BOLD" "$GREEN" "$cmd" "$RESET"

        eval "$cmd"
        local rc=$?

        echo ""
        if (( rc == 0 )); then
          printf "%s%s✓ Done (exit %d)%s\n" "$DIM" "$GREEN" "$rc" "$RESET"
        else
          printf "%s%s✗ Exited with code %d%s\n" "$BOLD" "$YELLOW" "$rc" "$RESET"
        fi
        printf "%s  Press any key to return to picker, q to quit%s\n" "$DIM" "$RESET"

        stty raw -echo < /dev/tty
        local resume
        resume=$(read_byte)
        stty "$SAVED_TTY" 2>/dev/null

        if [[ "$resume" == "q" ]]; then
          # Disable cleanup's clear since we're already clean
          PICKER_LINES=0
          return 0
        elif [[ "$resume" == $'\x03' ]]; then
          # Disable cleanup's clear since we're already clean
          PICKER_LINES=0
          exit 130
        fi

        printf '%s' "$HIDE_CURSOR"
        # Draw fresh (PICKER_LINES is 0 so it won't try to erase)
        ;;

      c)
        local cmd="${LINE_CMDS[$selected]}"
        if command -v pbcopy >/dev/null 2>&1; then
          printf '%s' "$cmd" | pbcopy
        elif command -v wl-copy >/dev/null 2>&1; then
          printf '%s' "$cmd" | wl-copy
        elif command -v xclip >/dev/null 2>&1; then
          printf '%s' "$cmd" | xclip -selection clipboard
        elif command -v xsel >/dev/null 2>&1; then
          printf '%s' "$cmd" | xsel --clipboard
        fi
        FLASH_MSG="✔ Copied: $cmd"
        ;;

      esc|q)
        clear_picker
        PICKER_LINES=0
        return
        ;;

      ctrl-c)
        clear_picker
        PICKER_LINES=0
        exit 130
        ;;
    esac

    draw_picker "$selected"
    FLASH_MSG=""
  done
}
