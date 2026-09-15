#!/usr/bin/env bash
# Show how the live ~/.config differs from dotfiles/, i.e. exactly what
# deploy.sh would change. In the diff, - lines are live and + lines are the
# repo. Read-only. Exits 1 if anything differs.
#
# usage: diff.sh [name...]
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

resolve_targets "$@"

differs=0
for name in "${names[@]}"; do
  target="$config_dir/$name"
  if is_deployed "$name"; then
    say same "$target"
    continue
  fi

  differs=1
  if [ -L "$target" ]; then
    say link "$target is a symlink (deploy replaces it with a real copy)"
  elif [ ! -e "$target" ]; then
    say new "$target (not deployed yet)"
  else
    say differs "$target"
    diff -ru --color=auto "$target" "$dotfiles_dir/$name" || true
  fi
done

exit "$differs"
