
# ── Main ─────────────────────────────────────────────────────────────────────
parse_sections < "$README"

if (( ${#SECTION_TITLES[@]} == 0 )); then
  echo "${YELLOW}No matching sections found in ${README}${RESET}" >&2
  echo "${DIM}Try: hdi all --full${RESET}" >&2
  exit 1
fi

PROJECT_NAME=$(basename "$(cd "$DIR" && pwd)")
build_display_list

if [[ "$INTERACTIVE" == "yes" ]] && ! $FULL; then
  run_interactive
else
  if ! $RAW; then
    printf "%s%s[hdi] %s%s" "$BOLD" "$YELLOW" "$PROJECT_NAME" "$RESET"
    case "$MODE" in
      install) printf "  %s[install]%s" "$DIM" "$RESET" ;;
      run)     printf "  %s[run]%s" "$DIM" "$RESET" ;;
      test)    printf "  %s[test]%s" "$DIM" "$RESET" ;;
      all)     printf "  %s[all]%s" "$DIM" "$RESET" ;;
    esac
    printf "\n"
  fi

  if $FULL; then
    render_full
  else
    render_static
  fi

  if ! $RAW; then
    echo ""
    if ! $FULL; then
      printf "%s  ─ add --full for prose, or: install | run | all%s\n\n" "$DIM" "$RESET"
    fi
  fi
fi
