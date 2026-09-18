# RicistRice
I want to rice the ricest rice on my ubuntu.

A Hyprland + Quickshell rice adapted by hand from
[caelestia](https://github.com/caelestia-dots/caelestia) (Hyprland config) and
[caelestia-shell](https://github.com/caelestia-dots/shell) (the Quickshell
shell), with its own theme pipeline: awww draws the wallpaper, matugen builds
colours from each theme's hand-picked palette.

## Setup (fresh install)

1. `scripts/bootstrap.sh` — installs the apt/PPA dependencies in
   `packages.txt` (Hyprland, quickshell-git, matugen, build deps, ...). It only
   reports `[manual]` items; install those by hand with the commands listed in
   `packages.txt` (awww, three fonts, discord, spotify + SpotX-Bash).
2. `scripts/build-shell.sh` — builds the shell's C++ QML plugin (caelestia's
   plugin, m3shapes, libcava) into `~/.local/lib/ricistrice`. No sudo.
3. Put wallpapers in `~/Pictures/Wallpapers/<theme>/`, e.g.
   `~/Pictures/Wallpapers/cozy-pixelated/`.
4. `scripts/deploy.sh` — copies `dotfiles/*` into `~/.config/*`. **The first
   time**, do this from Cinnamon (or log out of Hyprland right after): a
   Hyprland session started on the old `hyprland.conf` can't switch to
   `hyprland.lua` live, so `reload.sh` skips it and the new config applies at
   the next Hyprland login.

## Usage

```sh
./manage.sh                # menu for everything below
scripts/bootstrap.sh       # install missing apt/PPA dependencies (packages.txt)
scripts/bootstrap.sh --dry-run   # just list what's missing
scripts/build-shell.sh     # (re)build the shell plugin; no-op when up to date
scripts/check.sh           # validate scripts + Hyprland config, changes nothing
scripts/diff.sh            # what would deploy change in ~/.config?
scripts/deploy.sh [hypr]   # check, back up live config, copy dotfiles/ in, reload
scripts/restore.sh         # undo the last deploy (--list to pick an older backup)
scripts/capture.sh [hypr]  # copy live ~/.config edits back into dotfiles/
scripts/commit-push.sh     # check, commit everything, push
```

Editing `dotfiles/` never touches the live desktop; only `deploy.sh` does.
Backups go to `~/.local/state/ricistrice/backups/`.

## What's in dotfiles/

| Folder | Deployed to | What it is |
|---|---|---|
| `hypr/` | `~/.config/hypr` | Hyprland, Lua config ported from caelestia. Tweak apps, looks and keybinds in `variables.lua` |
| `quickshell/` | `~/.config/quickshell` | caelestia-shell's QML (GPL-3.0, see its `LICENSE`), Quickshell's default config so plain `qs` runs it |
| `caelestia/` | `~/.config/caelestia` | the shell's settings, `shell.json` (only what differs from caelestia's defaults) |
| `ricistrice/` | `~/.config/ricistrice` | `bin/theme.sh` and the theme palettes in `themes/` |

## Themes

A theme is a palette plus a wallpaper folder with the same name:
`dotfiles/ricistrice/themes/<name>/<flavour>/<mode>.conf` and
`~/Pictures/Wallpapers/<name>/`. The palette file format is documented at the
top of `themes/cozy-pixelated/default/dark.conf`.

Switch themes from the shell's launcher: `>scheme` lists themes, `>wallpaper`
browses wallpapers (picking one from another theme's folder switches to that
theme), `>variant` changes the Material colour variant. From a terminal:

```sh
~/.config/ricistrice/bin/theme.sh scheme set -n cozy-pixelated
~/.config/ricistrice/bin/theme.sh wallpaper -f ~/Pictures/Wallpapers/cozy-pixelated/room.gif
~/.config/ricistrice/bin/theme.sh wallpaper -r
```

`theme.sh` stands in for the caelestia CLI's `wallpaper` and `scheme`
commands; the shell calls it through `Paths.themeCmd`.

## Keybinds

caelestia's keybinds (see its README), with these differences:

| Keys | Does | Note |
|---|---|---|
| `Super` (tap) | launcher | replaces the old `Super+D` rofi |
| `Super+T`, `Super+Return` | terminal (alacritty) | `Super+Return` kept from the old config |
| `Super+M` | music workspace: opens Spotify if it isn't running | caelestia launches it through spicetify; we use plain Spotify + SpotX-Bash (ad blocking) |
| `Super+Shift+E` | log out | works without the shell; the old `Super+M` is caelestia's music workspace now |
| `Ctrl+Alt+Delete` | session menu (shell) | |
| `Super+Alt+Space` | toggle floating | the old `Super+V` is clipboard history now |
| `Super+V` / `Super+Alt+V` | clipboard history / delete an entry (rofi) | caelestia uses its CLI + fuzzel |
| `Print` | full screenshot to `~/Pictures/Screenshots` + clipboard | caelestia uses its CLI |
| `Super+1..0` | workspaces | bound by key position, so they also work on AZERTY |

Dropped because they need the caelestia CLI or apps that aren't installed:
screen recording (`Ctrl+Alt+R`...), emoji picker, paste-latest, the todo
workspace (`Super+R`).

## References

`refs/` is gitignored — it's upstream inspiration material, never edited
directly (see `CLAUDE.md`). To recreate it at the exact commits this repo
was last checked against:

```sh
git clone https://github.com/caelestia-dots/caelestia.git refs/caelestia && git -C refs/caelestia checkout 1ee7a98
git clone https://github.com/caelestia-dots/shell.git     refs/caelestia-shell && git -C refs/caelestia-shell checkout 0f1435a
git clone https://github.com/end-4/dots-hyprland.git      refs/dots-hyprland && git -C refs/dots-hyprland checkout 2f0c8bf
git clone https://github.com/ilyamiro/serpantinum.git     refs/serpantinum && git -C refs/serpantinum checkout 5aae96c
```

Pins are just a snapshot of what was actually read when adapting `dotfiles/`
— update the hash here whenever you re-pull a ref for new ideas. The
caelestia-shell pin must also match `caelestia_rev` in
`scripts/build-shell.sh`, since the copied QML and the compiled plugin have to
come from the same commit.
