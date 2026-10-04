#!/usr/bin/env bash
#
# StartDump.sh — dump every partition listed in /dev/block/bootdevice/by-name
# Shell counterpart of StartDump.bat
#
# Usage: ./StartDump.sh [n|s]
#   (no argument)  ask before extracting each partition
#   s              extract everything, fetch a fresh partition list
#   n              extract everything, reuse cached ROMbkp/by-name.txt

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ROM_DIR="$SCRIPT_DIR/ROMbkp"
BY_NAME="$ROM_DIR/by-name.txt"

usage() {
    cat <<EOF
Usage: $(basename "$0") [n|s]
  (no argument)  ask before extracting each partition
  s              extract everything, fetch a fresh partition list
  n              extract everything, reuse cached ROMbkp/by-name.txt
EOF
}

pause() {
    if [ -t 0 ]; then
        read -rp "Press Enter to continue... " _ || true
    fi
}

die() {
    printf '%s\n' "$@"
    echo "Program exited."
    pause
    exit 1
}

find_adb() {
    if [ -x "$SCRIPT_DIR/adb" ]; then
        ADB="$SCRIPT_DIR/adb"
    elif command -v adb >/dev/null 2>&1; then
        ADB="$(command -v adb)"
    else
        die "Error: adb not found. Install android-platform-tools or put an executable 'adb' in $SCRIPT_DIR."
    fi
}

errls() {
    die "Error: Cannot read partition list( /dev/block/bootdevice/by-name ) from phone." \
        'Note: "error: no devices/emulators found" means adb is unable to detect phone which caused this error.'
}

valid_listing() {
    [ -s "$BY_NAME" ] || return 1
    # a failed ls prints "ls: ..." - adb merges remote stderr into the file
    ! grep -q -m1 -E '^ls(:|$)' "$BY_NAME" 2>/dev/null
}

fetch_listing() {
    local err rc=0
    err="$(mktemp)"
    "$ADB" shell "ls -1 /dev/block/bootdevice/by-name" >"$BY_NAME" 2>"$err" || rc=$?
    if [ -s "$err" ]; then
        cat "$err" >&2
    fi
    rm -f -- "$err"
    [ "$rc" -eq 0 ] || return 1
    valid_listing
}

main() {
    local mode="${1:-}"
    case "$mode" in
        -h | --help)
            usage
            exit 0
            ;;
    esac

    find_adb
    "$ADB" start-server || true

    bash "$SCRIPT_DIR/clean.sh"
    mkdir -p "$ROM_DIR"

    local fresh=0
    if [ "$mode" = "n" ] && [ -s "$BY_NAME" ]; then
        : # 'n' with a usable cache: keep the cached list
    else
        fetch_listing || errls
        fresh=1
    fi

    if ! valid_listing; then
        if [ "$fresh" -eq 1 ]; then
            errls # freshly fetched listing is still broken
        fi
        # cached list is stale/broken: fetch once and re-check
        fetch_listing || errls
        valid_listing || errls
    fi

    local part rc=0
    while IFS= read -r part || [ -n "$part" ]; do
        part="${part%$'\r'}"
        if [ -z "$part" ]; then
            continue
        fi
        if ! bash "$SCRIPT_DIR/getimg.sh" "$part" "$mode"; then
            rc=1
        fi
    done <"$BY_NAME"

    if [ "$rc" -ne 0 ]; then
        echo .
        echo "Error occured."
    fi
    echo "Program exited."
    pause
    exit "$rc"
}

main "$@"
