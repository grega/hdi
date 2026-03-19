
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

if [[ -z "$README" ]]; then
  echo "${YELLOW}No README found in ${DIR}${RESET}" >&2
  exit 1
fi
