# ── Defaults ─────────────────────────────────────────────────────────────────
MODE="default"
FULL=false
RAW=false
JSON=false
INTERACTIVE="auto"   # auto | yes | no
DIR="."
FILE=""

# ── Keyword groups ───────────────────────────────────────────────────────────
KW_INSTALL="prerequisite(s)?|require(ments)?|depend(encies)?|install(ing|ation)?|setup|set[. _-]up|getting[. _-]started|quick[. _-]start|quickstart|how[. _-]to|docker|migration|database[. _-]setup"
KW_RUN="^usage|run(ning)?|start(ing)?|dev|develop(ment|ing)?|dev[. _-]server|launch(ing)?|command|scripts|makefile|make[. _-]targets"
KW_TEST="test(s|ing)?"
KW_DEPLOY="deploy(ment|ing)?|ship(ping)?|release|publish(ing)?|provision(ing)?|rollout|ci[/-]?cd|pipeline"
KW_EXTRA="build(ing)?|compil(ation|ing)|config(uration|uring)?|environment|deploy(ment|ing)?"

# ── Parse arguments ──────────────────────────────────────────────────────────
for arg in "$@"; do
  case "$arg" in
    install|setup|i)        MODE="install" ;;
    run|start|r)            MODE="run" ;;
    test|t)                 MODE="test" ;;
    deploy|d)               MODE="deploy" ;;
    all|a)                  MODE="all" ;;
    needs|n)                MODE="needs" ;;
    contrib|c)              MODE="contrib" ;;
    --full|-f)              FULL=true ;;
    --raw)                  RAW=true; INTERACTIVE="no" ;;
    --json)                 JSON=true; INTERACTIVE="no" ;;
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
        echo "hdi: unknown argument: $arg" >&2
        echo "Try: hdi --help" >&2
        exit 1
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

# Benchmark mode: force interactive for picker timing
[[ "${_HDI_BENCH_PICKER:-}" == "1" ]] && INTERACTIVE="yes"

# Build the keyword pattern for the chosen mode
case "$MODE" in
  install)  PATTERN="($KW_INSTALL)" ;;
  run)      PATTERN="($KW_RUN)" ;;
  test)     PATTERN="($KW_TEST)" ;;
  deploy)   PATTERN="($KW_DEPLOY)" ;;
  all)      PATTERN="($KW_INSTALL|$KW_RUN|$KW_TEST|$KW_DEPLOY|$KW_EXTRA)" ;;
  needs)    PATTERN="($KW_INSTALL|$KW_RUN|$KW_TEST|$KW_DEPLOY|$KW_EXTRA)" ;;
  contrib)  PATTERN="($KW_INSTALL|$KW_RUN|$KW_TEST|$KW_DEPLOY|$KW_EXTRA)" ;;
  default)  PATTERN="($KW_INSTALL|$KW_RUN|$KW_TEST|$KW_DEPLOY|$KW_EXTRA)" ;;
esac
