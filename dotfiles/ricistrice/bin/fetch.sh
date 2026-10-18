#!/usr/bin/env bash
# fastfetch with the current theme's logo, run by the shell at startup
# (dotfiles/zsh/zshrc). The logo is an image, so it's shown only in kitty,
# which can draw images; other terminals get fastfetch's small text logo.
#
# The logo for theme <name> is the first match of
#   ~/Pictures/Logos/<name>.*      (e.g. cozy-pixelated.png)
#   ~/Pictures/Logos/default.*     (every theme without its own)
# Any format ImageMagick reads works (png, webp, jpg, ...); a transparent
# background looks best over the see-through terminal. fastfetch scales it and
# caches the result in ~/.cache/fastfetch, redone when the file changes.
#
# usage: fetch.sh [fastfetch options...]
set -euo pipefail
shopt -s nullglob

logos_dir="${RICISTRICE_LOGOS:-$HOME/Pictures/Logos}"
scheme_file="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/scheme.json"

# The logo's box, in terminal cells: it's fitted inside without stretching,
# so a tall image uses the full height and less than the full width
logo_height=18
logo_width=26

theme=""
if [ -f "$scheme_file" ]; then theme="$(jq -r '.name // ""' "$scheme_file" 2>/dev/null || true)"; fi

logo=""
for candidate in ${theme:+"$logos_dir/$theme".*} "$logos_dir"/default.*; do
  if [ -f "$candidate" ]; then
    logo="$candidate"
    break
  fi
done

if [ -n "$logo" ] && [ "${TERM:-}" = xterm-kitty ]; then
  exec fastfetch --logo-type kitty --logo "$logo" \
    --logo-height "$logo_height" --logo-width "$logo_width" --logo-preserve-aspect-ratio true "$@"
fi
exec fastfetch "$@"
