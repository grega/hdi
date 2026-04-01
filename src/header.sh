#!/usr/bin/env bash
# hdi - "How do I..." - Extracts setup/run/test commands from a README.
#
# Usage:
#   hdi                           Interactive picker - shows all sections (default)
#   hdi install                   Just install/setup commands (aliases: setup, i)
#   hdi run                       Just run/start commands (aliases: start, r)
#   hdi test                      Just test commands (alias: t)
#   hdi deploy                    Just deploy/release commands and platform detection (alias: d)
#   hdi all                       Show all matched sections (currently the default mode)
#   hdi check                     Check if required tools are installed (experimental)
#   hdi [mode] --no-interactive   Print commands without the picker (alias: --ni)
#   hdi [mode] --full             Include prose around commands
#   hdi [mode] --raw              Plain markdown output (no colour, good for piping)
#   hdi --json                    Structured JSON output (includes all sections)
#   hdi [mode] /path              Scan a specific directory
#   hdi [mode] /path/to/file.md   Parse a specific markdown file
#
# Interactive controls:
#   ↑/↓  k/j           Navigate commands
#   Tab/S-Tab          Jump between sections
#   Enter              Execute the highlighted command
#   c                  Copy highlighted command to clipboard
#   q / Esc / Ctrl+C   Quit

set -euo pipefail

# ── Version ─────────────────────────────────────────────────────────────────
VERSION="0.23.1"
