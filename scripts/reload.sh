#!/usr/bin/env bash
# Tell running components to re-read their config. Safe to run anytime:
# anything not running is skipped. deploy.sh and restore.sh call this.
#
# usage: reload.sh
set -uo pipefail
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
  say skip "not in a Hyprland session, changes apply at next login"
  exit 0
fi

if hyprctl reload >/dev/null; then
  say reload "Hyprland"
  errors="$(hyprctl configerrors)"
  if [ -n "${errors//[[:space:]]/}" ]; then
    say warn "Hyprland reports config errors:"
    printf '%s\n' "$errors"
  fi
fi

if pgrep -x waybar >/dev/null; then
  pkill -SIGUSR2 -x waybar
  say reload "waybar"
fi

# Quickshell's own file watcher loses track when the folder is swapped out,
# so restart it instead.
if pgrep -x quickshell >/dev/null || pgrep -x qs >/dev/null; then
  qs kill >/dev/null
  qs -d >/dev/null
  say restart "quickshell"
fi
