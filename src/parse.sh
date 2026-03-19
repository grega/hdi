
# ── Extract matching sections ────────────────────────────────────────────────
declare -a SECTION_TITLES=()
declare -a SECTION_BODIES=()

parse_sections() {
  local in_section=false
  local section_level=0
  local heading_text=""
  local body=""
  local prev_line=""
  local have_prev=false
  local ps_in_code=false
  local ps_fence_char=""

  shopt -s nocasematch

  # Helper: process a detected heading at a given level.
  # Sets _ps_started_new=true when a new section is started, so the
  # caller knows whether non-matching sub-headings should be kept in body.
  _ps_started_new=false

  _ps_handle_heading() {
    local text="$1" level="$2"
    _ps_started_new=false
    # Strip trailing ATX closing hashes
    if [[ "$text" =~ ^(.*[^#[:space:]])[[:space:]]*#+ ]]; then
      text="${BASH_REMATCH[1]}"
    fi
    # Strip bold/italic markdown formatting (pure bash, no sed)
    while [[ "$text" =~ ^(.*)\*\*([^*]+)\*\*(.*) ]]; do text="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}"; done
    while [[ "$text" =~ ^(.*)\*([^*]+)\*(.*) ]]; do text="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}"; done
    while [[ "$text" =~ ^(.*)__([^_]+)__(.*) ]]; do text="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}"; done
    while [[ "$text" =~ ^(.*)_([^_]+)_(.*) ]]; do text="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}"; done

    # Save the current section if a same-or-higher-level heading arrives,
    # or if a deeper-level heading also matches (avoids losing parent body)
    if $in_section; then
      if (( level <= section_level )); then
        SECTION_TITLES+=("$heading_text")
        SECTION_BODIES+=("$body")
        in_section=false
        body=""
      elif [[ "$text" =~ $PATTERN ]]; then
        # Deeper child heading also matches — save parent body first
        SECTION_TITLES+=("$heading_text")
        SECTION_BODIES+=("$body")
        in_section=false
        body=""
      fi
    fi

    if [[ "$text" =~ $PATTERN ]]; then
      in_section=true
      section_level=$level
      heading_text="$text"
      body=""
      _ps_started_new=true
    fi
  }

  while IFS= read -r line; do
    # Track fenced code blocks so comments/content inside them
    # are not misinterpreted as headings
    if [[ "$line" =~ ^[[:space:]]*(\`{3,}|~{3,}) ]]; then
      local ps_matched="${BASH_REMATCH[1]}"
      if $ps_in_code; then
        [[ "${ps_matched:0:1}" == "$ps_fence_char" ]] && ps_in_code=false && ps_fence_char=""
      else
        ps_in_code=true
        ps_fence_char="${ps_matched:0:1}"
      fi
      # Still include fence lines in body if we're in a section
      if $have_prev; then
        if $in_section; then body+="$prev_line"$'\n'; fi
        have_prev=false; prev_line=""
      fi
      if $in_section; then body+="$line"$'\n'; fi
      continue
    fi

    # Inside a code block — skip heading detection, just accumulate body
    if $ps_in_code; then
      if $have_prev; then
        if $in_section; then body+="$prev_line"$'\n'; fi
        have_prev=false; prev_line=""
      fi
      if $in_section; then body+="$line"$'\n'; fi
      continue
    fi

    # Check for setext underline: current line is ===+ or ---+ (3+ chars)
    if $have_prev && [[ "$line" =~ ^[[:space:]]*(={3,}|-{3,})[[:space:]]*$ ]]; then
      local setext_char="${BASH_REMATCH[1]:0:1}"
      local level=2
      [[ "$setext_char" == "=" ]] && level=1
      _ps_handle_heading "$prev_line" "$level"
      # Keep non-matching setext sub-headings in body (as ATX) for sub-grouping
      if $in_section && ! $_ps_started_new; then
        if (( level == 1 )); then body+="# $prev_line"$'\n'
        else body+="## $prev_line"$'\n'; fi
      fi
      have_prev=false
      prev_line=""
      continue
    fi

    # Process the buffered previous line
    if $have_prev; then
      if [[ "$prev_line" =~ ^(#{1,6})[[:space:]]+(.*) ]]; then
        local hashes="${BASH_REMATCH[1]}"
        local level=${#hashes}
        local text="${BASH_REMATCH[2]}"
        _ps_handle_heading "$text" "$level"
        # Keep non-matching ATX sub-headings in body for sub-grouping
        if $in_section && ! $_ps_started_new; then
          body+="$prev_line"$'\n'
        fi
      elif [[ "$prev_line" =~ ^[[:space:]]*\*\*([^*]+)\*\*[[:space:]]*$ ]]; then
        # Bold pseudo-heading: when not inside a real heading's section,
        # check against keywords so e.g. **Run application** matches run mode.
        # When inside a real section, keep it in body for sub-group display.
        local bold_text="${BASH_REMATCH[1]}"
        _ps_started_new=false
        if ! $in_section || (( section_level == 7 )); then
          _ps_handle_heading "$bold_text" 7
        fi
        if $in_section && ! $_ps_started_new; then
          body+="$prev_line"$'\n'
        fi
      elif $in_section; then
        body+="$prev_line"$'\n'
      fi
    fi

    prev_line="$line"
    have_prev=true
  done

  # Process final buffered line
  if $have_prev && ! $ps_in_code; then
    if [[ "$prev_line" =~ ^(#{1,6})[[:space:]]+(.*) ]]; then
      local hashes="${BASH_REMATCH[1]}"
      local level=${#hashes}
      local text="${BASH_REMATCH[2]}"
      _ps_handle_heading "$text" "$level"
      if $in_section && ! $_ps_started_new; then
        body+="$prev_line"$'\n'
      fi
    elif [[ "$prev_line" =~ ^[[:space:]]*\*\*([^*]+)\*\*[[:space:]]*$ ]]; then
      local bold_text="${BASH_REMATCH[1]}"
      _ps_started_new=false
      if ! $in_section || (( section_level == 7 )); then
        _ps_handle_heading "$bold_text" 7
      fi
      if $in_section && ! $_ps_started_new; then
        body+="$prev_line"$'\n'
      fi
    elif $in_section; then
      body+="$prev_line"$'\n'
    fi
  fi

  if $in_section; then
    SECTION_TITLES+=("$heading_text")
    SECTION_BODIES+=("$body")
  fi

  shopt -u nocasematch
}
