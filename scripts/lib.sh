# shellcheck shell=bash
# shellcheck disable=SC2034  # variables here are used by the scripts that source this file
# Shared paths and helpers for scripts/*.sh and manage.sh. Source it, don't run it.

shopt -s nullglob

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(dirname "$scripts_dir")"
dotfiles_dir="$repo_dir/dotfiles"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"

# Every deploy/restore gets one timestamped folder here holding the live
# configs it replaced, so nothing in ~/.config is ever lost, only moved.
backup_root="${XDG_STATE_HOME:-$HOME/.local/state}/ricistrice/backups"
run_backup_dir="$backup_root/$(date +%Y%m%d-%H%M%S)"

say() { printf '%-8s %s\n' "$1" "$2"; }   # say ok "~/.config/hypr (up to date)"
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

confirm() {
  local reply
  read -rp "$1 [y/N] " reply || return 1
  [[ "$reply" =~ ^[Yy]$ ]]
}

# Fills the global array `names` with the configs to act on: the ones passed
# as arguments, or else every folder in dotfiles/. Scaffold folders holding
# only .gitkeep are skipped so they never replace a working config with nothing.
resolve_targets() {
  names=()
  local name src candidates=("$@")
  if [ ${#candidates[@]} -eq 0 ]; then
    for src in "$dotfiles_dir"/*/; do
      candidates+=("$(basename "$src")")
    done
  fi
  for name in "${candidates[@]}"; do
    [ -d "$dotfiles_dir/$name" ] || die "no such config: dotfiles/$name"
    if [ -z "$(find "$dotfiles_dir/$name" -mindepth 1 ! -name .gitkeep -print -quit)" ]; then
      say skip "dotfiles/$name (no content yet)"
    else
      names+=("$name")
    fi
  done
}

# True if ~/.config/<name> is a real folder identical to dotfiles/<name>.
is_deployed() {
  local target="$config_dir/$1"
  [ ! -L "$target" ] && diff -rq "$dotfiles_dir/$1" "$target" >/dev/null 2>&1
}

# Replaces ~/.config/<name> with a copy of <source>, first moving whatever was
# there into this run's backup folder.
replace_live() {
  local name="$1" source="$2" target="$config_dir/$1"
  local staging="$target.ricistrice-new"

  # Copy to a staging folder first so the live config is only missing for the
  # instant between the two mv calls below.
  rm -rf "$staging"
  cp -a "$source" "$staging"

  if [ -e "$target" ] || [ -L "$target" ]; then
    mkdir -p "$run_backup_dir"
    mv "$target" "$run_backup_dir/$name"
    say backup "$target -> $run_backup_dir/$name"
  fi

  mv "$staging" "$target"
  say copy "$source -> $target"
}
