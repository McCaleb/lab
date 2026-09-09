#!/usr/bin/env bash
#
# Logs the Bitwarden (bw) CLI in with a personal API key, unlocks the vault, syncs it, then prints the export line for BW_SESSION.
#
# Required in the env:
#   BW_CLIENTID       personal API key client_id
#   BW_CLIENTSECRET   personal API key client_secret
#   BW_PASSWORD       master password (login authenticates, only the master
#                     password can decrypt, so both are needed)
#
# Optional:
#   BW_SERVER         defaults to the Bitwarden cloud
#
# Usage:
#   eval "$(scripts/bw-session.sh)"
#
# The session key is printed on stdout (Maybe use eval so it goes straight into the shell environment rather than your terminal history). 
# Session keys have no TTL. Per Bitwarden's CLI docs they stay valid until
# 'bw lock' or 'bw logout'. (Some people see a ~1 hour lock, which is a
# reported bug tied to the web vault logout setting, not a session TTL.)

set -euo pipefail

if [ -z "${BW_CLIENTID:-}" ]; then
    echo "BW_CLIENTID is not set" >&2
    exit 1
fi

if [ -z "${BW_CLIENTSECRET:-}" ]; then
    echo "BW_CLIENTSECRET is not set" >&2
    exit 1
fi

if [ -z "${BW_PASSWORD:-}" ]; then
    echo "BW_PASSWORD is not set" >&2
    exit 1
fi

BW_SERVER="${BW_SERVER:-https://vault.bitwarden.com}"

bw config server "$BW_SERVER" > /dev/null

if bw status | grep -q '"status":"unauthenticated"'; then
    bw login --apikey > /dev/null
fi

session="$(bw unlock --passwordenv BW_PASSWORD --raw)"

BW_SESSION="$session" bw sync > /dev/null

echo "export BW_SESSION=$session"
