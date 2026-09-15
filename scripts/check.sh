#!/usr/bin/env bash
# Validate the repo without touching ~/.config: every shell script parses (and
# passes shellcheck, if installed) and Hyprland accepts dotfiles/hypr.
# Exits non-zero if anything fails. deploy.sh and commit-push.sh run this first.
#
# usage: check.sh
set -uo pipefail   # no -e: keep going so every problem shows up in one run
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

failed=0
fail() { say FAIL "$1"; failed=1; }
indent() { sed 's/^/         /'; }

# --- Shell scripts -----------------------------------------------------------
have_shellcheck=0
if command -v shellcheck >/dev/null; then
  have_shellcheck=1
else
  say skip "shellcheck not installed, syntax check only (sudo apt install shellcheck)"
fi

mapfile -t scripts < <(find "$repo_dir" \( -path "$repo_dir/refs" -o -path "$repo_dir/.git" \) -prune \
  -o -type f -name '*.sh' -print | sort)

for f in "${scripts[@]}"; do
  rel="${f#"$repo_dir"/}"
  if ! out="$(bash -n "$f" 2>&1)"; then
    fail "$rel (syntax error)"
    printf '%s\n' "$out" | indent
  elif [ "$have_shellcheck" -eq 1 ] && ! out="$(shellcheck -x -P SCRIPTDIR -S warning "$f" 2>&1)"; then
    fail "$rel (shellcheck)"
    printf '%s\n' "$out" | indent
  else
    say pass "$rel"
  fi
done

# --- Hyprland ----------------------------------------------------------------
hypr_conf="$dotfiles_dir/hypr/hyprland.conf"
if [ ! -f "$hypr_conf" ]; then
  say skip "dotfiles/hypr/hyprland.conf (not present)"
elif ! command -v Hyprland >/dev/null; then
  say skip "dotfiles/hypr/hyprland.conf (Hyprland not installed)"
elif out="$(Hyprland --verify-config -c "$hypr_conf" 2>&1)"; then
  say pass "dotfiles/hypr/hyprland.conf"
else
  fail "dotfiles/hypr/hyprland.conf"
  grep '^Config error' <<<"$out" | indent
fi

# Relative sources resolve next to the file being checked, so they verify the
# repo's copy. Absolute ~/.config ones would silently verify the live copy.
if [ -d "$dotfiles_dir/hypr" ] &&
   grep -rnE '^\s*source\s*=\s*(~|\$HOME)/\.config/hypr/' "$dotfiles_dir/hypr" >/dev/null; then
  say warn "dotfiles/hypr sources ~/.config/hypr/... (checks the live copy, not the repo; use ./file.conf)"
fi

echo
if [ "$failed" -eq 0 ]; then
  echo "All checks passed."
else
  echo "Some checks failed."
  exit 1
fi
