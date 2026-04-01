# ── Non-interactive render ──────────────────────────────────
render_static() {
  for idx in "${!DISPLAY_LINES[@]}"; do
    local line="${DISPLAY_LINES[$idx]}"
    local type="${LINE_TYPES[$idx]}"

    case "$type" in
      filesep)
        if $RAW; then
          printf "\n--- %s ---\n" "$line"
        else
          printf "\n%s  ── %s ──────────────────────────────%s\n" "$DIM" "$line" "$RESET"
        fi
        ;;
      header)
        if $RAW; then
          printf "\n## %s\n" "$line"
        else
          _section_header "$line"; printf "\n%s\n" "$_SH"
        fi
        ;;
      subheader)
        if $RAW; then
          printf "\n### %s\n" "$line"
        else
          printf "\n  %s%s%s%s\n" "$BOLD" "$MAGENTA" "$line" "$RESET"
        fi
        ;;
      command)
        if $RAW; then
          printf "%s\n" "$line"
        else
          printf "  %s%s%s\n" "$GREEN" "$line" "$RESET"
        fi
        ;;
      empty)
        if $RAW; then
          if [[ -n "$line" ]]; then printf "  %s\n" "$line"; fi
        else
          if [[ -n "$line" ]]; then printf "  %s%s%s\n" "$DIM" "$line" "$RESET"; fi
        fi
        ;;
    esac
  done
}

# ── Full-prose render ────────────────────────────────────────────────────────
render_full() {
  local _rf_prev_source=""
  for i in "${!SECTION_TITLES[@]}"; do
    local title="${SECTION_TITLES[$i]}"
    local content="${SECTION_BODIES[$i]}"
    local _rf_source="${SECTION_FILES[$i]:-}"

    # File separator when source changes
    if [[ -n "$_rf_prev_source" && -n "$_rf_source" && "$_rf_source" != "$_rf_prev_source" ]]; then
      if $RAW; then
        printf "\n--- %s ---\n" "$(basename "$_rf_source")"
      else
        printf "\n%s  ── %s ──────────────────────────────%s\n" "$DIM" "$(basename "$_rf_source")" "$RESET"
      fi
    fi
    _rf_prev_source="$_rf_source"

    # Strip trailing blank lines (pure bash, no tail subprocess)
    while [[ "$content" == *$'\n' ]]; do
      local _stripped="${content%$'\n'}"
      local _last_line="${_stripped##*$'\n'}"
      if [[ "$_last_line" =~ ^[[:space:]]*$ ]]; then
        content="$_stripped"
      else
        break
      fi
    done
    [[ -z "$content" ]] && continue

    if $RAW; then
      printf "\n## %s\n\n%s\n" "$title" "$content"
      continue
    fi

    _section_header "$title"; printf "\n%s\n" "$_SH"

    local in_code=false
    local code_buf=""
    local rf_fence_char=""
    local rf_prev="" rf_have_prev=false

    # Helper: render a single non-heading, non-code body line
    _rf_render_line() {
      local l="$1"
      [[ -z "${l// /}" ]] && echo "" && return
      if [[ "$l" =~ ^#{2,}[[:space:]]+(.*) ]]; then
        local sub_heading="${BASH_REMATCH[1]}"
        if [[ "$sub_heading" =~ ^(.*[^#[:space:]])[[:space:]]*#+ ]]; then
          sub_heading="${BASH_REMATCH[1]}"
        fi
        # Strip bold/italic (pure bash, no sed)
        while [[ "$sub_heading" =~ ^(.*)\*\*([^*]+)\*\*(.*) ]]; do sub_heading="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}"; done
        while [[ "$sub_heading" =~ ^(.*)\*([^*]+)\*(.*) ]]; do sub_heading="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}"; done
        while [[ "$sub_heading" =~ ^(.*)__([^_]+)__(.*) ]]; do sub_heading="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}"; done
        while [[ "$sub_heading" =~ ^(.*)_([^_]+)_(.*) ]]; do sub_heading="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}"; done
        printf "  %s%s%s\n" "$MAGENTA$BOLD" "$sub_heading" "$RESET"
        return
      fi
      # Highlight backtick content (pure bash, no sed)
      local formatted=""
      local _rem="$l"
      while [[ "$_rem" =~ ^([^\`]*)\`([^\`]+)\`(.*) ]]; do
        formatted+="${BASH_REMATCH[1]}${GREEN}${BASH_REMATCH[2]}${RESET}"
        _rem="${BASH_REMATCH[3]}"
      done
      formatted+="$_rem"
      printf "  %s\n" "$formatted"
    }

    while IFS= read -r line; do
      # Handle fenced code blocks (pass-through, no lookahead needed)
      if [[ "$line" =~ ^[[:space:]]*(\`{3,}|~{3,}) ]]; then
        local rf_matched="${BASH_REMATCH[1]}"
        # Flush buffered prev line before handling fence
        if $rf_have_prev && ! $in_code; then
          _rf_render_line "$rf_prev"
          rf_have_prev=false; rf_prev=""
        fi
        if $in_code; then
          if [[ "${rf_matched:0:1}" == "$rf_fence_char" ]]; then
            printf "%s%s%s\n" "$CODE_BG$GREEN" "$code_buf" "$RESET"
            code_buf=""; in_code=false; rf_fence_char=""
          fi
        else
          in_code=true
          rf_fence_char="${rf_matched:0:1}"
        fi
        continue
      fi
      if $in_code; then
        code_buf+="  $line"$'\n'
        continue
      fi

      # Setext heading detection: prev_line followed by ===+ or ---+
      if $rf_have_prev && [[ "$line" =~ ^[[:space:]]*(={3,}|-{3,})[[:space:]]*$ ]]; then
        local sh_text="$rf_prev"
        while [[ "$sh_text" =~ ^(.*)\*\*([^*]+)\*\*(.*) ]]; do sh_text="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}"; done
        while [[ "$sh_text" =~ ^(.*)\*([^*]+)\*(.*) ]]; do sh_text="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}"; done
        while [[ "$sh_text" =~ ^(.*)__([^_]+)__(.*) ]]; do sh_text="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}"; done
        while [[ "$sh_text" =~ ^(.*)_([^_]+)_(.*) ]]; do sh_text="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}"; done
        printf "  %s%s%s\n" "$MAGENTA$BOLD" "$sh_text" "$RESET"
        rf_have_prev=false; rf_prev=""
        continue
      fi

      # Process buffered prev line
      if $rf_have_prev; then
        _rf_render_line "$rf_prev"
      fi
      rf_prev="$line"
      rf_have_prev=true
    done <<< "$content"

    # Flush final buffered line
    if $rf_have_prev; then
      _rf_render_line "$rf_prev"
    fi
  done
}
