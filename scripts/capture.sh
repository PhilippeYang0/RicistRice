#!/usr/bin/env bash
# The reverse of deploy.sh: copy the live ~/.config/<name> into dotfiles/<name>.
# Use it after changing a config outside the repo (a settings GUI, a quick live
# edit), or to adopt a new one (capture.sh mako creates dotfiles/mako).
# Refuses to overwrite dotfiles/<name> if it has uncommitted changes, since git
# couldn't bring those back. Review the result with `git diff`, then commit it
# or drop it with `git restore dotfiles/<name>`.
#
# usage: capture.sh [name...]
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

if [ $# -gt 0 ]; then
  names=("$@")
else
  resolve_targets
fi

for name in "${names[@]}"; do
  live="$config_dir/$name"
  dest="$dotfiles_dir/$name"
  # Separate assignment so a git failure stops the script instead of reading
  # as "no uncommitted changes".
  uncommitted="$(git -C "$repo_dir" status --porcelain -- "dotfiles/$name")"

  if [ ! -d "$live" ] || [ -L "$live" ]; then
    say skip "$live (not a real folder)"
  elif [ -d "$dest" ] && is_deployed "$name"; then
    say same "$live"
  elif [ -n "$uncommitted" ]; then
    say skip "dotfiles/$name has uncommitted changes, commit or stash them first"
  else
    mkdir -p "$dest"
    rsync -a --delete "$live/" "$dest/"
    say capture "$live -> $dest"
  fi
done

echo
echo "Review with: git -C \"$repo_dir\" diff -- dotfiles/"
