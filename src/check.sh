# ── Check mode: report which tools are installed ─────────────────────────────

# Shell builtins and coreutils that are always available - not worth checking
_CHECK_SKIP="^(cd|cp|mv|rm|mkdir|echo|export|source|cat|chmod|chown|ln|touch|ls|printf|trap|pwd|set|unset|eval|exec|exit|return|read|test|true|false|tee|head|tail|wc|sort|grep|xargs|find|tar|gzip|gunzip|sed|awk|tr|cut|diff|date|sleep|kill|whoami|env|which|man|less|more)$"

# Extract the tool name from a command string
# Strips leading env vars (FOO=bar) and sudo, returns the first word
# Sets _CT_RESULT or "" if nothing useful
_check_tool_name() {
  local cmd="$1"

  # Strip leading env vars
  while [[ "$cmd" =~ ^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]* ]]; do
    cmd="${cmd#"${BASH_REMATCH[0]}"}"
    cmd="${cmd#"${cmd%%[![:space:]]*}"}"
  done

  # Strip sudo
  if [[ "$cmd" =~ ^sudo[[:space:]]+ ]]; then
    cmd="${cmd#sudo}"
    cmd="${cmd#"${cmd%%[![:space:]]*}"}"
  fi

  # First word
  local tool="${cmd%% *}"

  # Skip paths (./foo, /foo, bin/foo), flags (-h, --help), empty, builtins
  if [[ -z "$tool" ]] || [[ "$tool" == -* ]] || [[ "$tool" == */* ]] || [[ "$tool" =~ $_CHECK_SKIP ]]; then
    _CT_RESULT=""
    return
  fi

  _CT_RESULT="$tool"
}

run_check() {
  local -a tools=()
  local tool

  # Collect unique tool names from all extracted commands
  for idx in "${!DISPLAY_LINES[@]}"; do
    [[ "${LINE_TYPES[$idx]}" != "command" ]] && continue
    _check_tool_name "${LINE_CMDS[$idx]}"
    [[ -z "$_CT_RESULT" ]] && continue
    tool="$_CT_RESULT"

    # Deduplicate
    local seen=false
    for t in "${tools[@]+"${tools[@]}"}"; do
      [[ "$t" == "$tool" ]] && seen=true && break
    done
    $seen && continue
    tools+=("$tool")
  done

  if (( ${#tools[@]} == 0 )); then
    echo "${YELLOW}hdi: no tool references found in commands${RESET}" >&2
    echo "${DIM}Try: hdi all --full${RESET}" >&2
    exit 1
  fi

  # Header
  printf "\n%s%s[hdi] %s%s  %scheck%s\n\n" "$BOLD" "$YELLOW" "$PROJECT_NAME" "$RESET" "$DIM" "$RESET"

  local found=0 missing=0
  for tool in "${tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
      # Try to extract a version number
      local ver=""
      ver=$("$tool" --version 2>&1 | head -1) || true
      if [[ "$ver" =~ [0-9]+\.[0-9]+[0-9.]* ]]; then
        ver="${BASH_REMATCH[0]}"
      else
        ver=""
      fi

      if [[ -n "$ver" ]]; then
        printf "  %s✓%s %-14s %s(%s)%s\n" "$GREEN" "$RESET" "$tool" "$DIM" "$ver" "$RESET"
      else
        printf "  %s✓%s %-14s\n" "$GREEN" "$RESET" "$tool"
      fi
      found=$((found + 1))
    else
      printf "  %s✗%s %-14s %snot found%s\n" "$YELLOW" "$RESET" "$tool" "$DIM" "$RESET"
      missing=$((missing + 1))
    fi
  done

  printf "\n"
  if (( missing == 0 )); then
    printf "  %s✓ All %d tools found%s\n\n" "$DIM" "$found" "$RESET"
  else
    printf "  %s%d found, %s%d not found%s\n\n" "$DIM" "$found" "$YELLOW" "$missing" "$RESET"
  fi
}
