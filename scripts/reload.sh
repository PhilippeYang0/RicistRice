#!/usr/bin/env bash
# Tell running components (Hyprland, Quickshell) to re-read their config. Safe to run anytime:
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

# A running Hyprland keeps the config format it started with. If that file is
# gone (the first deploy after hyprland.conf became hyprland.lua, or a restore
# going back), a reload would find it missing and write a default config in its
# place. Skip the reload; the deployed config applies at next login.
provider="$(hyprctl systeminfo 2>/dev/null | sed -n 's/^configProvider: //p')"
case "$provider" in
  lua) session_conf="$config_dir/hypr/hyprland.lua" ;;
  *) session_conf="$config_dir/hypr/hyprland.conf" ;;
esac

if [ ! -f "$session_conf" ]; then
  say skip "Hyprland (this session runs $(basename "$session_conf"), which is gone now: log out and back in)"
elif hyprctl reload >/dev/null; then
  say reload "Hyprland"
  errors="$(hyprctl configerrors)"
  if [ -n "${errors//[[:space:]]/}" ]; then
    say warn "Hyprland reports config errors:"
    printf '%s\n' "$errors"
  fi
fi

# Quickshell's own file watcher loses track when the folder is swapped out,
# so restart it instead. If it isn't running (e.g. it crashed at login on a
# config error that this deploy fixes), start it. -n: never start a second copy.
if pgrep -x quickshell >/dev/null || pgrep -x qs >/dev/null; then
  qs kill >/dev/null
  # qs kill only asks the shell to quit. Wait (up to 5s) until it's gone, or
  # -n sees the exiting copy as still running and starts nothing
  for _ in $(seq 50); do
    pgrep -x quickshell >/dev/null || pgrep -x qs >/dev/null || break
    sleep 0.1
  done
  qs -n -d >/dev/null
  say restart "quickshell"
elif [ -f "$config_dir/quickshell/shell.qml" ]; then
  qs -n -d >/dev/null
  say start "quickshell (wasn't running)"
fi
