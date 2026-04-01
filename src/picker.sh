# ═══════════════════════════════════════════════════════════════════════════════
# ── Interactive picker (inline mode) ─────────────────────────────────────────
# ═══════════════════════════════════════════════════════════════════════════════
#
# Draws inline below the cursor with a scrolling viewport. Only the lines
# that fit within the terminal height are rendered. Output is buffered and
# emitted in a single write to avoid flicker. On quit, clears the picker
# area entirely so the terminal is left clean.

PICKER_LINES=0   # tracks how many lines the last draw_picker call printed
FLASH_MSG=""     # one-shot message shown in footer, cleared on next draw
VIEWPORT_TOP=0  # first DISPLAY_LINES index visible in the viewport

# Get terminal height reliably (stty from tty, fallback to tput, then 24)
_term_height() {
  local h
  h=$(stty size < /dev/tty 2>/dev/null) && h="${h%% *}" && (( h > 0 )) && { echo "$h"; return; }
  h=$(tput lines 2>/dev/null) && (( h > 0 )) && { echo "$h"; return; }
  echo 24
}

# Get terminal width reliably (COLUMNS, stty from tty, fallback to tput, then 80)
_term_width() {
  if (( ${COLUMNS:-0} > 0 )); then echo "$COLUMNS"; return; fi
  local w
  w=$(stty size < /dev/tty 2>/dev/null) && w="${w##* }" && (( w > 0 )) && { echo "$w"; return; }
  w=$(tput cols 2>/dev/null) && (( w > 0 )) && { echo "$w"; return; }
  echo 80
}

# Pre-computed dash strings (200 chars covers any reasonable terminal width)
_DASH_POOL="────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
_DOUBLE_DASH_POOL="════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════"

# Format a section header with trailing dashes (sets _SH, no subshell)
# _RENDER_WIDTH defaults to _MAX_CONTENT_WIDTH; draw_picker caps it to terminal width
_SH=""
_RENDER_WIDTH=0
_section_header() {
  (( _RENDER_WIDTH == 0 )) && _RENDER_WIDTH=$_MAX_CONTENT_WIDTH
  local prefix=" ▸ $1 "
  local prefix_len=${#prefix}
  local target=$(( _RENDER_WIDTH > prefix_len ? _RENDER_WIDTH : prefix_len + 4 ))
  local n=$(( target - prefix_len ))
  (( n < 2 )) && n=2
  _SH="${BOLD}${CYAN}${prefix}${RESET}${DIM}${_DASH_POOL:0:n}${RESET}"
}

# Format a file separator with double-line dashes (sets _FS, no subshell)
_FS=""
_file_separator() {
  (( _RENDER_WIDTH == 0 )) && _RENDER_WIDTH=$_MAX_CONTENT_WIDTH
  local prefix="  ══ $1 "
  local prefix_len=${#prefix}
  local target=$(( _RENDER_WIDTH > prefix_len ? _RENDER_WIDTH : prefix_len + 4 ))
  local n=$(( target - prefix_len ))
  (( n < 2 )) && n=2
  _FS="${DIM}  ══ ${RESET}${BOLD}${YELLOW}$1${RESET}${DIM} ${_DOUBLE_DASH_POOL:0:n}${RESET}"
}

# Screen lines per display entry type — sets _SL (no subshell)
# Headers/subheaders take 2 lines (blank + text), others take 1
_SL=1
_sl() {
  case "${LINE_TYPES[$1]}" in filesep) _SL=3 ;; header|subheader) _SL=2 ;; *) _SL=1 ;; esac
}

# Adjust VIEWPORT_TOP so that the selected item is visible
adjust_viewport() {
  local selected="$1"
  local term_h
  term_h=$(_term_height)
  (( term_h < 5 )) && term_h=5

  local chrome=3  # header(1) + footer gap(1) + footer(1)
  local n_items=${#DISPLAY_LINES[@]}

  # Check if everything fits without scrolling
  # Note: the first header/subheader at viewport_top has its blank line
  # suppressed in draw_picker, so it costs 1 line instead of 2
  local total=0
  for (( _i = 0; _i < n_items; _i++ )); do
    _sl "$_i"; (( total += _SL ))
  done
  case "${LINE_TYPES[0]}" in header|subheader|filesep) (( total -= 1 )) ;; esac
  if (( total + chrome <= term_h )); then
    VIEWPORT_TOP=0
    return
  fi

  # If selected is at or above viewport top, try to include section context
  if (( selected <= VIEWPORT_TOP )); then
    VIEWPORT_TOP=$selected
    # Walk back through consecutive headers/subheaders to show full context
    while (( VIEWPORT_TOP > 0 )); do
      local prev_type="${LINE_TYPES[$((VIEWPORT_TOP - 1))]}"
      if [[ "$prev_type" == "header" || "$prev_type" == "subheader" || "$prev_type" == "filesep" ]]; then
        (( VIEWPORT_TOP -= 1 ))
      else
        break
      fi
    done
  fi

  # Account for scroll indicators in available space (after possible VIEWPORT_TOP change)
  local above_cost=0
  if (( VIEWPORT_TOP > 0 )); then
    for (( idx = 0; idx < VIEWPORT_TOP; idx++ )); do
      [[ "${LINE_TYPES[$idx]}" != "empty" ]] && above_cost=1 && break
    done
  fi
  local avail=$(( term_h - chrome - above_cost ))

  # Check if selected is below the visible area
  local row=0 lines
  for (( idx = VIEWPORT_TOP; idx < n_items; idx++ )); do
    _sl "$idx"; lines=$_SL
    # First item at viewport_top has blank line suppressed in draw_picker
    if (( idx == VIEWPORT_TOP )); then
      case "${LINE_TYPES[$idx]}" in header|subheader|filesep) (( lines -= 1 )) ;; esac
    fi
    if (( idx == selected )); then
      if (( row + lines > avail )); then break; fi
      return  # It fits
    fi
    (( row += lines ))
  done

  # Scroll down: work backwards from selected to find new viewport_top
  local budget=$(( term_h - chrome - 1 ))  # -1 for "more above" indicator
  # Reserve 1 for "more below" if meaningful content exists after selected
  local has_after=false
  for (( idx = selected + 1; idx < n_items; idx++ )); do
    [[ "${LINE_TYPES[$idx]}" != "empty" ]] && has_after=true && break
  done
  $has_after && (( budget -= 1 ))

  _sl "$selected"; local used=$_SL
  local new_top=$selected
  for (( idx = selected - 1; idx >= 0; idx-- )); do
    _sl "$idx"; lines=$_SL
    if (( used + lines > budget )); then
      # If this item would be at viewport top, its blank line is suppressed —
      # try again with 1 fewer line.  Also, reaching idx==0 removes the
      # "more above" indicator, freeing 1 more line of budget
      local saving=0
      case "${LINE_TYPES[$idx]}" in header|subheader|filesep) saving=1 ;; esac
      (( idx == 0 )) && (( saving += 1 ))
      if (( saving > 0 && used + lines - saving <= budget )); then
        (( used += lines - saving ))
        new_top=$idx
      fi
      break
    fi
    (( used += lines ))
    new_top=$idx
  done
  VIEWPORT_TOP=$new_top
}

draw_picker() {
  local selected="$1"
  local EL=$'\033[K'  # erase to end of line

  # Move to top of previous output (but don't clear — we overwrite in place)
  # Cursor sits on the last line (no trailing \n), so move up count-1 lines
  if (( PICKER_LINES > 0 )); then
    printf '\033[%dA\r' "$((PICKER_LINES - 1))"
  fi

  local term_h term_w
  term_h=$(_term_height)
  term_w=$(_term_width)
  (( term_h < 5 )) && term_h=5

  # Cap content width to terminal so dividers and highlights don't wrap
  _RENDER_WIDTH=$(( _MAX_CONTENT_WIDTH < term_w ? _MAX_CONTENT_WIDTH : term_w ))

  local count=0
  local n_items=${#DISPLAY_LINES[@]}
  local buf=""

  # Helper: append a line to buf with end-of-line clear
  _line() { buf+="$1${EL}"$'\n'; (( count += 1 )); }
  # Helper: append a blank line (just clear + newline)
  _blank() { buf+="${EL}"$'\n'; (( count += 1 )); }

  # Header
  local hdr="${BOLD}${YELLOW}[hdi] ${PROJECT_NAME}${RESET}"
  case "$MODE" in
    install) hdr+="  ${DIM}[install]${RESET}" ;;
    run)     hdr+="  ${DIM}[run]${RESET}" ;;
    test)    hdr+="  ${DIM}[test]${RESET}" ;;
    deploy)
      if [[ -n "${_PLATFORM_DISPLAY:-}" ]]; then
        hdr+="  ${DIM}[deploy → ${RESET}${CYAN}${_PLATFORM_DISPLAY}${DIM}]${RESET}"
      else
        hdr+="  ${DIM}[deploy]${RESET}"
      fi
      ;;
    all)     hdr+="  ${DIM}[all]${RESET}" ;;
    contrib) hdr+="  ${DIM}[contrib]${RESET}" ;;
  esac
  _line "$hdr"
  _blank
  local chrome=4

  # Scroll-up indicator (only if meaningful content is above the viewport)
  local has_above=false
  if (( VIEWPORT_TOP > 0 )); then
    for (( _ai = 0; _ai < VIEWPORT_TOP; _ai++ )); do
      [[ "${LINE_TYPES[$_ai]}" != "empty" ]] && has_above=true && break
    done
  fi
  local avail=$(( term_h - chrome ))
  if $has_above; then
    _line "  ${DIM}▲ ···${RESET}"
    (( avail -= 1 ))
  fi

  # Render only entries that fit in the viewport
  local rendered=0 lines_needed
  local has_below=false
  for (( idx = VIEWPORT_TOP; idx < n_items; idx++ )); do
    local line="${DISPLAY_LINES[$idx]}"
    local type="${LINE_TYPES[$idx]}"
    _sl "$idx"; lines_needed=$_SL

    # Always render the selected item — never let the reserve hide it
    # For other items, reserve 1 line for "more below" indicator
    if (( idx != selected )); then
      local reserve=0
      (( idx < n_items - 1 )) && reserve=1
      if (( rendered + lines_needed > avail - reserve )) && (( idx > VIEWPORT_TOP )); then
        has_below=true; break
      fi
    fi
    if (( rendered + lines_needed > avail )) && (( idx > VIEWPORT_TOP )); then
      has_below=true; break
    fi

    case "$type" in
      filesep)
        if (( idx != VIEWPORT_TOP )); then
          _blank; (( rendered += 1 ))
        fi
        _file_separator "$line"; _line "$_FS"
        _blank; (( rendered += 1 ))
        ;;
      header)
        if (( idx != VIEWPORT_TOP )); then
          _blank; (( rendered += 1 ))
        fi
        _section_header "$line"; _line "$_SH"
        (( rendered += 1 ))
        ;;
      subheader)
        if (( idx != VIEWPORT_TOP )); then
          _blank; (( rendered += 1 ))
        fi
        _line "  ${BOLD}${MAGENTA}${line}${RESET}"
        (( rendered += 1 ))
        ;;
      command)
        if (( idx == selected )); then
          local _pad_n=$(( _RENDER_WIDTH - ${#line} - 5 ))
          (( _pad_n < 0 )) && _pad_n=0
          local _pad="${_DASH_POOL:0:_pad_n}"
          _pad="${_pad//?/ }"
          if [[ -n "$FLASH_MSG" ]]; then
            _line "  ${BG_SELECT}${GREEN}${BOLD}✔ ${line} ${_pad}${RESET}"
          else
            _line "  ${BG_SELECT}${WHITE}${BOLD}▶ ${line} ${_pad}${RESET}"
          fi
        else
          _line "  ${GREEN}  ${line}${RESET}"
        fi
        (( rendered += 1 ))
        ;;
      empty)
        if [[ -n "$line" ]]; then
          _line "  ${DIM}  ${line}${RESET}"
        else
          _blank
        fi
        (( rendered += 1 ))
        ;;
    esac
  done

  # Scroll-down indicator (only if meaningful content remains below)
  if $has_below; then
    local _real_below=false
    for (( _bi = idx; _bi < n_items; _bi++ )); do
      [[ "${LINE_TYPES[$_bi]}" != "empty" ]] && _real_below=true && break
    done
    if $_real_below; then
      _line "  ${DIM}▼ ···${RESET}"
    fi
  fi

  # Footer
  _blank
  if [[ -n "$FLASH_MSG" ]]; then
    _line "  ${DIM}${FLASH_MSG}${RESET}"
  else
    local _footer="↑↓ navigate  ⇥ sections"
    (( ${#FILE_FIRST_CMD[@]} > 0 )) && _footer+="  f files"
    _footer+="  ⏎ execute  c copy  q quit"
    _line "  ${DIM}${_footer}${RESET}"
  fi

  # Strip trailing newline so the cursor stays on the last line (no scroll)
  buf="${buf%$'\n'}"

  # Single write: overwrite in place, then clear any leftover lines below
  printf '%s\033[J' "$buf"

  PICKER_LINES=$count
}

# Erase the picker from the terminal
clear_picker() {
  if (( PICKER_LINES > 0 )); then
    printf '\r\033[%dA\033[J' "$((PICKER_LINES - 1))"
    PICKER_LINES=0
  fi
}

run_interactive() {
  local num_cmds=${#CMD_INDICES[@]}

  if (( num_cmds == 0 )); then
    if [[ -n "${_PLATFORM_DISPLAY:-}" ]]; then
      printf "%s%s[hdi] %s%s  %s[deploy → %s%s%s%s]%s\n\n" \
        "$BOLD" "$YELLOW" "$PROJECT_NAME" "$RESET" \
        "$DIM" "$RESET" "$CYAN" "$_PLATFORM_DISPLAY" "$DIM" "$RESET"
    fi
    echo "${YELLOW}hdi: no commands to pick from${RESET}" >&2
    echo "${DIM}Try: hdi all --full${RESET}" >&2
    exit 1
  fi

  local cursor=0
  local selected="${CMD_INDICES[$cursor]}"

  # Benchmark mode: draw one frame without TTY, then exit
  if [[ "${_HDI_BENCH_PICKER:-}" == "1" ]]; then
    _term_height() { echo "${LINES:-24}"; }
    adjust_viewport "$selected"
    draw_picker "$selected"
    return 0
  fi

  # Save terminal state (global so cleanup trap can access after function returns)
  SAVED_TTY=$(stty -g)

  cleanup() {
    stty "$SAVED_TTY" 2>/dev/null
    printf '%s' "$SHOW_CURSOR"
    # Clear any remaining picker output
    if (( PICKER_LINES > 0 )); then
      printf '\r\033[%dA\033[J' "$((PICKER_LINES - 1))"
    fi
  }
  trap cleanup EXIT INT TERM

  printf '%s' "$HIDE_CURSOR"
  adjust_viewport "$selected"
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

      f)
        local _fnext=-1
        for _ff in "${FILE_FIRST_CMD[@]}"; do
          if (( _ff > cursor )); then
            _fnext=$_ff
            break
          fi
        done
        if (( _fnext >= 0 )); then
          cursor=$_fnext
        elif (( ${#FILE_FIRST_CMD[@]} > 0 )); then
          cursor=0
        fi
        selected="${CMD_INDICES[$cursor]}"
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
          printf "%s✓ Done (exit %d)%s\n" "$GREEN" "$rc" "$RESET"
          # Warn about commands that modify the shell environment
          if [[ "$cmd" =~ (^|[;&|]\ *)(source|\.)\  ]] || [[ "$cmd" =~ activate ]]; then
            printf "%s  Tip: environment changes (eg. venv activation) don't persist outside hdi.%s\n" "$DIM" "$RESET"
            printf "%s  You may prefer to run this command directly in your shell instead.%s\n\n" "$DIM" "$RESET"
          fi
        else
          printf "%s%s✗ Exited with code %d%s\n" "$BOLD" "$YELLOW" "$rc" "$RESET"
        fi
        printf "%s  Press any key to return to picker, q to quit%s\n" "$DIM" "$RESET"

        stty raw -echo < /dev/tty
        local resume
        resume=$(read_byte)
        stty "$SAVED_TTY" 2>/dev/null

        if [[ "$resume" == "q" || "$resume" == $'\x03' ]]; then
          echo ""
          # Disable cleanup's clear since we're already clean
          PICKER_LINES=0
          return 0
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

      esc|q|ctrl-c)
        clear_picker
        PICKER_LINES=0
        return
        ;;
    esac

    adjust_viewport "$selected"
    draw_picker "$selected"
    FLASH_MSG=""
  done
}
