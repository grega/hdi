
# ── Defaults ─────────────────────────────────────────────────────────────────
MODE="default"
FULL=false
RAW=false
INTERACTIVE="auto"   # auto | yes | no
DIR="."
FILE=""

# ── Keyword groups ───────────────────────────────────────────────────────────
KW_INSTALL="prerequisite(s)?|require(ments)?|depend(encies)?|install(ing|ation)?|setup|set[. _-]up|getting[. _-]started|quick[. _-]start|quickstart|how[. _-]to|docker|migration|database[. _-]setup"
KW_RUN="^usage|run(ning)?|start(ing)?|develop(ment|ing)?|dev[. _-]server|launch(ing)?|command|scripts|makefile|make[. _-]targets"
KW_TEST="test(s|ing)?"
KW_EXTRA="build(ing)?|compil(ation|ing)|config(uration|uring)?|environment|deploy(ment|ing)?"

# ── Parse arguments ──────────────────────────────────────────────────────────
for arg in "$@"; do
  case "$arg" in
    install|setup|i)        MODE="install" ;;
    run|start|r)            MODE="run" ;;
    test|t)                 MODE="test" ;;
    all|a)                  MODE="all" ;;
    --full|-f)              FULL=true ;;
    --raw)                  RAW=true; INTERACTIVE="no" ;;
    --no-interactive|--ni)  INTERACTIVE="no" ;;
    --version|-v)
      echo "hdi $VERSION"
      exit 0
      ;;
    --help|-h)
      sed -n '2,/^$/{ s/^# \{0,1\}//; p; }' "$0"
      exit 0
      ;;
    *)
      if [[ -d "$arg" ]]; then
        DIR="$arg"
      elif [[ -f "$arg" && ( "$arg" == *.md || "$arg" == *.rst ) ]]; then
        FILE="$arg"
      else
        echo "Unknown argument: $arg" >&2; exit 1
      fi
      ;;
  esac
done

# Resolve interactive mode
if [[ "$INTERACTIVE" == "auto" ]]; then
  if [[ -t 0 ]] && [[ -t 1 ]] && ! $FULL; then
    INTERACTIVE="yes"
  else
    INTERACTIVE="no"
  fi
fi

# Build the keyword pattern for the chosen mode
case "$MODE" in
  install)  PATTERN="($KW_INSTALL)" ;;
  run)      PATTERN="($KW_RUN)" ;;
  test)     PATTERN="($KW_TEST)" ;;
  all)      PATTERN="($KW_INSTALL|$KW_RUN|$KW_TEST|$KW_EXTRA)" ;;
  default)  PATTERN="($KW_INSTALL|$KW_RUN)" ;;
esac
