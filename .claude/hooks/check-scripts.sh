#!/usr/bin/env bash
# PostToolUse hook for Edit|Write. Never blocks the edit (it already happened):
# when a shell script in the repo is edited, report syntax errors and any
# warnings from shellcheck back to Claude right away (exit 2 = stderr shown to Claude).
set -uo pipefail

input="$(cat)"
file_path="$(jq -r '.tool_input.file_path // .tool_response.filePath // empty' <<<"$input")"

case "$file_path" in
  */refs/*) exit 0 ;;
  *.sh) ;;
  *) exit 0 ;;
esac
[ -f "$file_path" ] || exit 0

if ! out="$(bash -n "$file_path" 2>&1)"; then
  printf 'Syntax error in %s:\n%s\n' "$file_path" "$out" >&2
  exit 2
fi

if command -v shellcheck >/dev/null &&
   ! out="$(shellcheck -x -P SCRIPTDIR -S warning "$file_path" 2>&1)"; then
  printf 'shellcheck warnings in %s:\n%s\n' "$file_path" "$out" >&2
  exit 2
fi

exit 0
