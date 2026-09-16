#!/usr/bin/env bash
# Build the compiled parts of the shell into ~/.local/lib/ricistrice, user-local
# and without sudo. dotfiles/quickshell is caelestia's QML, and it imports two
# C++ QML modules that Ubuntu doesn't package:
#
#   libcava    LukashonakV/cava as a library  -> lib/          (the plugin links it)
#   m3shapes   soramanew/m3shapes             -> qml/M3Shapes
#   caelestia  caelestia-dots/shell plugin    -> qml/Caelestia, caelestia/ (version helper)
#
# dotfiles/hypr/hyprland/env.lua points QML_IMPORT_PATH and CAELESTIA_LIB_DIR
# at that folder. Sources are cloned at the pinned commits below into
# ~/.cache/ricistrice/build; delete ~/.local/lib/ricistrice to undo everything.
#
# Safe to re-run: a part already built at the same pin and Qt version is
# skipped, so after an apt upgrade of Qt only a re-run is needed. Build deps are
# in packages.txt; run scripts/bootstrap.sh first.
#
# usage: build-shell.sh [--force]     --force rebuilds everything
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# The caelestia pin must match the commit dotfiles/quickshell was copied from
# (see the header of dotfiles/quickshell/shell.qml): the QML and the plugin
# change together upstream. Bump both at once.
libcava_repo=https://github.com/LukashonakV/cava.git
libcava_rev=f03278ef9e5e7948fb206453d2f02758f8db216c   # tag 1.0.0
m3shapes_repo=https://github.com/soramanew/m3shapes.git
m3shapes_rev=32ad9ce328bb77ed349b40a3be10ee9ea610b8ab
caelestia_repo=https://github.com/caelestia-dots/shell.git
caelestia_rev=0f1435a2f5f0c6ad25a2858f282eee1a0453d8b0

prefix="$HOME/.local/lib/ricistrice"
build_root="${XDG_CACHE_HOME:-$HOME/.cache}/ricistrice/build"
stamps="$prefix/.built"   # inside prefix, so deleting prefix forgets the builds too

force=0
if [ "${1:-}" = "--force" ]; then
  force=1
fi

missing=()
for tool in git cmake ninja meson pkg-config g++; do
  command -v "$tool" >/dev/null || missing+=("$tool")
done
pkg-config --exists Qt6Core 2>/dev/null || missing+=("Qt6 dev files")
[ ${#missing[@]} -eq 0 ] || die "missing ${missing[*]}; run scripts/bootstrap.sh first"
qt_version="$(pkg-config --modversion Qt6Core)"

# up_to_date NAME STAMP: true if NAME was last built with exactly STAMP
up_to_date() {
  [ "$force" -eq 0 ] && [ "$(cat "$stamps/$1" 2>/dev/null)" = "$2" ]
}

mark_built() {
  mkdir -p "$stamps"
  printf '%s\n' "$2" >"$stamps/$1"
}

# fetch NAME REPO REV: clone (once) and check out REV; prints the source dir
fetch() {
  local src="$build_root/$1/src"
  if [ ! -d "$src/.git" ]; then
    git clone --quiet "$2" "$src" >&2
  fi
  if ! git -C "$src" cat-file -e "$3^{commit}" 2>/dev/null; then
    git -C "$src" fetch --quiet --tags origin >&2
  fi
  git -C "$src" -c advice.detachedHead=false checkout --quiet "$3" >&2
  printf '%s\n' "$src"
}

# fresh_build_dir NAME: an empty build folder (it's only cache)
fresh_build_dir() {
  local build="$build_root/$1/build"
  rm -rf "$build"
  printf '%s\n' "$build"
}

build_libcava() {
  local stamp="$libcava_rev"
  if up_to_date libcava "$stamp"; then
    say ok "libcava (built at ${libcava_rev:0:7})"
    return
  fi
  say build "libcava ${libcava_rev:0:7}"
  local src build
  src="$(fetch libcava "$libcava_repo" "$libcava_rev")"
  build="$(fresh_build_dir libcava)"
  meson setup "$build" "$src" --prefix "$prefix" --libdir lib --buildtype release -Dbuild_target=lib
  meson compile -C "$build"
  meson install -C "$build"
  mark_built libcava "$stamp"
}

build_m3shapes() {
  local stamp="$m3shapes_rev qt$qt_version"
  if up_to_date m3shapes "$stamp"; then
    say ok "m3shapes (built at ${m3shapes_rev:0:7}, Qt $qt_version)"
    return
  fi
  say build "m3shapes ${m3shapes_rev:0:7}"
  local src build
  src="$(fetch m3shapes "$m3shapes_repo" "$m3shapes_rev")"
  build="$(fresh_build_dir m3shapes)"
  # $ORIGIN: the plugin finds its backing library installed next to it
  cmake -S "$src" -B "$build" -G Ninja -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$prefix" -DINSTALL_QMLDIR=qml -DCMAKE_INSTALL_RPATH='$ORIGIN'
  cmake --build "$build"
  cmake --install "$build"
  mark_built m3shapes "$stamp"
}

build_caelestia() {
  # Rebuilt when libcava changes too, since it links against it
  local stamp="$caelestia_rev libcava-$libcava_rev qt$qt_version"
  if up_to_date caelestia "$stamp"; then
    say ok "caelestia plugin (built at ${caelestia_rev:0:7}, Qt $qt_version)"
    return
  fi
  say build "caelestia plugin ${caelestia_rev:0:7}"
  local src build
  src="$(fetch caelestia "$caelestia_repo" "$caelestia_rev")"
  build="$(fresh_build_dir caelestia)"
  # Only the plugin and version helper: the QML ("shell" module) comes from
  # dotfiles/quickshell instead. The rpath lets it find libcava in $prefix/lib.
  # -I$prefix/include: the plugin includes <cava/cavacore.h>, but libcava.pc
  # only adds include/cava. Installed to /usr (as on Arch) that works anyway,
  # since /usr/include is always searched; in our prefix it has to be added.
  PKG_CONFIG_PATH="$prefix/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}" \
    cmake -S "$src" -B "$build" -G Ninja -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS="-I$prefix/include" \
    -DCMAKE_INSTALL_PREFIX="$prefix" -DENABLE_MODULES="extras;plugin" \
    -DINSTALL_QMLDIR=qml -DINSTALL_LIBDIR=caelestia \
    -DCMAKE_INSTALL_RPATH="$prefix/lib" -DDISTRIBUTOR=RicistRice
  cmake --build "$build"
  cmake --install "$build"
  mark_built caelestia "$stamp"
}

build_libcava
build_m3shapes
build_caelestia

# Every installed library should resolve all of its dependencies
unresolved=0
while IFS= read -r lib; do
  if ldd "$lib" 2>/dev/null | grep -q 'not found'; then
    say FAIL "$lib has unresolved libraries:"
    ldd "$lib" | grep 'not found' | sed 's/^/         /'
    unresolved=1
  fi
done < <(find "$prefix" -name '*.so*' -type f)
[ "$unresolved" -eq 0 ] || die "some libraries in $prefix can't load"

echo
echo "Shell plugin ready in $prefix."
echo "Hyprland sets QML_IMPORT_PATH/CAELESTIA_LIB_DIR from dotfiles/hypr/hyprland/env.lua after a deploy and re-login."
