# RicistRice
I want to rice the ricest rice on my ubuntu.

## Setup

1. `./bootstrap.sh` — installs apt/PPA dependencies listed in `packages.txt`
   (Hyprland, Quickshell, matugen, etc.). Prints a TODO list for anything
   with no clean Ubuntu package (currently just awww) instead of guessing an
   install command for those.
2. `./install.sh` — symlinks `dotfiles/*` into `~/.config/*`, backing up
   any existing config first.
3. `./uninstall.sh` — reverses step 2, restoring the most recent backup.

## Usage

```sh
./manage.sh                # menu for everything below
scripts/bootstrap.sh       # install missing apt/PPA dependencies (packages.txt)
scripts/bootstrap.sh --dry-run   # just list what's missing
scripts/check.sh           # validate scripts + Hyprland config, changes nothing
scripts/diff.sh            # what would deploy change in ~/.config?
scripts/deploy.sh [hypr]   # check, back up live config, copy dotfiles/ in, reload
scripts/restore.sh         # undo the last deploy (--list to pick an older backup)
scripts/capture.sh [hypr]  # copy live ~/.config edits back into dotfiles/
scripts/commit-push.sh     # check, commit everything, push
```

Editing `dotfiles/` never touches the live desktop; only `deploy.sh` does.
Backups go to `~/.local/state/ricistrice/backups/`.

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
— update the hash here whenever you re-pull a ref for new ideas.
