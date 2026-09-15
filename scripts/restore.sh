#!/usr/bin/env bash
# Put back the configs saved in a backup. With no argument, uses the newest
# one, i.e. undoes the last deploy. What's live now gets backed up first, so
# running restore.sh a second time undoes the restore.
#
# usage: restore.sh [--list | <backup>]     e.g. restore.sh 20260915-201500
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

backups=("$backup_root"/*/)
[ ${#backups[@]} -gt 0 ] || die "no backups in $backup_root"

if [ "${1:-}" = "--list" ]; then
  for b in "${backups[@]}"; do
    contents=("$b"*)
    printf '%s  %s\n' "$(basename "$b")" "$(printf '%s ' "${contents[@]##*/}")"
  done
  exit 0
fi

# Timestamps sort chronologically, so the last glob match is the newest.
pick="${1:-$(basename "${backups[-1]}")}"
backup="$backup_root/$pick"
[ -d "$backup" ] || die "no such backup: $pick (see restore.sh --list)"

say restore "from $backup"
for item in "$backup"/*; do
  replace_live "$(basename "$item")" "$item"
done

echo
"$scripts_dir/reload.sh"
