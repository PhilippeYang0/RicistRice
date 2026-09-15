#!/usr/bin/env bash
# PreToolUse hook for Bash.
# Heuristically blocks shell commands that would WRITE into refs/ (CLAUDE.md:
# refs/ is read-only reference material - copy into dotfiles/ first, then edit).
# Read-only commands (cat, grep, find, ls, diff, cp FROM refs/ TO elsewhere)
# are intentionally left alone.
set -euo pipefail

input="$(cat)"
cmd="$(jq -r '.tool_input.command // empty' <<<"$input")"

[ -z "$cmd" ] && exit 0
[[ "$cmd" != *refs/* ]] && exit 0

block() {
  echo "Blocked: this command appears to write into refs/, which is read-only reference material (see CLAUDE.md)." >&2
  echo "Command: $cmd" >&2
  echo "Copy the relevant file into dotfiles/ first, then modify it there." >&2
  exit 2
}

# rm anywhere touching refs/ is always a mutation of refs/.
if [[ "$cmd" =~ (^|[;&|]|[[:space:]])rm[[:space:]] ]]; then
  block
fi

# mv/cp/rsync: only a problem when refs/ is the DESTINATION (last path-like
# argument). Copying FROM refs/ into dotfiles/ is the intended workflow.
if [[ "$cmd" =~ (^|[;&|]|[[:space:]])(mv|cp|rsync)[[:space:]] ]]; then
  last_arg="$(awk '{print $NF}' <<<"$cmd")"
  last_arg="${last_arg%\'}"; last_arg="${last_arg#\'}"
  last_arg="${last_arg%\"}"; last_arg="${last_arg#\"}"
  if [[ "$last_arg" == refs/* || "$last_arg" == */refs/* || "$last_arg" == "refs" ]]; then
    block
  fi
fi

# Shell redirection (> or >>) into a refs/ path.
if [[ "$cmd" =~ \>{1,2}[[:space:]]*\"?\'?([^[:space:]\"\']*refs/[^[:space:]\"\']*) ]]; then
  block
fi

# In-place edits / writes that name a refs/ path explicitly.
if [[ "$cmd" =~ (^|[;&|]|[[:space:]])sed[[:space:]].*-i ]] && [[ "$cmd" == *refs/* ]]; then
  block
fi
if [[ "$cmd" =~ (^|[;&|]|[[:space:]])tee[[:space:]] ]] && [[ "$cmd" == *refs/* ]]; then
  block
fi
if [[ "$cmd" =~ (^|[;&|]|[[:space:]])dd[[:space:]].*of=[^[:space:]]*refs/ ]]; then
  block
fi
if [[ "$cmd" =~ (^|[;&|]|[[:space:]])truncate[[:space:]] ]] && [[ "$cmd" == *refs/* ]]; then
  block
fi

exit 0
