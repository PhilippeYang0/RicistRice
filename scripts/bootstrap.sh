#!/usr/bin/env bash
# Install the apt/PPA dependencies listed in packages.txt. Safe to re-run:
# already-added PPAs and already-installed packages are skipped, so a second
# run with nothing missing never calls sudo.
#
# Never installs anything under [manual] (no clean Ubuntu package): those are
# only reported as found or still TODO, so nothing gets guessed at.
#
# usage: bootstrap.sh [--dry-run]     --dry-run reports what's missing, changes nothing
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

dry_run=0
if [ "${1:-}" = "--dry-run" ]; then
  dry_run=1
fi

manifest="$repo_dir/packages.txt"
[ -f "$manifest" ] || die "$manifest not found"

section=""
ppas=()
apts=()
manuals=()

while IFS= read -r line; do
  line="${line%%$'\r'}"
  [[ "$line" == \#* ]] && continue
  if [ "$section" != manual ]; then
    line="${line%%#*}"          # inline "# used by ..." comments
  fi
  line="${line%"${line##*[![:space:]]}"}"   # trailing whitespace
  [ -z "$line" ] && continue

  if [[ "$line" == \[*\] ]]; then
    section="${line#[}"
    section="${section%]}"
    continue
  fi

  case "$section" in
    ppa) ppas+=("$line") ;;
    apt) apts+=("$line") ;;
    manual) manuals+=("$line") ;;
    *) die "packages.txt: '$line' is outside a [ppa]/[apt]/[manual] section" ;;
  esac
done < "$manifest"

# --- PPAs --------------------------------------------------------------------
needs_update=0
for ppa in "${ppas[@]}"; do
  ppa_name="${ppa#ppa:}"
  # Ubuntu 24.04+ writes PPAs as deb822 *.sources files; older ones use *.list.
  if grep -qsF "/${ppa_name}/" /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; then
    say ok "$ppa (already added)"
  elif [ "$dry_run" -eq 1 ]; then
    say missing "$ppa"
  else
    say add-ppa "$ppa"
    sudo add-apt-repository -y "$ppa"
    needs_update=1
  fi
done

if [ "$needs_update" -eq 1 ]; then
  sudo apt-get update
fi

# --- apt packages ------------------------------------------------------------
# dpkg -s alone isn't enough: it succeeds for removed packages whose config
# files are still around ("deinstall ok config-files").
is_installed() {
  [ "$(dpkg-query -W -f='${Status}' "$1" 2>/dev/null)" = "install ok installed" ]
}

to_install=()
for pkg in "${apts[@]}"; do
  if is_installed "$pkg"; then
    say ok "$pkg (already installed)"
  else
    say missing "$pkg"
    to_install+=("$pkg")
  fi
done

if [ "${#to_install[@]}" -gt 0 ] && [ "$dry_run" -eq 0 ]; then
  echo
  say install "${to_install[*]}"
  sudo apt-get install -y "${to_install[@]}"
fi

# --- manual installs ---------------------------------------------------------
todo=0
for m in "${manuals[@]}"; do
  name="${m%% ::*}"
  if command -v "$name" >/dev/null; then
    say ok "$name (manual, found at $(command -v "$name"))"
  else
    say todo "$name (manual install, see packages.txt)"
    todo=1
  fi
done

if [ "$dry_run" -eq 1 ] && { [ "${#to_install[@]}" -gt 0 ] || [ "$todo" -eq 1 ]; }; then
  echo
  echo "Dry run: nothing was installed."
  exit 1
fi
