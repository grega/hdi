# ── Locate the README ───────────────────────────────────────────────────────
README=""
if [[ -n "$FILE" ]]; then
  README="$FILE"
else
  for candidate in "$DIR/README.md" "$DIR/readme.md" "$DIR/Readme.md" \
                   "$DIR/README.MD" "$DIR/README.rst" "$DIR/readme.rst"; do
    [[ -f "$candidate" ]] && README="$candidate" && break
  done
fi

if [[ -z "$README" ]] && [[ "$MODE" != "contrib" ]]; then
  echo "${YELLOW}hdi: no README found in ${DIR}${RESET}" >&2
  echo "${DIM}Looked for README.md, readme.md, Readme.md, README.rst${RESET}" >&2
  echo "${DIM}Try: hdi --help${RESET}" >&2
  exit 1
fi

# ── Discover contributor/development docs ───────────────────────────────────
CONTRIB_FILES=()
if [[ -z "$FILE" ]]; then
  for _cname in CONTRIBUTING.md contributing.md Contributing.md \
                DEVELOPMENT.md development.md Development.md \
                DEVELOPERS.md developers.md Developers.md \
                HACKING.md hacking.md; do
    [[ -f "$DIR/$_cname" ]] || continue
    # Deduplicate (case-insensitive filesystems may match multiple variants)
    _cf_dup=false
    _cf_real=$(cd "$DIR" && realpath "$_cname" 2>/dev/null || echo "$DIR/$_cname")
    for _cf_existing in "${CONTRIB_FILES[@]+"${CONTRIB_FILES[@]}"}"; do
      [[ "$_cf_existing" == "$_cf_real" ]] && _cf_dup=true && break
    done
    $_cf_dup || CONTRIB_FILES+=("$_cf_real")
  done
fi

if [[ "$MODE" == "contrib" ]] && (( ${#CONTRIB_FILES[@]} == 0 )); then
  echo "${YELLOW}hdi: no contributor docs found in ${DIR}${RESET}" >&2
  echo "${DIM}Looked for CONTRIBUTING.md, DEVELOPMENT.md, DEVELOPERS.md, HACKING.md${RESET}" >&2
  exit 1
fi
