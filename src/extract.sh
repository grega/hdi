# ── Extract fenced code blocks, skipping non-command languages ───────────────
SKIP_LANGS="json|yaml|yml|toml|xml|csv|sql|html|css|text|plaintext|txt|output|log|env"
SKIP_LANGS+="|ini|conf|properties|graphql|gql|proto|protobuf|hcl"
SKIP_LANGS+="|markdown|md|mermaid|diff|patch|svg"

# Pre-compiled regex patterns for language checks (avoids grep in loops)
_RE_SKIP_LANG="^($SKIP_LANGS)$"
_RE_CONSOLE="^(console|terminal)$"

# Known CLI prefixes for recognising commands in inline backticks (`yarn test`)
# and for validating shell prompt stripping ($ command → command)
CMD_PREFIXES="yarn|npm|npx|pnpm|pnpx|bunx|node|bun|deno|corepack"
CMD_PREFIXES+="|python3?|pip3?|pipenv|poetry|uv|conda|mamba"
CMD_PREFIXES+="|ruby|gem|bundle|rake|rails"
CMD_PREFIXES+="|cargo|rustup"
CMD_PREFIXES+="|go|zig"
CMD_PREFIXES+="|java|javac|mvn|gradle|sbt|lein|clj|mill"
CMD_PREFIXES+="|dotnet"
CMD_PREFIXES+="|swift|flutter|dart"
CMD_PREFIXES+="|elixir|mix|iex"
CMD_PREFIXES+="|php|composer|perl|lua"
CMD_PREFIXES+="|cabal|stack"
CMD_PREFIXES+="|docker|docker-compose|podman"
CMD_PREFIXES+="|make|cmake|just|task|bazel|pants"
CMD_PREFIXES+="|bash|sh|zsh"
CMD_PREFIXES+="|curl|wget|git|sudo|apt|apt-get|brew|yum|dnf|pacman"
CMD_PREFIXES+="|kubectl|terraform|ansible|helm"
CMD_PREFIXES+="|nix|mise|asdf|rtx|fnm|nvm|volta"
CMD_PREFIXES+="|ng|vue|vite|turbo|nx"

# Pre-compiled regex patterns for command matching (avoids rebuilding in loops)
_RE_CMD_SPACE="^($CMD_PREFIXES) "
_RE_CMD_END="^($CMD_PREFIXES)( |$)"
_RE_INDENTED_CMD="^[[:space:]]*(\\\$[[:space:]]+)?($CMD_PREFIXES)( |$)"

# Extract backtick-wrapped commands from a line of text
# Sets _FBC_RESULT (newline-separated) instead of printing to stdout
# Usage: find_backtick_commands "text" [require_args]
#   require_args=true  (default) - prefix must be followed by a space (prose)
#   require_args=false            - bare prefix allowed (headings like `make`)
find_backtick_commands() {
  local text="$1"
  local require_args="${2:-true}"
  local pat="$_RE_CMD_SPACE"
  $require_args || pat="$_RE_CMD_END"
  _FBC_RESULT=""
  local remaining="$text"
  while [[ "$remaining" =~ \`([^\`]+)\` ]]; do
    local match="${BASH_REMATCH[1]}"
    remaining="${remaining#*"${BASH_REMATCH[0]}"}"
    shopt -s nocasematch
    if [[ "$match" =~ $pat ]]; then
      _FBC_RESULT+="$match"$'\n'
    fi
    shopt -u nocasematch
  done
}

# Strip shell prompt prefixes ($ or %) from fenced code block lines
# The regex requires whitespace after $ so "$HOME/bin" is never mangled
# Sets _SP_RESULT instead of printing to stdout (avoids subshell per call).
strip_prompt() {
  if [[ "$1" =~ ^[[:space:]]*[\$%][[:space:]]+(.*) ]]; then
    _SP_RESULT="${BASH_REMATCH[1]}"
  else
    _SP_RESULT="$1"
  fi
}

# Extract commands from section body text
# Sets _EC_RESULT instead of printing to stdout (avoids subshell per call)
#
# When _EC_GROUPED=true, sub-headings (##+ ) and bold pseudo-headings
# (**text**) in the prose are emitted as marker lines prefixed with \x01
# so the caller can create display sub-groups without a second pass
_EC_GROUPED=false
_EC_SUBHDR=$'\x01'

extract_commands() {
  local content="$1"
  local commands=""
  local in_code=false
  local skip_block=false
  local fence_char=""
  local continuation_buf=""
  local console_mode=false
  local indented_buf=""
  local line iline inline_cmds inline_cmd

  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*(\`{3,}|~{3,}) ]]; then
      local matched="${BASH_REMATCH[1]}"
      if $in_code; then
        # Only close if same fence character
        if [[ "${matched:0:1}" == "$fence_char" ]]; then
          # Flush any pending continuation
          if [[ -n "$continuation_buf" ]]; then
            commands+="$continuation_buf"$'\n'
            continuation_buf=""
          fi
          in_code=false
          if ! $skip_block && [[ -n "$commands" ]]; then
            commands+=$'\n'
          fi
          skip_block=false
          fence_char=""
          console_mode=false
        fi
      else
        in_code=true
        fence_char="${matched:0:1}"
        local lang=""
        local rest="${line#*"$matched"}"
        rest="${rest#"${rest%%[![:space:]]*}"}"
        lang="${rest%%[[:space:]]*}"
        lang="${lang%%[^a-zA-Z0-9_-]*}"
        if [[ -n "$lang" ]]; then
          shopt -s nocasematch
          if [[ "$lang" =~ $_RE_SKIP_LANG ]]; then
            skip_block=true
          elif [[ "$lang" =~ $_RE_CONSOLE ]]; then
            console_mode=true
          fi
          shopt -u nocasematch
        fi
      fi
      continue
    fi
    if $in_code && ! $skip_block; then
      local stripped="${line#"${line%%[![:space:]]*}"}"
      # In console mode, only extract lines with $ or % prompts (skip output)
      if $console_mode; then
        if [[ "$stripped" =~ ^[\$%][[:space:]]+ ]]; then
          strip_prompt "$stripped"; stripped="$_SP_RESULT"
        else
          continue
        fi
      else
        strip_prompt "$stripped"; stripped="$_SP_RESULT"
      fi
      # Handle backslash line continuations
      if [[ "$stripped" =~ \\[[:space:]]*$ ]]; then
        continuation_buf+="${stripped%\\*} "
      elif [[ -n "$continuation_buf" ]]; then
        commands+="${continuation_buf}${stripped}"$'\n'
        continuation_buf=""
      else
        commands+="$stripped"$'\n'
      fi
    elif ! $in_code; then
      # Detect sub-headings and bold pseudo-headings for display grouping
      if $_EC_GROUPED; then
        if [[ "$line" =~ ^#{2,6}[[:space:]]+(.*) ]]; then
          local _ec_label="${BASH_REMATCH[1]}"
          if [[ "$_ec_label" =~ ^(.*[^#[:space:]])[[:space:]]*#+ ]]; then
            _ec_label="${BASH_REMATCH[1]}"
          fi
          while [[ "$_ec_label" =~ ^(.*)\*\*([^*]+)\*\*(.*) ]]; do _ec_label="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}"; done
          while [[ "$_ec_label" =~ ^(.*)\*([^*]+)\*(.*) ]]; do _ec_label="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}"; done
          commands+="${_EC_SUBHDR}${_ec_label}"$'\n'
          # Fall through to check inline backtick cmds in heading text
        elif [[ "$line" =~ ^[[:space:]]*\*\*([^*]+)\*\*[[:space:]]*$ ]]; then
          commands+="${_EC_SUBHDR}${BASH_REMATCH[1]}"$'\n'
          continue
        fi
      fi
      # Detect indented code blocks (4+ spaces or tab)
      if [[ "$line" =~ ^(\ {4,}|	) ]] && [[ -n "${line//[[:space:]]/}" ]]; then
        local dedented="${line#    }"
        [[ "$line" == $'\t'* ]] && dedented="${line#$'\t'}"
        indented_buf+="$dedented"$'\n'
        continue
      fi
      # Flush indented buffer - only include if it looks like commands
      if [[ -n "$indented_buf" ]]; then
        shopt -s nocasematch
        if [[ "$indented_buf" =~ $_RE_INDENTED_CMD ]]; then
          shopt -u nocasematch
          while IFS= read -r iline; do
            [[ -z "$iline" ]] && continue
            strip_prompt "$iline"; iline="$_SP_RESULT"
            commands+="$iline"$'\n'
          done <<< "$indented_buf"
        else
          shopt -u nocasematch
        fi
        indented_buf=""
      fi

      find_backtick_commands "$line"
      inline_cmds="$_FBC_RESULT"
      if [[ -n "$inline_cmds" ]]; then
        while IFS= read -r inline_cmd; do
          commands+="$inline_cmd"$'\n'
        done <<< "$inline_cmds"
      fi
    fi
  done <<< "$content"

  # Flush any remaining indented buffer
  if [[ -n "$indented_buf" ]]; then
    shopt -s nocasematch
    if [[ "$indented_buf" =~ $_RE_INDENTED_CMD ]]; then
      shopt -u nocasematch
      while IFS= read -r iline; do
        [[ -z "$iline" ]] && continue
        strip_prompt "$iline"; iline="$_SP_RESULT"
        commands+="$iline"$'\n'
      done <<< "$indented_buf"
    else
      shopt -u nocasematch
    fi
    indented_buf=""
  fi

  _EC_RESULT="$commands"
}
