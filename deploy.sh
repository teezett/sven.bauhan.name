#!/usr/bin/env bash
# Baut die Seite und lädt output/ per SFTP auf den IONOS-Webspace.
# Zugangsdaten stehen in .deploy.env (nicht im Repository), siehe .deploy.env.example
set -euo pipefail
cd "$(dirname "$0")"

[ -f .deploy.env ] || { echo "Fehlt: .deploy.env (Vorlage: .deploy.env.example)" >&2; exit 1; }
# shellcheck disable=SC1091
source .deploy.env
: "${DEPLOY_HOST:?}" "${DEPLOY_USER:?}" "${DEPLOY_PATH:?}"

command -v lftp >/dev/null || { echo "lftp fehlt: brew install lftp" >&2; exit 1; }

rm -rf output
jbake -b

# --dry-run zeigt nur, was passieren würde
FLAGS="--reverse --delete --verbose"
[ "${1:-}" = "--dry-run" ] && FLAGS="$FLAGS --dry-run"

lftp -e "set sftp:auto-confirm yes; mirror $FLAGS output '$DEPLOY_PATH'; bye" \
     "sftp://$DEPLOY_USER@$DEPLOY_HOST"
