# ── Main ─────────────────────────────────────────────────────────────────────

if $JSON; then
  render_json
  exit 0
fi

parse_sections < "$README"

if (( ${#SECTION_TITLES[@]} == 0 )); then
  echo "${YELLOW}hdi: no matching sections found in ${README}${RESET}" >&2
  echo "${DIM}Try: hdi all --full${RESET}" >&2
  exit 1
fi

PROJECT_NAME=$(basename "$(cd "$DIR" && pwd)")
build_display_list

# Platform detection (deploy mode only, including interactive)
if [[ "$MODE" == "deploy" ]]; then
  _project_dir="$DIR"
  if [[ -n "$FILE" ]]; then _project_dir="${FILE%/*}"; fi
  detect_platforms_from_files "$_project_dir"
  detect_platforms_from_commands
  detect_platforms_from_prose
  build_platform_display
fi

if [[ "$MODE" == "check" ]]; then
  run_check
elif [[ "$INTERACTIVE" == "yes" ]] && ! $FULL; then
  run_interactive
else
  if ! $RAW; then
    printf "%s%s[hdi] %s%s" "$BOLD" "$YELLOW" "$PROJECT_NAME" "$RESET"
    case "$MODE" in
      install) printf "  %s[install]%s" "$DIM" "$RESET" ;;
      run)     printf "  %s[run]%s" "$DIM" "$RESET" ;;
      test)    printf "  %s[test]%s" "$DIM" "$RESET" ;;
      deploy)
        if [[ -n "${_PLATFORM_DISPLAY:-}" ]]; then
          printf "  %s[deploy → %s%s%s%s]%s" "$DIM" "$RESET" "$CYAN" "$_PLATFORM_DISPLAY" "$DIM" "$RESET"
        else
          printf "  %s[deploy]%s" "$DIM" "$RESET"
        fi
        ;;
      all)     printf "  %s[all]%s" "$DIM" "$RESET" ;;
    esac
    printf "\n\n"
  fi

  if $FULL; then
    render_full
  else
    render_static
  fi

  if ! $RAW; then
    echo ""
    if ! $FULL; then
      printf "%s  ─ add --full for prose, or: install | run | deploy | all%s\n\n" "$DIM" "$RESET"
    fi
  fi
fi
