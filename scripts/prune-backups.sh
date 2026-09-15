#!/usr/bin/env bash
# Delete all but the newest N backups (default 5), printing each one removed.
#
# usage: prune-backups.sh [N]
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

keep="${1:-5}"
[[ "$keep" =~ ^[0-9]+$ ]] || die "N must be a whole number, got: $keep"

backups=("$backup_root"/*/)
count=${#backups[@]}
if [ "$count" -le "$keep" ]; then
  say ok "$count backup(s), nothing to prune (keeping $keep)"
  exit 0
fi

# Oldest first, so everything before the last $keep entries goes.
for b in "${backups[@]:0:count-keep}"; do
  rm -rf "${b%/}"
  say delete "${b%/}"
done
