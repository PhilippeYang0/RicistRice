#!/usr/bin/env bash
# Force-close the focused window, like "End task" on Windows. Super+Q only
# asks the app to close, which does nothing when the app is hung; this sends
# SIGKILL to the window's process and to everything that process started
# (Electron helpers, wine/Proton children), which the app can't ignore.
#
# Bound to Super+Shift+Q in hypr/variables.lua. For a window that isn't focused
# there is Hyprland's own click-to-kill mode (Ctrl+Super+Q, `hyprctl kill`).
#
# usage: force-kill.sh
set -euo pipefail

info=$(hyprctl activewindow -j)
pid=$(jq -r '.pid // empty' <<<"$info")
class=$(jq -r '.class // "window"' <<<"$info")

# Nothing focused: hyprctl prints {} and there is no pid
[[ $pid =~ ^[0-9]+$ ]] && ((pid > 1)) || exit 0

# Never take the compositor or the shell down with a window
case "$(cat "/proc/$pid/comm" 2>/dev/null || true)" in
Hyprland | qs | quickshell) exit 0 ;;
esac

# Children first, so a dying parent can't respawn them
descendants() {
    local child
    for child in $(pgrep -P "$1" || true); do
        descendants "$child"
        echo "$child"
    done
}

mapfile -t pids < <(
    descendants "$pid"
    echo "$pid"
)
kill -KILL "${pids[@]}" 2>/dev/null || true

notify-send -a force-kill "Force closed" "$class (pid $pid)" 2>/dev/null || true
