#!/usr/bin/env bash
#
# Bind the SOPS textconv diff drivers named in .gitattributes.
#

set -euo pipefail

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Not inside a git work tree. Run this from within the repo." >&2
    exit 1
fi

if ! command -v sops >/dev/null 2>&1; then
    echo "SOPS is not on PATH or is not installed." >&2
    exit 1
fi

# --input-type isn't optional. 
git config --local diff.sopsdiffer-yaml.textconv "sops decrypt --input-type yaml --output-type yaml"
git config --local diff.sopsdiffer-json.textconv "sops decrypt --input-type json --output-type json"
git config --local diff.sopsdiffer-env.textconv "sops decrypt --input-type dotenv --output-type dotenv"

echo "Bound 3 textconv drivers in $(git rev-parse --show-toplevel)"
echo "Check with: git config --local --get-regexp '^diff\.sopsdiffer'"
