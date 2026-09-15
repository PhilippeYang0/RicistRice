#!/usr/bin/env bash
# Check, then stage everything, commit, and push the current branch. Steps with
# nothing to do are skipped, so it's safe to re-run (e.g. after a failed push).
# Shows what will be committed and asks first, unless -y is given.
#
# usage: commit-push.sh [-y] ["commit message"]
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

assume_yes=0
if [ "${1:-}" = "-y" ]; then
  assume_yes=1
  shift
fi
msg="${1:-}"

cd "$repo_dir"

git config user.email >/dev/null ||
  die "git doesn't know who you are yet. Run once:
  git config --global user.name \"Your Name\"
  git config --global user.email \"you@example.com\""

"$scripts_dir/check.sh" || die "check failed, nothing committed"
echo

changes="$(git status --porcelain)"
if [ -n "$changes" ]; then
  git status --short
  echo
  if [ "$assume_yes" -eq 0 ]; then
    confirm "Stage all of the above and commit?" || die "aborted, nothing committed"
  fi
  if [ -z "$msg" ]; then
    read -rp "Commit message: " msg
  fi
  [ -n "$msg" ] || die "empty commit message, nothing committed"
  git add -A
  git commit -m "$msg"
else
  say ok "nothing to commit"
fi

branch="$(git branch --show-current)"
[ -n "$branch" ] || die "not on a branch (detached HEAD), nothing pushed"

if git rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1; then
  git push
else
  git push -u origin "$branch"
fi
