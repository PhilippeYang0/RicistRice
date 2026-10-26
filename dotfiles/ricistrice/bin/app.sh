#!/usr/bin/env bash
# Put any program or file in the app launcher (Super). The launcher lists the
# .desktop files in ~/.local/share/applications, so this writes one there:
# a program is run directly, any other file is opened with its default app.
#
# Entries are named app-<name>.desktop so they never shadow a system app's,
# and carry an X-RicistRice-App line so `ls`/`rm` only ever touch our own.
#
# Called as `app` (alias in zsh/zshrc).
#
# usage: app [add] [-n name] [-i icon] [-t] <file>   add (-t: run in a terminal)
#        app ls                                       list added entries
#        app rm <name>                                remove one
set -euo pipefail

dir="$HOME/.local/share/applications"
marker="X-RicistRice-App=true"

usage() {
    sed -n '/^# usage:/,/^set /s/^# //p' "$0" >&2
    exit 1
}

# "My Tool" -> my-tool
slug() {
    tr '[:upper:]' '[:lower:]' <<<"$1" | sed 's/[^a-z0-9]\+/-/g; s/^-//; s/-$//'
}

ours() {
    grep -qx "$marker" "$1" 2>/dev/null
}

cmd_ls() {
    local f
    for f in "$dir"/app-*.desktop; do
        ours "$f" || continue
        printf '%-24s %s\n' "$(sed -n 's/^Name=//p' "$f")" "$(sed -n 's/^Exec=//p' "$f")"
    done
}

cmd_rm() {
    [[ $# -eq 1 ]] || usage
    local f
    f="$dir/app-$(slug "$1").desktop"
    ours "$f" || { echo "app: no entry named '$1' (see: app ls)" >&2; exit 1; }
    rm -- "$f"
    echo "Removed '$1' from the launcher"
}

cmd_add() {
    local name="" icon="application-x-executable" terminal=false opt
    OPTIND=1
    while getopts "n:i:t" opt; do
        case $opt in
        n) name=$OPTARG ;;
        i) icon=$OPTARG ;;
        t) terminal=true ;;
        *) usage ;;
        esac
    done
    shift $((OPTIND - 1))
    [[ $# -eq 1 ]] || usage

    local target
    target=$(realpath -e -- "$1" 2>/dev/null) || { echo "app: no such file: $1" >&2; exit 1; }
    # These would need escaping in Exec=; refusing is simpler than getting it wrong
    if [[ $target == *[\"\`\$\\%]* ]]; then
        echo "app: path has a character Exec= can't take as is (\" \` \$ \\ %): $target" >&2
        exit 1
    fi

    # Default name: file name without its extension
    [[ -n $name ]] || { name=$(basename -- "$target"); name=${name%.*}; }
    local id
    id=$(slug "$name")
    [[ -n $id ]] || { echo "app: name '$name' has no letters or digits" >&2; exit 1; }

    local exec
    if [[ -f $target && -x $target ]]; then
        exec="\"$target\""
    else
        exec="xdg-open \"$target\""
    fi

    local f="$dir/app-$id.desktop"
    if [[ -e $f ]] && ! ours "$f"; then
        echo "app: $f exists and wasn't made by app, leaving it alone" >&2
        exit 1
    fi

    mkdir -p "$dir"
    cat >"$f" <<EOF
[Desktop Entry]
Type=Application
Name=$name
Exec=$exec
Icon=$icon
Terminal=$terminal
$marker
EOF
    echo "Added '$name' to the launcher ($f)"
}

case ${1:-} in
"") usage ;;
ls) shift; cmd_ls "$@" ;;
rm) shift; cmd_rm "$@" ;;
add) shift; cmd_add "$@" ;;
*) cmd_add "$@" ;;
esac
