#!/usr/bin/env bash
#
# Verify a SOPS-encrypted file before you trust it or commit it.
#
#   ./verify.sh <file> [file...]
#   ./verify.sh -d <file>     also decrypt to stdout, which prints secrets
#
# Per file:
#   1. sops says the file is encrypted        (needs sops 3.9+ for filestatus)
#   2. how many age recipients can open it
#   3. git is not ignoring it
#

set -uo pipefail

usage() {
    cat <<'USAGE'
Usage: verify.sh [-d] <file> [file...]

  -d   also decrypt each file to stdout (prints secrets)
  -h   this message
USAGE
}

decrypt=0
while getopts ":dh" opt; do
    case "$opt" in
        d) decrypt=1 ;;
        h) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done
shift $((OPTIND - 1))

if [ "$#" -eq 0 ]; then
    usage >&2
    exit 2
fi

if ! command -v sops >/dev/null 2>&1; then
    echo "SOPS is not on PATH or not installed." >&2
    exit 1
fi

rc=0

for f in "$@"; do
    echo "== $f"

    if [ ! -f "$f" ]; then
        echo "   file:        MISSING"
        rc=1
        continue
    fi

    status=$(sops filestatus "$f" 2>&1)
    if printf '%s' "$status" | grep -qE '"encrypted":[[:space:]]*true'; then
        echo "   encrypted:   yes"
    elif printf '%s' "$status" | grep -qE '"encrypted":[[:space:]]*false'; then
        echo "   encrypted:   NO, this file is plaintext"
        rc=1
    else
        echo "   encrypted:   unknown, sops filestatus said: $status"
        rc=1
    fi

    case "$f" in
        *.env)  pattern='map_recipient=age1' ;;
        *.json) pattern='"recipient":[[:space:]]*"age1' ;;
        *)      pattern='recipient:[[:space:]]*age1' ;;
    esac
    count=$(grep -cE "$pattern" "$f" || true)
    echo "   recipients:  $count"
    if [ "$count" -eq 0 ]; then
        rc=1
    fi

    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        if git check-ignore -q "$f"; then
            echo "   git:         IGNORED, this file will not be committed"
            rc=1
        else
            echo "   git:         not ignored"
        fi
    fi

    if [ "$decrypt" -eq 1 ]; then
        echo "   --- decrypted ---"
        sops decrypt "$f" || rc=1
    fi
done

exit "$rc"
