#!/usr/bin/env bash
# PreToolUse hook for Edit|Write|NotebookEdit.
# Blocks any write targeting refs/ - CLAUDE.md says refs/ is read-only
# reference material; copy into dotfiles/ first, then edit there.
set -euo pipefail

input="$(cat)"
file_path="$(jq -r '.tool_input.file_path // empty' <<<"$input")"

[ -z "$file_path" ] && exit 0

project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"

# Resolve to an absolute path without requiring the file to exist yet.
case "$file_path" in
  /*) abs_path="$file_path" ;;
  *) abs_path="$project_dir/$file_path" ;;
esac
abs_path="$(cd "$(dirname "$abs_path")" 2>/dev/null && pwd)/$(basename "$abs_path")" || abs_path="$abs_path"

refs_dir="$(cd "$project_dir" 2>/dev/null && pwd)/refs"

case "$abs_path" in
  "$refs_dir"/*|"$refs_dir")
    echo "Blocked: refs/ is read-only reference material (see CLAUDE.md)." >&2
    echo "Copy the relevant file into dotfiles/ first, then edit it there." >&2
    exit 2
    ;;
esac

exit 0
