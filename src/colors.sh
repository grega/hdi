
# ── Colours ──────────────────────────────────────────────────────────────────
if [[ -t 1 ]] && ! $RAW && [[ -z "${NO_COLOR:-}" ]] && [[ "${TERM:-}" != dumb ]]; then
  BOLD=$'\033[1m'  DIM=$'\033[2m'
  CYAN=$'\033[36m' GREEN=$'\033[32m' YELLOW=$'\033[33m' MAGENTA=$'\033[35m'
  WHITE=$'\033[97m' BG_SELECT=$'\033[48;5;236m'
  RESET=$'\033[0m' CODE_BG=$'\033[7m'
  HIDE_CURSOR=$'\033[?25l' SHOW_CURSOR=$'\033[?25h'
else
  BOLD="" DIM="" CYAN="" GREEN="" YELLOW="" MAGENTA="" WHITE=""
  BG_SELECT="" RESET="" CODE_BG="" HIDE_CURSOR="" SHOW_CURSOR=""
fi
