#!/usr/bin/env bash
# hdi - "How do I..." - Extracts setup/run/test commands from a README.
#
# Usage:
#   hdi                           Interactive command picker (default in a terminal)
#   hdi install                   Just install/setup commands
#   hdi run                       Just run/start commands
#   hdi test                      Just test commands
#   hdi deploy                    Just deploy/release commands
#   hdi all                       Show all matched sections
#   hdi check                     Check if required tools are installed (experimental)
#   hdi [mode] --no-interactive   Print commands without the picker
#   hdi [mode] --full             Include prose around commands
#   hdi [mode] --raw              Plain markdown output (no colour, good for piping)
#   hdi --json                     Structured JSON output (includes all sections)
#   hdi [mode] /path              Scan a specific directory
#   hdi [mode] /path/to/file.md   Parse a specific markdown file
#
# Interactive controls:
#   ↑/↓  k/j     Navigate commands
#   Tab/S-Tab    Jump between sections
#   Enter        Execute the highlighted command
#   c            Copy highlighted command to clipboard
#   q / Esc      Quit
#
# Aliases: "install" = "setup" = "i", "run" = "start" = "r", "test" = "t",
#          "deploy" = "d", "check" = "c"

set -euo pipefail

# ── Version ─────────────────────────────────────────────────────────────────
VERSION="0.19.1"
