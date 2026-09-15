#!/usr/bin/env bash
# Menu front-end for scripts/. Each entry just runs one of those scripts, so
# everything here can also be done straight from the shell.
#
# usage: ./manage.sh
set -uo pipefail
# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/scripts/lib.sh"

command -v whiptail >/dev/null || die "whiptail is missing: sudo apt install whiptail"

items=(
  check          "Validate configs and scripts (changes nothing)"
  diff           "Show what deploy would change in ~/.config"
  deploy         "Check, back up live config, copy dotfiles/ in, reload"
  commit-push    "Check, commit everything, push to GitHub"
  deploy+push    "deploy, then commit-push"
  restore        "Put back a backed-up config (undo a deploy)"
  capture        "Copy live ~/.config changes back into dotfiles/"
  reload         "Reload Hyprland and bars without changing files"
  prune-backups  "Delete old backups"
  deps           "Show missing dependencies (changes nothing)"
  bootstrap      "Install missing apt/PPA dependencies (sudo)"
)

# whiptail draws on stdout and writes the answer to stderr; swap them to
# capture the answer.
ask() { whiptail --title "RicistRice" "$@" 3>&1 1>&2 2>&3; }

pick_backup() {
  local lines=() b contents
  for b in "$backup_root"/*/; do
    contents=("$b"*)
    lines=("$(basename "$b")" "$(printf '%s ' "${contents[@]##*/}")" "${lines[@]}")
  done
  if [ ${#lines[@]} -eq 0 ]; then
    whiptail --title "RicistRice" --msgbox "No backups yet. deploy creates one." 8 50
    return 1
  fi
  ask --menu "Restore which backup? (newest first)" 20 70 12 "${lines[@]}"
}

while choice="$(ask --menu "Pick an action (Esc to quit)" 20 78 12 "${items[@]}")"; do
  clear
  case "$choice" in
    deploy+push)
      "$scripts_dir/deploy.sh" && echo && "$scripts_dir/commit-push.sh"
      ;;
    deps)
      "$scripts_dir/bootstrap.sh" --dry-run
      ;;
    restore)
      backup="$(pick_backup)" || continue
      clear
      "$scripts_dir/restore.sh" "$backup"
      ;;
    prune-backups)
      keep="$(ask --inputbox "Keep how many of the newest backups?" 8 50 5)" || continue
      clear
      "$scripts_dir/prune-backups.sh" "$keep"
      ;;
    *)
      "$scripts_dir/$choice.sh"
      ;;
  esac
  echo
  read -rp "Press Enter to return to the menu..."
done
clear
