#!/usr/bin/env bash
# Theme switcher for the RicistRice shell: wallpaper through awww, colours
# through matugen. It stands in for the two caelestia CLI commands the shell
# runs, taking the same arguments and printing the same output, so the shell's
# wallpaper and scheme browsers work unchanged (dotfiles/quickshell calls it
# through Paths.themeCmd).
#
# A theme is a wallpaper folder plus a palette, found by name:
#   ~/.config/ricistrice/themes/<name>/<flavour>/<mode>.conf   the palette
#   ~/Pictures/Wallpapers/<name>/                              its wallpapers
# Picking a wallpaper from a theme's folder switches to that theme, and picking
# a theme puts up one of its wallpapers. (caelestia calls a palette a "scheme".)
#
# The theme named "dynamic" is the exception, like caelestia's scheme of that
# name: its colours come from whatever wallpaper is set, from any folder, and
# changing the wallpaper never switches away from it. With smart scheme on (the
# shell's settings toggle; --no-smart turns it off for one run), each new
# wallpaper also picks dynamic's light/dark mode and variant (see smart_opts).
#
# It writes only these files, none of them under ~/.config:
#   ~/.local/state/caelestia/scheme.json          the shell's colours (services/Colours.qml)
#   ~/.local/state/caelestia/wallpaper/path.txt   the shell's wallpaper (services/Wallpapers.qml)
#   ~/.local/state/ricistrice/hypr-colours.lua    Hyprland's colours (hypr/utils/colours.lua)
#
# usage: see usage() below, or run theme.sh with no arguments
set -euo pipefail

script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
themes_dir="$(dirname "$script_dir")/themes"
walls_dir="${RICISTRICE_WALLPAPERS:-$HOME/Pictures/Wallpapers}"

state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
scheme_file="$state_home/caelestia/scheme.json"
wall_file="$state_home/caelestia/wallpaper/path.txt"
hypr_colours="$state_home/ricistrice/hypr-colours.lua"
shell_config="${XDG_CONFIG_HOME:-$HOME/.config}/caelestia/shell.json"

default_theme=cozy-pixelated
dynamic_theme=dynamic # the shell checks for this name (Colours.scheme === "dynamic")
variants=(tonalspot vibrant expressive fidelity fruitsalad monochrome neutral rainbow content)

usage() {
  cat <<'EOF'
usage:
  theme.sh wallpaper                 print the current wallpaper
  theme.sh wallpaper -f FILE         set it (switches theme if FILE is in a theme's folder)
  theme.sh wallpaper -r              random wallpaper from the current theme's folder
  theme.sh wallpaper -p FILE         print the colours FILE would give, change nothing
                                     (the wallpaper commands also take --no-smart)
  theme.sh thumb FILE                print an image standing in for FILE: FILE
                                     itself, or a frame extracted from it (and
                                     cached) when FILE is a video
  theme.sh scheme list               every theme and its colours, as JSON
  theme.sh scheme get [-nfmv]        print name, flavour, mode and/or variant
  theme.sh scheme set [-n NAME] [-f FLAVOUR] [-m MODE] [-v VARIANT] [--notify]
  theme.sh restore                   at login: wait for awww-daemon, reapply everything
EOF
  exit 1
}

die() { printf 'theme.sh: %s\n' "$*" >&2; exit 1; }

# fail TITLE BODY: an error the user should see. With --notify (the shell
# passes it) it also pops up a notification, since nobody reads its stderr.
notify=0
fail() {
  if [ "$notify" -eq 1 ] && command -v notify-send >/dev/null; then
    notify-send -a ricistrice -u critical "$1" "$2"
  fi
  die "$1: $2"
}

# atomic_write FILE < content. The shell watches these files, so write a temp
# file and rename it rather than letting the shell read a half-written one.
atomic_write() {
  mkdir -p "$(dirname "$1")"
  local tmp
  tmp="$(mktemp "$1.XXXXXX")"
  cat >"$tmp"
  mv "$tmp" "$1"
}

contains() {
  local want="$1" x
  shift
  for x in "$@"; do
    [ "$x" = "$want" ] && return 0
  done
  return 1
}

# listed VALUE CMD...: true if CMD prints VALUE as one of its lines. (No grep
# -q: it stops reading early, and pipefail would then count CMD's SIGPIPE.)
listed() {
  local want="$1"
  shift
  "$@" | grep -xF -- "$want" >/dev/null
}

subdirs() {
  local d
  for d in "$1"/*/; do
    if [ -d "$d" ]; then basename "$d"; fi
  done
}
themes()   { subdirs "$themes_dir"; }
flavours() { subdirs "$themes_dir/$1"; }
modes() {
  local f
  for f in "$themes_dir/$1/$2"/*.conf; do
    if [ -f "$f" ]; then basename "$f" .conf; fi
  done
}

# --- Palettes ----------------------------------------------------------------
# A palette file is "key value" lines, # starts a comment. These keys are
# settings; any other key pins that colour role (e.g. "background 1c1714"),
# overriding what matugen generates. See themes/cozy-pixelated/default/dark.conf.
declare -A settings=() overrides=()
setting_keys=(seed variant prefer filter transition)

read_palette() {
  local file="$themes_dir/$1/$2/$3.conf" key value
  [ -f "$file" ] || die "no palette $file"
  settings=()
  overrides=()
  while read -r key value _; do
    key="${key%%#*}"
    [ -n "$key" ] || continue
    value="${value#\#}"
    if contains "$key" "${setting_keys[@]}"; then
      settings[$key]="$value"
    elif [[ "$value" =~ ^[0-9a-fA-F]{6}$ ]]; then
      overrides[$key]="$value"
    else
      printf 'theme.sh: %s: %s is not a colour (rrggbb), ignored\n' "$file" "$key" >&2
    fi
  done <"$file"
}

# The palette's default variant, used until one is picked with `scheme set -v`
palette_variant() {
  read_palette "$1" "$2" "$3"
  printf '%s\n' "${settings[variant]:-tonalspot}"
}

# success* aren't Material roles, so matugen doesn't make them; caelestia's
# default values, which a palette can pin like any other role
success_colours() {
  if [ "$1" = light ]; then
    echo '{"success":"4F6354","onSuccess":"FFFFFF","successContainer":"D1E8D5","onSuccessContainer":"0C1F13"}'
  else
    echo '{"success":"B5CCBA","onSuccess":"213528","successContainer":"374B3E","onSuccessContainer":"D1E9D6"}'
  fi
}

# gen_colours NAME FLAVOUR MODE VARIANT WALLPAPER: print the full colour set as
# one JSON object of role -> "rrggbb", the shape scheme.json uses. matugen
# builds every Material role from the palette's seed colour (or from the
# wallpaper, with "seed wallpaper"), then the palette's pinned roles go on top.
gen_colours() {
  local name="$1" flavour="$2" mode="$3" variant="$4" wall="$5"
  read_palette "$name" "$flavour" "$mode"

  local type="scheme-$variant"
  case "$variant" in
    tonalspot) type=scheme-tonal-spot ;;
    fruitsalad) type=scheme-fruit-salad ;;
  esac

  local seed="${settings[seed]:-wallpaper}" source
  if [ "$seed" = wallpaper ]; then
    [ -f "$wall" ] || fail "No wallpaper" "Theme $name takes its colours from the wallpaper, but none is set"
    # --prefer: an image has several candidate colours; pick without asking
    source=(image "$wall" --prefer "${settings[prefer]:-saturation}")
  else
    source=(color hex "#$seed")
  fi

  local pins key
  pins="$(for key in "${!overrides[@]}"; do printf '%s %s\n' "$key" "${overrides[$key]}"; done |
    jq -Rn '[inputs | split(" ") | {(.[0]): .[1]}] | add // {}')"

  matugen "${source[@]}" -m "$mode" -t "$type" --json hex --dry-run </dev/null |
    jq -c --arg mode "$mode" --argjson success "$(success_colours "$mode")" --argjson pins "$pins" '
      def camel: gsub("_(?<c>[a-z])"; .c | ascii_upcase);
      (.colors | with_entries(.key |= camel | .value |= (.[$mode].color | ltrimstr("#"))))
      + (.palettes | with_entries(
          select(.key | IN("primary", "secondary", "tertiary", "neutral", "neutral_variant"))
          | .key += "_paletteKeyColor"
          | .value |= (.["50"].color | ltrimstr("#"))))
      + $success + $pins'
}

# --- State -------------------------------------------------------------------
# The current theme lives in the shell's scheme.json, so there's one source of
# truth; before the first run it's the default theme.
name="" flavour="" mode="" variant=""

load_state() {
  name="$default_theme" flavour=default mode=dark variant=""
  if [ -f "$scheme_file" ]; then
    { read -r name; read -r flavour; read -r mode; read -r variant; } \
      < <(jq -r '.name // "", .flavour // "", .mode // "", .variant // ""' "$scheme_file")
  fi
}

# Fill in a missing or stale flavour/mode the way caelestia does: fall back to
# the theme's first one. An unknown theme name falls back to the default theme.
check_state() {
  local -a all
  mapfile -t all < <(themes)
  contains "$name" "${all[@]}" || name="$default_theme"
  mapfile -t all < <(flavours "$name")
  [ ${#all[@]} -gt 0 ] || die "theme $name has no palettes in $themes_dir/$name"
  contains "$flavour" "${all[@]}" || flavour="${all[0]}"
  mapfile -t all < <(modes "$name" "$flavour")
  [ ${#all[@]} -gt 0 ] || die "theme $name has no palettes in $themes_dir/$name/$flavour"
  contains "$mode" "${all[@]}" || mode="${all[0]}"
  if [ -z "$variant" ]; then variant="$(palette_variant "$name" "$flavour" "$mode")"; fi
}

current_wall() {
  if [ -f "$wall_file" ]; then cat "$wall_file"; fi
}

# The theme whose wallpaper folder FILE is in, or nothing
theme_for_wallpaper() {
  local rel="${1#"$walls_dir"/}"
  [ "$rel" != "$1" ] || return 0
  local theme="${rel%%/*}"
  if [ "$theme" != "$rel" ] && [ -d "$themes_dir/$theme" ]; then printf '%s\n' "$theme"; fi
}

# random_wallpaper DIR [find options]: a random image under DIR, preferring
# one other than the current wallpaper; nothing if DIR has no images
random_wallpaper() {
  local dir="$1" current w
  shift
  [ -d "$dir" ] || return 0
  current="$(current_wall)"
  local -a walls
  mapfile -t walls < <(find "$dir" "$@" -type f -iregex '.*\.\(png\|jpe?g\|webp\|gif\|bmp\|mp4\|webm\|mkv\)' | shuf)
  for w in "${walls[@]}"; do
    if [ "$w" != "$current" ]; then
      printf '%s\n' "$w"
      return 0
    fi
  done
  if [ ${#walls[@]} -gt 0 ]; then printf '%s\n' "${walls[0]}"; fi
}

# --- Video wallpapers --------------------------------------------------------
# awww draws images and GIFs only, and neither matugen nor ImageMagick can read
# a video at all. So everywhere but playback itself, a video wallpaper is
# represented by one frame extracted from it: awww puts that still up, and the
# colours are generated from it. The shell plays the video on its background
# window, one layer above awww, so the still is what shows while the video
# loads and whenever playback is paused (see modules/background/VideoWallpaper.qml).
# The shell asks for the same frame with `theme.sh thumb`.
video_exts=(mp4 webm mkv)
thumbs_dir="${XDG_CACHE_HOME:-$HOME/.cache}/ricistrice/videothumbs"

is_video() {
  local ext="${1##*.}"
  contains "${ext,,}" "${video_exts[@]}"
}

# extract_still VIDEO OUT: one frame of VIDEO into OUT. Seeks 30% in, capped at
# 4s, so the frame isn't a fade-in from black and a long video stays quick.
extract_still() {
  local duration seek tmp
  duration="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$1" 2>/dev/null)" || duration=""
  seek=0.1
  if [[ "$duration" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    seek="$(jq -rn --argjson d "$duration" 'if $d > 1 then [$d * 0.3, 4] | min else 0.1 end')"
  fi
  mkdir -p "$(dirname "$2")"
  tmp="$(mktemp "$2.XXXXXX")"
  if ffmpeg -y -v error -ss "$seek" -i "$1" -frames:v 1 -q:v 2 -update 1 -f image2 "$tmp" \
       </dev/null >/dev/null 2>&1 && [ -s "$tmp" ]; then
    mv "$tmp" "$2"
    return 0
  fi
  rm -f "$tmp"
  printf 'theme.sh: could not extract a frame from %s (is ffmpeg installed?)\n' "$1" >&2
  return 1
}

# still_of FILE: an image standing in for FILE — FILE itself when it is one,
# otherwise a frame extracted from the video, cached and regenerated whenever
# the video is newer than the frame. Prints nothing for an empty FILE or when
# extraction fails, which leaves callers with the same "no wallpaper" path they
# already handle.
still_of() {
  [ -n "${1:-}" ] || return 0
  if ! is_video "$1"; then
    printf '%s\n' "$1"
    return 0
  fi
  local video thumb
  # Resolved, so the same video reached by different paths is cached once
  video="$(readlink -f "$1")" || return 0
  thumb="$thumbs_dir/$(printf '%s' "$video" | md5sum | cut -d' ' -f1).jpg"
  if [ ! -f "$thumb" ] || [ "$video" -nt "$thumb" ]; then
    extract_still "$video" "$thumb" || return 0
  fi
  printf '%s\n' "$thumb"
}

# Draw FILE with awww, using the current palette's filter and transition, and
# remember it for the shell. awww failing (daemon not up yet) isn't fatal:
# `restore` puts the wallpaper back once it is.
set_wallpaper() {
  read_palette "$name" "$flavour" "$mode"
  # A video's still: awww holds it under the shell's playback (see still_of)
  local drawn
  drawn="$(still_of "$1")"
  if [ -n "$drawn" ]; then
    awww img "$drawn" --filter "${settings[filter]:-Lanczos3}" \
      --transition-type "${settings[transition]:-simple}" --transition-fps 60 ||
      printf 'theme.sh: awww img failed (is awww-daemon running?)\n' >&2
  fi
  # The video itself, not its still: this is what the shell plays and what
  # names the wallpaper everywhere else
  printf '%s\n' "$1" | atomic_write "$wall_file"
}

# Generate the current theme's colours and hand them to the shell and Hyprland.
# Hyprland is only reloaded when its colours actually changed.
apply() {
  local colours hypr
  colours="$(gen_colours "$name" "$flavour" "$mode" "$variant" "$(still_of "$(current_wall)")")"

  jq -n --arg name "$name" --arg flavour "$flavour" --arg mode "$mode" --arg variant "$variant" \
    --argjson colours "$colours" \
    '{name: $name, flavour: $flavour, mode: $mode, variant: $variant, colours: $colours}' |
    atomic_write "$scheme_file"

  hypr="$(jq -r '"-- Written by ricistrice theme.sh from the current theme; do not edit.",
                 "return {", (to_entries[] | "    \(.key) = \"\(.value)\","), "}"' <<<"$colours")"
  if [ ! -f "$hypr_colours" ] || [ "$(cat "$hypr_colours")" != "$hypr" ]; then
    printf '%s\n' "$hypr" | atomic_write "$hypr_colours"
    # Only the Lua config reads these colours, and reloading an older
    # hyprland.conf session after hyprland.lua was deployed would make it
    # write a default config (see scripts/reload.sh)
    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] &&
       hyprctl systeminfo 2>/dev/null | grep -x 'configProvider: lua' >/dev/null; then
      hyprctl reload >/dev/null
    fi
  fi
}

# Switch to theme NAME if FILE sits in its folder; its default variant applies.
# The dynamic theme stays on whatever folder FILE is in.
adopt_theme_of() {
  local theme
  [ "$name" != "$dynamic_theme" ] || return 0
  theme="$(theme_for_wallpaper "$1")"
  if [ -n "$theme" ] && [ "$theme" != "$name" ]; then
    name="$theme" variant=""
  fi
}

# --- Smart scheme ------------------------------------------------------------
# On unless the shell's "Smart colour scheme" toggle is off (or --no-smart)
smart=1
if [ -f "$shell_config" ] &&
   [ "$(jq -r '.services.smartScheme // true' "$shell_config" 2>/dev/null)" = false ]; then
  smart=0
fi

# smart_opts FILE: print "MODE VARIANT" suited to FILE, from two numbers
# ImageMagick measures on a 64x64 thumbnail (first frame of a GIF):
#   lightness  average perceptual lightness (CIELAB L, 0-1): above 0.6 is a
#              bright image, which gets light mode
#   chroma     average colourfulness (HCL C, 0-1): near-grey images get
#              monochrome/neutral so the shell isn't more colourful than the
#              wallpaper, very colourful ones get vibrant
# Thresholds picked by measuring ~/Pictures/Wallpapers (Sept 2026): lightness
# ran 0.10-0.78, chroma 0.015-0.39.
smart_opts() {
  local out lightness chroma
  out="$(magick "$1[0]" -resize '64x64!' -write mpr:w +delete \
    mpr:w -colorspace LAB -format '%[fx:mean.r] ' -write info: +delete \
    mpr:w -colorspace HCL -format '%[fx:mean.g]' info: 2>/dev/null)" || return 1
  read -r lightness chroma <<<"$out"
  jq -rn --argjson l "$lightness" --argjson c "$chroma" '
    (if $l > 0.6 then "light" else "dark" end) + " " +
    (if $c < 0.035 then "monochrome"
     elif $c < 0.09 then "neutral"
     elif $c < 0.25 then "tonalspot"
     else "vibrant" end)'
}

# smart_pick FILE: with smart on and the dynamic theme current, take mode and
# variant from FILE. A mode the theme has no palette for is left as it is.
# A video is measured through its still, like every other image-only step.
smart_pick() {
  [ "$smart" -eq 1 ] && [ "$name" = "$dynamic_theme" ] || return 0
  local img opts new_mode new_variant
  img="$(still_of "${1:-}")"
  [ -n "$img" ] && [ -f "$img" ] || return 0
  if ! opts="$(smart_opts "$img")"; then
    printf 'theme.sh: could not analyse %s, keeping mode and variant\n' "$img" >&2
    return 0
  fi
  read -r new_mode new_variant <<<"$opts"
  if listed "$new_mode" modes "$name" "$flavour"; then mode="$new_mode"; fi
  variant="$new_variant"
}

# --- Commands ----------------------------------------------------------------
cmd_wallpaper() {
  local action="" file=""
  while [ $# -gt 0 ]; do
    case "$1" in
      -f|--file) action=set file="${2:?-f needs a file}"; shift 2 ;;
      -p|--print) action=print file="${2:?-p needs a file}"; shift 2 ;;
      -r|--random) action=random; shift ;;
      --no-smart) smart=0; shift ;; # only the dynamic theme is smart; curated themes set their own mode
      *) usage ;;
    esac
  done

  load_state
  case "$action" in
    "")
      file="$(current_wall)"
      printf '%s\n' "${file:-No wallpaper set}"
      ;;
    print)
      [ -f "$file" ] || die "$file is not a file"
      adopt_theme_of "$file"
      check_state
      smart_pick "$file"
      jq -n --arg name "$name" --arg flavour "$flavour" --arg mode "$mode" --arg variant "$variant" \
        --argjson colours "$(gen_colours "$name" "$flavour" "$mode" "$variant" "$(still_of "$file")")" \
        '{name: $name, flavour: $flavour, mode: $mode, variant: $variant, colours: $colours}'
      ;;
    set | random)
      if [ "$action" = random ]; then
        # From the current theme's folder; failing that, from loose images
        # directly in the wallpaper folder, never from another theme's folder
        # (which would switch themes). The dynamic theme takes any wallpaper.
        check_state
        if [ "$name" = "$dynamic_theme" ]; then
          file="$(random_wallpaper "$walls_dir")"
        else
          file="$(random_wallpaper "$walls_dir/$name")"
          [ -n "$file" ] || file="$(random_wallpaper "$walls_dir" -maxdepth 1)"
        fi
        [ -n "$file" ] || die "no wallpapers in $walls_dir/$name or directly in $walls_dir"
      fi
      [ -f "$file" ] || die "$file is not a file"
      file="$(readlink -f "$file")"
      adopt_theme_of "$file"
      check_state
      smart_pick "$file"
      set_wallpaper "$file"
      apply
      ;;
  esac
}

cmd_scheme_list() {
  load_state
  local wall theme flav m colours
  wall="$(still_of "$(current_wall)")"
  while read -r theme; do
    while read -r flav; do
      # Preview each palette in the current mode when it has one
      m="$mode"
      listed "$m" modes "$theme" "$flav" || m="$(modes "$theme" "$flav" | head -n 1)"
      [ -n "$m" ] || continue
      # A palette that can't be generated (no wallpaper for "seed wallpaper")
      # is left out of the list rather than failing it
      colours="$( (gen_colours "$theme" "$flav" "$m" "$(palette_variant "$theme" "$flav" "$m")" "$wall") 2>/dev/null)" ||
        continue
      jq -cn --arg t "$theme" --arg f "$flav" --argjson c "$colours" '{($t): {($f): $c}}'
    done < <(flavours "$theme")
  done < <(themes) | jq -cs 'reduce .[] as $x ({}; . * $x)'
}

cmd_scheme_get() {
  local want="" arg
  for arg in "$@"; do
    case "$arg" in
      -*) want+="${arg#-}" ;;
      *) usage ;;
    esac
  done
  [ -n "$want" ] || want=nfmv

  load_state
  check_state
  # Always in this order, whatever order the flags came in (like caelestia)
  if [[ "$want" == *n* ]]; then echo "$name"; fi
  if [[ "$want" == *f* ]]; then echo "$flavour"; fi
  if [[ "$want" == *m* ]]; then echo "$mode"; fi
  if [[ "$want" == *v* ]]; then echo "$variant"; fi
}

cmd_scheme_set() {
  local new_name="" new_flavour="" new_mode="" new_variant=""
  while [ $# -gt 0 ]; do
    case "$1" in
      -n|--name) new_name="${2:?-n needs a theme}"; shift 2 ;;
      -f|--flavour) new_flavour="${2:?-f needs a flavour}"; shift 2 ;;
      -m|--mode) new_mode="${2:?-m needs a mode}"; shift 2 ;;
      -v|--variant) new_variant="${2:?-v needs a variant}"; shift 2 ;;
      --notify) notify=1; shift ;;
      *) usage ;;
    esac
  done
  [ -n "$new_name$new_flavour$new_mode$new_variant" ] || usage

  load_state
  check_state
  local theme_changed=0
  if [ -n "$new_name" ] && [ "$new_name" != "$name" ]; then
    listed "$new_name" themes || fail "Unable to set theme" "\"$new_name\" is not a theme. Themes: $(themes | xargs)"
    name="$new_name" variant="" theme_changed=1
  fi
  if [ -n "$new_flavour" ]; then
    listed "$new_flavour" flavours "$name" ||
      fail "Unable to set flavour" "Theme $name has no flavour \"$new_flavour\". Flavours: $(flavours "$name" | xargs)"
    flavour="$new_flavour"
  fi
  check_state
  # Switching to the dynamic theme fits it to the wallpaper already up;
  # an explicit -m/-v below still wins
  if [ "$theme_changed" -eq 1 ]; then smart_pick "$(current_wall)"; fi
  if [ -n "$new_mode" ]; then
    listed "$new_mode" modes "$name" "$flavour" ||
      fail "Unable to set mode" "Theme $name $flavour has no $new_mode mode"
    mode="$new_mode"
  fi
  if [ -n "$new_variant" ]; then
    contains "$new_variant" "${variants[@]}" ||
      fail "Unable to set variant" "\"$new_variant\" is not one of: ${variants[*]}"
    variant="$new_variant"
  fi

  # A new theme brings one of its own wallpapers, unless it has none yet
  if [ "$theme_changed" -eq 1 ]; then
    local wall
    wall="$(random_wallpaper "$walls_dir/$name")"
    if [ -n "$wall" ]; then set_wallpaper "$wall"; fi
  fi
  apply
}

# The shell calls this for a video's still, rather than working out where the
# cache put it, so still_of stays the only thing that knows (services/Wallpapers.qml)
cmd_thumb() {
  local file="${1:-}"
  [ -n "$file" ] || usage
  [ -f "$file" ] || die "$file is not a file"
  still_of "$file"
}

cmd_restore() {
  local wall
  # awww-daemon starts alongside this at login; give it up to 5s
  for _ in $(seq 50); do
    awww query >/dev/null 2>&1 && break
    sleep 0.1
  done

  load_state
  check_state
  wall="$(current_wall)"
  if [ -f "$wall" ]; then set_wallpaper "$wall"; fi
  apply
}

case "${1:-}" in
  wallpaper) shift; cmd_wallpaper "$@" ;;
  scheme)
    shift
    case "${1:-}" in
      list) cmd_scheme_list ;;
      get) shift; cmd_scheme_get "$@" ;;
      set) shift; cmd_scheme_set "$@" ;;
      *) usage ;;
    esac
    ;;
  thumb) shift; cmd_thumb "$@" ;;
  restore) cmd_restore ;;
  *) usage ;;
esac
