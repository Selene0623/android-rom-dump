#!/usr/bin/env bash
#
# clean.sh — remove images previously dumped into ROMbkp/
# Shell counterpart of clean.bat

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ROM_DIR="$SCRIPT_DIR/ROMbkp"

echo "Cleaning previous data..."
rm -f -- "$ROM_DIR"/*.img
