#!/usr/bin/env bash
# Install hdi to ~/.local/bin
set -euo pipefail

INSTALL_DIR="${HDI_INSTALL_DIR:-$HOME/.local/bin}"
REPO="grega/hdi"
BRANCH="main"
URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/hdi"

mkdir -p "$INSTALL_DIR"

echo "Installing hdi to ${INSTALL_DIR}..."
curl -fsSL "$URL" -o "${INSTALL_DIR}/hdi"
chmod +x "${INSTALL_DIR}/hdi"

if [[ ":$PATH:" != *":${INSTALL_DIR}:"* ]]; then
  echo ""
  echo "⚠  ${INSTALL_DIR} is not on your \$PATH."
  echo "   Add this to your shell config:"
  echo ""
  echo "   export PATH=\"${INSTALL_DIR}:\$PATH\""
  echo ""
else
  echo "✓ Done. Run 'hdi' in any project with a README."
fi
