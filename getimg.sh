#!/usr/bin/env bash
#
# getimg.sh — dump one partition from /dev/block/bootdevice/by-name into ROMbkp/
# Shell counterpart of getimg.bat
#
# Usage: ./getimg.sh <partition> [s|n]
#   s | n   extract without prompting (StartDump.sh passes its own flag through)
#   other   ask before extracting

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ROM_DIR="$SCRIPT_DIR/ROMbkp"

pause() {
    if [ -t 0 ]; then
        read -rp "Press Enter to continue... " _ || true
    fi
}

find_adb() {
    if [ -x "$SCRIPT_DIR/adb" ]; then
        ADB="$SCRIPT_DIR/adb"
    elif command -v adb >/dev/null 2>&1; then
        ADB="$(command -v adb)"
    else
        echo "Error: adb not found. Install android-platform-tools or put an executable 'adb' in $SCRIPT_DIR."
        pause
        exit 1
    fi
}

main() {
    local partition="${1:-}"
    local mode="${2:-}"

    if [ -z "$partition" ]; then
        echo "Error: No arguments supplied"
        pause
        exit 1
    fi

    # the partition name becomes a file name: reject path separators / whitespace
    if [[ "$partition" == */* || "$partition" == *\\* || "$partition" == *[[:space:]]* ]]; then
        echo "Error: '$partition' does not look like a valid partition name."
        pause
        exit 1
    fi

    mkdir -p "$ROM_DIR"
    find_adb

    local extract_now=0
    case "$mode" in
        s | n) extract_now=1 ;;
    esac

    local yn
    if [ "$extract_now" -eq 0 ]; then
        if [ ! -t 0 ]; then
            echo "Error: cannot prompt for '$partition' (no terminal). Pass 's' or 'n' as the second argument."
            exit 1
        fi
        while :; do
            echo .
            yn=""
            if ! read -rp "Do you want to extract $partition (y/n)? " yn; then
                echo
                exit 1
            fi
            case "$yn" in
                [yY]) extract_now=1; break ;;
                [nN]) exit 0 ;;
            esac
        done
    fi

    local img="$ROM_DIR/$partition.img"
    local txt="$ROM_DIR/$partition.txt"
    local err status=0
    err="$(mktemp)"

    echo
    # adb merges remote dd errors into stdout (they land in $img);
    # adb's own errors go to $err. Catch both, plus a missing exit code.
    "$ADB" shell "dd if=/dev/block/bootdevice/by-name/$partition" >"$img" 2>"$err" || status=$?

    if [ "$status" -ne 0 ] || [ ! -s "$img" ] ||
        grep -a -q -m1 '^dd:' "$img" 2>/dev/null ||
        grep -q -m1 '^dd:' "$err" 2>/dev/null; then
        mv -f -- "$img" "$txt"
        if [ -s "$err" ]; then
            cat "$err" >>"$txt"
        elif [ ! -s "$txt" ]; then
            printf 'dd failed with no output (adb exit status %s) for /dev/block/bootdevice/by-name/%s\n' \
                "$status" "$partition" >>"$txt"
        fi
        rm -f -- "$err"
        echo
        echo "Error: Cannot dump '$partition'"
        echo "Read 'ROMbkp/$partition.txt' for more info."
        pause
        exit 1
    fi

    if [ -s "$err" ]; then
        cat "$err" >&2
    fi
    rm -f -- "$err"

    echo .
    echo "'$partition' successfully written to 'ROMbkp/$partition.img'."
}

main "$@"
