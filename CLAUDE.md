# MyRice — Hyprland/Quickshell Ricing Project

## Goal

Build a custom, hand-adapted desktop rice for Hyprland on this machine (**Elysium**,
Ubuntu 26.04 LTS "Resolute Raccoon", dual-booted with Windows, NVIDIA RTX 3050),
inspired by rices found on r/unixporn — primarily ones built on **Quickshell**
(e.g. Caelestia, DankMaterialShell, Lucid) — rather than using any all-in-one
automated installer.

Hyprland runs as an **additional session alongside Cinnamon** (not a replacement).
The display manager (LightDM) lets the user pick either session at login.

This repo (`~/projects/RicistRice`) is the single source of truth for that rice:
the actual config that gets deployed (copied) into `~/.config/`, plus reference
material pulled from other people's dotfiles repos for inspiration.

## Why this approach (not an automated installer)

Automated installers (JaKooLit/LinuxBeginnings, etc.) were tried and dropped
after hitting two installer-specific bugs in a row (a distro-version detection
bug, and a stale-dependency build failure). Going manual/hand-adapted means:

- Debugging only *our own* config choices, never an installer script's assumptions
- Matches how most real r/unixporn rices are actually built — hand-adapted
  dotfiles, not installer-generated
- Full control over exactly what gets installed and why

## Stack decisions

| Layer | Choice | Notes |
|---|---|---|
| Compositor | Hyprland | via `cppiber/hyprland` PPA (Ubuntu repos are stale) |
| Bar/shell | Quickshell (QML) | not waybar — chosen for full shell capability (bar + launcher + lock + notifications in one), at the cost of editing QML instead of a flat config. Installed from `ppa:avengemedia/danklinux` (DankMaterialShell's PPA), not built from source |
| Wallpaper daemon | `awww` | successor to `swww`, which is now archived/unmaintained |
| Color/theme | `matugen` as the per-theme accent generator; curated palettes per theme, not a single global wallpaper-derived scheme | from the same `avengemedia/danklinux` PPA. pywal is a lighter alternative if matugen output looks off |
| Display manager | LightDM | already confirmed working, no change needed |
| NVIDIA driver | 595.91.07 (already installed) | exceeds the 555+ target for Hyprland/Wayland |

**Aesthetic direction: multi-theme, browsable at runtime**, not a single fixed
look. The user switches between curated themes (wallpaper + palette bundles)
via a browser UI rather than picking one aesthetic for the whole rice. Planned
themes: **cozy-pixelated** (build first, active focus), **anime-stylish**
(planned), **cold-winter** (planned). Each theme gets its own hand-picked
palette; `matugen` recolors accents within a theme rather than deriving the
whole scheme from whatever wallpaper happens to be set.

**Rice to adapt from: `refs/caelestia-shell`** — chosen because it already
implements a wallpaper/scheme browsing UI (`modules/launcher/services/Schemes.qml`,
`modules/launcher/items/WallpaperItem.qml`, `modules/nexus/pages/WallpaperAndStyle.qml`)
that matches the multi-theme-browser requirement directly, on top of already
matching the Quickshell + matugen stack decision.

## Repo structure

```
~/projects/RicistRice/
├── dotfiles/              # the config — deploy.sh copies each folder into ~/.config/
│   ├── hypr/              #   → ~/.config/hypr
│   ├── waybar/            #   → ~/.config/waybar (leftover placeholder, see Open items; don't maintain)
│   ├── quickshell/        #   → ~/.config/quickshell (scaffold only, skipped until it has content)
│   └── ...                #   (mako/, hyprlock/, etc. if/as added)
├── refs/                  # untouched reference clones — read/copy from, don't edit
├── scripts/               # one job per script, all runnable directly
│   ├── lib.sh             #   shared paths/helpers (sourced, not run)
│   ├── check.sh           #   validate scripts (bash -n, shellcheck) + Hyprland --verify-config
│   ├── diff.sh            #   show what deploy would change in ~/.config
│   ├── deploy.sh          #   check → back up live config → cp -a dotfiles/<name> → reload
│   ├── restore.sh         #   put a backup back (undo a deploy)
│   ├── capture.sh         #   reverse of deploy: live ~/.config/<name> → dotfiles/<name>
│   ├── reload.sh          #   hyprctl reload, waybar SIGUSR2, restart quickshell
│   ├── prune-backups.sh   #   keep the newest N backups
│   ├── commit-push.sh     #   check → git add -A → commit → push
│   └── bootstrap.sh       #   install apt/PPA deps from packages.txt (--dry-run: just report)
├── manage.sh              # whiptail menu that runs the scripts above
├── packages.txt           # every dependency + what uses it; read by bootstrap.sh
├── README.md
└── CLAUDE.md              # this file
```

Backups live outside the repo in `~/.local/state/ricistrice/backups/<timestamp>/<name>`,
one timestamped folder per deploy/restore run.

`refs/` is `.gitignore`d (or submoduled) — it's inspiration material, not part
of our own rice. Never edit files inside `refs/`; copy the parts we want into
`dotfiles/` and adapt them there.

## Workflow

1. **Reference**: clone a rice repo of interest into `refs/<name>/` for reading.
2. **Adapt**: copy/port the relevant QML components, configs, or scripts into
   `dotfiles/`, rewriting anything hardcoded to the original author's machine —
   monitor names, wallpaper paths, package-manager assumptions (they're often
   Arch/`pacman`/`paru`; we need apt/PPA equivalents), keybind IPC calls.
3. **Deploy explicitly, by copy**: editing `dotfiles/` does *not* touch the live
   desktop. `scripts/deploy.sh` (or `./manage.sh`) runs `check.sh`, moves the
   live `~/.config/<name>` into a timestamped backup, copies `dotfiles/<name>`
   in, and reloads. Symlinking was dropped on purpose: it made every save
   instantly live, which was too much destructive power. The cost is that the
   live config can drift from the repo — `diff.sh` shows drift, `capture.sh`
   pulls live changes back into the repo.
4. **Iterate**: use Claude Code, working directory `~/projects/RicistRice`, to
   read `refs/` for ideas, edit `dotfiles/` directly, and debug QML/shell errors
   as they come up. Don't run `deploy.sh` or `commit-push.sh` on the user's
   behalf unless asked — deploying changes their live desktop, pushing publishes.
5. **Version**: commit `dotfiles/` changes to git as the rice evolves. `refs/`
   stays out of version control (or pinned separately) since it's just upstream
   source material.

## Ground rules for Claude Code in this repo

- **Never edit anything under `refs/`.** Treat it as read-only inspiration —
  copy the relevant piece into `dotfiles/` first, then modify.
- **This is Ubuntu, not Arch.** When porting a rice built for Arch (most of
  them), translate `pacman`/`paru`/`yay` package names to apt equivalents or
  PPAs, and flag any dependency with no clean Ubuntu equivalent instead of
  silently skipping it.
- **Scripts in `scripts/` must stay idempotent and non-destructive**: re-running
  one with nothing to do is a no-op (deploy skips configs identical to the repo,
  commit-push skips empty commits). Nothing in `~/.config` is ever deleted —
  `replace_live` in `lib.sh` moves it into the backup folder first. Keep one job
  per script; combined actions call the single-job scripts rather than
  duplicating them. `.claude/hooks/check-scripts.sh` lints any `.sh` after an edit.
- **Hyprland `source =` lines should use relative paths** (`./monitors.conf`),
  so `check.sh`'s `Hyprland --verify-config` checks the repo's copy rather than
  the live `~/.config/hypr` one.
- **Every dependency goes in `packages.txt`, in the same change that starts
  using it**, so a fresh Ubuntu install can be rebuilt with
  `scripts/bootstrap.sh`. "Dependency" means any program the repo relies on:
  anything a dotfile launches (`exec-once`, keybinds, bar modules), anything a
  script or hook calls, and build deps. Put it under `[apt]` with a
  `# used by: <file>` comment, under `[ppa]` for its source, or under
  `[manual]` (`name :: how to install`) when there's no clean Ubuntu package —
  never leave it unlisted. Remove the line when nothing uses it anymore. Only
  base-system tools (coreutils, grep, sed, findutils, diffutils, procps) are
  exempt. Verify with `scripts/bootstrap.sh --dry-run` (read-only, exits 1 if
  anything is missing).
- **`scripts/bootstrap.sh` is the only thing that installs packages**, and it
  must stay idempotent: skip added PPAs and installed packages (checked with
  `dpkg-query` status, since `dpkg -s` also matches removed packages), and
  never call `sudo` when nothing is missing.
- **Keep `hyprland.conf` changes minimal and explicit** — only add what's
  needed to launch Quickshell (`exec-once = qs`) and bind its IPC calls;
  don't restructure the user's existing Hyprland config wholesale.
- **Prefer explaining QML/shell errors over silently "fixing" them** when the
  cause isn't obvious — this is a learning project for someone newer to
  terminal/code work, not a black-box automation.
- **Check the current [project decisions doc]** (tracked in the separate
  Claude.ai project, not this repo) before assuming a stack choice — it's the
  source of truth for what's been decided vs. still open.

## Open items to resolve before/while building this out

- Only `cozy-pixelated` is being built now; `anime-stylish` and `cold-winter`
  are scaffolded as placeholder themes until it ships
- Quickshell is installed (0.3.1, via the PPA), but no shell config exists yet:
  `dotfiles/quickshell/` is still an empty scaffold, and the companion pieces
  (launcher, lock screen, notification daemon) are still pending
- **`exec-once = waybar` / `exec-once = hyprpaper` in `hyprland.conf`, and all of
  `dotfiles/waybar/`, are unintentional leftovers** from the first copy of the
  user's local config, not stack choices. Don't fix, extend, or debug them.
  They get removed in the same change that makes Quickshell (`exec-once = qs`)
  and `awww-daemon` take over. hyprpaper is deliberately not in `packages.txt`
- No automated QML check yet — `check.sh` covers shell scripts and Hyprland
  only. Quickshell is installed now, so this is unblocked
