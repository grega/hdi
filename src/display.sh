# ── Build a flat list: section headers + commands ────────────────────────────
# Each entry is either a "header", "subheader", "command", or "empty".
# We store parallel arrays for the display lines, their types, and
# (for commands) the actual command.

declare -a DISPLAY_LINES=()   # what to print
declare -a LINE_TYPES=()      # "header" | "subheader" | "command" | "empty"
declare -a LINE_CMDS=()       # the raw command (only for type=command)
declare -a CMD_INDICES=()     # indices into DISPLAY_LINES that are commands
declare -a SECTION_FIRST_CMD=()  # cursor indices (into CMD_INDICES) of first cmd per section

build_display_list() {
  for i in "${!SECTION_TITLES[@]}"; do
    local title="${SECTION_TITLES[$i]}"
    local body="${SECTION_BODIES[$i]}"

    # Section header
    DISPLAY_LINES+=("$title")
    LINE_TYPES+=("header")
    LINE_CMDS+=("")

    # Extract commands from backtick-wrapped text in the heading itself
    # (eg. ### `yarn start` - the command is the heading)
    find_backtick_commands "$title" false
    local title_cmds="$_FBC_RESULT"
    local has_cmds=false
    local _section_recorded=false
    if [[ -n "$title_cmds" ]]; then
      while IFS= read -r tcmd; do
        [[ -z "$tcmd" ]] && continue
        has_cmds=true
        CMD_INDICES+=("${#DISPLAY_LINES[@]}")
        if ! $_section_recorded; then
          SECTION_FIRST_CMD+=("$(( ${#CMD_INDICES[@]} - 1 ))")
          _section_recorded=true
        fi
        DISPLAY_LINES+=("$tcmd")
        LINE_TYPES+=("command")
        LINE_CMDS+=("$tcmd")
      done <<< "$title_cmds"
    fi

    # Extract commands with sub-group markers (single pass over the body)
    # Sub-headings and bold pseudo-headings produce \x01-prefixed marker
    # lines; everything else is a command or empty line
    _EC_GROUPED=true
    extract_commands "$body"
    _EC_GROUPED=false
    local cmds="$_EC_RESULT"

    # Deduplicate commands within each sub-group (pure bash, no awk)
    if [[ -n "$cmds" ]]; then
      local _deduped="" _dup _cur_group="" _group_seen=""
      while IFS= read -r _cmd; do
        [[ -z "$_cmd" ]] && continue
        # Sub-header marker - reset per-group seen list
        if [[ "$_cmd" == "$_EC_SUBHDR"* ]]; then
          _deduped+="$_cmd"$'\n'
          _group_seen=""
          continue
        fi
        _dup=false
        if [[ -n "$_group_seen" ]]; then
          while IFS= read -r _existing; do
            [[ "$_existing" == "$_cmd" ]] && _dup=true && break
          done <<< "$_group_seen"
        fi
        if ! $_dup; then
          _deduped+="$_cmd"$'\n'
          _group_seen+="$_cmd"$'\n'
        fi
      done <<< "$cmds"
      cmds="$_deduped"
    fi

    # Build display entries from the flat command list with markers
    if [[ -n "$cmds" ]]; then
      local _pending_label=""
      while IFS= read -r _entry; do
        [[ -z "$_entry" ]] && continue
        if [[ "$_entry" == "$_EC_SUBHDR"* ]]; then
          _pending_label="${_entry:1}"
          continue
        fi
        # Emit the sub-header only when its group has commands
        if [[ -n "$_pending_label" ]]; then
          DISPLAY_LINES+=("$_pending_label")
          LINE_TYPES+=("subheader")
          LINE_CMDS+=("")
          _pending_label=""
        fi
        has_cmds=true
        CMD_INDICES+=("${#DISPLAY_LINES[@]}")
        if ! $_section_recorded; then
          SECTION_FIRST_CMD+=("$(( ${#CMD_INDICES[@]} - 1 ))")
          _section_recorded=true
        fi
        DISPLAY_LINES+=("$_entry")
        LINE_TYPES+=("command")
        LINE_CMDS+=("$_entry")
      done <<< "$cmds"
    fi

    if ! $has_cmds; then
      DISPLAY_LINES+=("(no commands - use --full to see prose)")
      LINE_TYPES+=("empty")
      LINE_CMDS+=("")
    fi

    # Blank separator
    DISPLAY_LINES+=("")
    LINE_TYPES+=("empty")
    LINE_CMDS+=("")
  done
}
