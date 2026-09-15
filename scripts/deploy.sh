#!/usr/bin/env bash
# Copy dotfiles/<name> to ~/.config/<name> for every config (or only the ones
# named), once check.sh passes. Whatever was live is moved into a timestamped
# backup first, so restore.sh can undo this. Configs already identical to the
# repo are left alone, so re-running is safe.
#
# usage: deploy.sh [--no-check] [name...]     e.g. deploy.sh hypr
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

run_check=1
if [ "${1:-}" = "--no-check" ]; then
  run_check=0
  shift
fi

resolve_targets "$@"
[ ${#names[@]} -gt 0 ] || die "nothing to deploy"

if [ "$run_check" -eq 1 ]; then
  "$scripts_dir/check.sh" || die "check failed, nothing deployed (--no-check skips it)"
  echo
fi

changed=0
for name in "${names[@]}"; do
  if is_deployed "$name"; then
    say ok "$config_dir/$name (up to date)"
  else
    replace_live "$name" "$dotfiles_dir/$name"
    changed=1
  fi
done

if [ "$changed" -eq 1 ]; then
  echo
  "$scripts_dir/reload.sh"
fi
