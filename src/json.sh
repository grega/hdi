# ── JSON output ───────────────────────────────────────────────────────────────

# Escape a string for safe embedding in JSON
_json_esc() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

# Set PATTERN for a given mode name (mirrors the case in args.sh)
_json_set_pattern() {
  case "$1" in
    install)  PATTERN="($KW_INSTALL)" ;;
    run)      PATTERN="($KW_RUN)" ;;
    test)     PATTERN="($KW_TEST)" ;;
    deploy)   PATTERN="($KW_DEPLOY)" ;;
    *)        PATTERN="($KW_INSTALL|$KW_RUN|$KW_TEST|$KW_DEPLOY|$KW_EXTRA)" ;;
  esac
}

# Print the modes display-list array as JSON for the current DISPLAY_LINES
# Skips trailing blank separators (empty type + empty text)
_json_display_list() {
  local mode="$1"
  printf '    "%s": [' "$mode"
  local first=true
  for idx in "${!DISPLAY_LINES[@]}"; do
    local text="${DISPLAY_LINES[$idx]}"
    local type="${LINE_TYPES[$idx]}"
    [[ "$type" == "empty" && -z "$text" ]] && continue
    $first || printf ','
    first=false
    printf '\n      {"type": "%s", "text": "%s"}' "$type" "$(_json_esc "$text")"
  done
  printf '\n    ]'
}

# Print the fullProse array as JSON for the current SECTION_TITLES/BODIES
_json_full_prose() {
  local mode="$1"
  printf '    "%s": [' "$mode"
  local first_item=true

  _fp_emit() {
    $first_item || printf ','
    first_item=false
    printf '\n      {"type": "%s", "text": "%s"}' "$1" "$(_json_esc "$2")"
  }

  # Render a plain prose line (not inside a code block)
  _fp_prose_line() {
    local l="$1"
    # Empty / whitespace-only
    if [[ -z "${l// /}" ]]; then
      _fp_emit "empty" ""
      return
    fi
    # ATX sub-heading (##+ )
    if [[ "$l" =~ ^#{2,6}[[:space:]]+(.*) ]]; then
      local sub="${BASH_REMATCH[1]}"
      if [[ "$sub" =~ ^(.*[^#[:space:]])[[:space:]]*#+ ]]; then
        sub="${BASH_REMATCH[1]}"
      fi
      while [[ "$sub" =~ ^(.*)\*\*([^*]+)\*\*(.*) ]]; do sub="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}"; done
      while [[ "$sub" =~ ^(.*)\*([^*]+)\*(.*) ]]; do sub="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}"; done
      _fp_emit "subheader" "$sub"
      return
    fi
    _fp_emit "prose" "$l"
  }

  for i in "${!SECTION_TITLES[@]}"; do
    local title="${SECTION_TITLES[$i]}"
    local content="${SECTION_BODIES[$i]}"

    # Strip trailing blank lines (same as render_full)
    while [[ "$content" == *$'\n' ]]; do
      local _s="${content%$'\n'}"
      local _last="${_s##*$'\n'}"
      if [[ "$_last" =~ ^[[:space:]]*$ ]]; then
        content="$_s"
      else
        break
      fi
    done
    [[ -z "$content" ]] && continue

    # Section header
    _fp_emit "header" "$title"

    local fp_in_code=false fp_skip=false fp_fence=""
    local fp_prev="" fp_have_prev=false

    while IFS= read -r line; do
      # Fenced code blocks
      if [[ "$line" =~ ^[[:space:]]*(\`{3,}|~{3,}) ]]; then
        local fp_matched="${BASH_REMATCH[1]}"
        # Flush buffered prev line before handling fence
        if $fp_have_prev && ! $fp_in_code; then
          _fp_prose_line "$fp_prev"
          fp_have_prev=false; fp_prev=""
        fi
        if $fp_in_code; then
          [[ "${fp_matched:0:1}" == "$fp_fence" ]] && fp_in_code=false && fp_skip=false && fp_fence=""
        else
          fp_in_code=true
          fp_fence="${fp_matched:0:1}"
          fp_skip=false
          local rest="${line#*"$fp_matched"}"
          rest="${rest#"${rest%%[![:space:]]*}"}"
          local lang="${rest%%[[:space:]]*}"
          lang="${lang%%[^a-zA-Z0-9_-]*}"
          if [[ -n "$lang" ]]; then
            shopt -s nocasematch
            [[ "$lang" =~ $_RE_SKIP_LANG ]] && fp_skip=true
            shopt -u nocasematch
          fi
        fi
        continue
      fi

      # Inside code block
      if $fp_in_code; then
        if $fp_skip; then
          _fp_emit "prose" "$line"
        else
          local stripped="${line#"${line%%[![:space:]]*}"}"
          strip_prompt "$stripped"; stripped="$_SP_RESULT"
          _fp_emit "command" "$stripped"
        fi
        continue
      fi

      # Setext heading detection (prev_line followed by ===+ or ---+)
      if $fp_have_prev && [[ "$line" =~ ^[[:space:]]*(={3,}|-{3,})[[:space:]]*$ ]]; then
        local sh_text="$fp_prev"
        while [[ "$sh_text" =~ ^(.*)\*\*([^*]+)\*\*(.*) ]]; do sh_text="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}"; done
        while [[ "$sh_text" =~ ^(.*)\*([^*]+)\*(.*) ]]; do sh_text="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}"; done
        _fp_emit "subheader" "$sh_text"
        fp_have_prev=false; fp_prev=""
        continue
      fi

      # Process buffered prev line
      if $fp_have_prev; then
        _fp_prose_line "$fp_prev"
      fi
      fp_prev="$line"
      fp_have_prev=true
    done <<< "$content"

    # Flush final buffered line
    if $fp_have_prev; then
      _fp_prose_line "$fp_prev"
    fi
  done

  printf '\n    ]'
}

# Print the check array as JSON using the current DISPLAY_LINES
_json_check() {
  local -a tools=()
  local tool

  for idx in "${!DISPLAY_LINES[@]}"; do
    [[ "${LINE_TYPES[$idx]}" != "command" ]] && continue
    _check_tool_name "${LINE_CMDS[$idx]}"
    [[ -z "$_CT_RESULT" ]] && continue
    tool="$_CT_RESULT"
    local seen=false
    for t in "${tools[@]+"${tools[@]}"}"; do
      [[ "$t" == "$tool" ]] && seen=true && break
    done
    $seen && continue
    tools+=("$tool")
  done

  printf '['
  local first=true
  for tool in "${tools[@]+"${tools[@]}"}"; do
    $first || printf ','
    first=false
    if command -v "$tool" >/dev/null 2>&1; then
      local ver=""
      ver=$("$tool" --version 2>&1 | head -1) || true
      if [[ "$ver" =~ [0-9]+\.[0-9]+[0-9.]* ]]; then
        ver="${BASH_REMATCH[0]}"
        printf '\n    {"tool": "%s", "installed": true, "version": "%s"}' "$tool" "$ver"
      else
        printf '\n    {"tool": "%s", "installed": true}' "$tool"
      fi
    else
      printf '\n    {"tool": "%s", "installed": false}' "$tool"
    fi
  done
  printf '\n  ]'
}

# Main JSON renderer: outputs all modes, fullProse, and check
render_json() {
  local _modes=("default" "install" "run" "test" "deploy" "all")
  local first

  printf '{\n  "modes": {\n'
  first=true
  for _m in "${_modes[@]}"; do
    $first || printf ',\n'
    first=false
    _json_set_pattern "$_m"
    SECTION_TITLES=(); SECTION_BODIES=()
    parse_sections < "$README"
    DISPLAY_LINES=(); LINE_TYPES=(); LINE_CMDS=(); CMD_INDICES=()
    build_display_list
    _json_display_list "$_m"
  done

  printf '\n  },\n  "fullProse": {\n'
  first=true
  for _m in "${_modes[@]}"; do
    $first || printf ',\n'
    first=false
    _json_set_pattern "$_m"
    SECTION_TITLES=(); SECTION_BODIES=()
    parse_sections < "$README"
    _json_full_prose "$_m"
  done

  # Re-parse with "all" pattern for check tool extraction
  printf '\n  },\n  "check": '
  _json_set_pattern "all"
  SECTION_TITLES=(); SECTION_BODIES=()
  parse_sections < "$README"
  DISPLAY_LINES=(); LINE_TYPES=(); LINE_CMDS=(); CMD_INDICES=()
  build_display_list
  _json_check

  printf '\n}\n'
}
