#!/usr/bin/env bash
# Installs mpv-collage: the two tools into ~/.local/bin, the mpv scripts into the
# mpv config folder and, if fish is installed, the `collage` function.
#
#   ./install.sh [--bind] [--dry-run]     install (--bind also adds the keys to input.conf)
#   ./install.sh --uninstall [--dry-run]  remove everything it installed
#
# Honours XDG_BIN_HOME, XDG_CONFIG_HOME and MPV_HOME. No sudo needed.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
bindir=${XDG_BIN_HOME:-$HOME/.local/bin}
confdir=${XDG_CONFIG_HOME:-$HOME/.config}
mpvdir=${MPV_HOME:-$confdir/mpv}
fishdir=$confdir/fish/conf.d
action=install bind=0 dry=0

for arg in "$@"; do
    case $arg in
        --uninstall) action=uninstall ;;
        --bind) bind=1 ;;
        --dry-run) dry=1 ;;
        -h | --help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown option: $arg" >&2; exit 2 ;;
    esac
done

run() { if [ "$dry" = 1 ]; then echo "would: $*"; else "$@"; fi; }

keys=(
    'ctrl+shift+s           script-binding contact_sheet/contact-sheet              #! Utils > Contact sheet'
    'ctrl+shift+c           script-binding collage/collage                          #! Utils > Collage'
)
files=(
    "bin/mpv-collage:$bindir/mpv-collage:755"
    "bin/mpv-contact-sheet:$bindir/mpv-contact-sheet:755"
    "mpv/collage.lua:$mpvdir/scripts/collage.lua:644"
    "mpv/contact-sheet.lua:$mpvdir/scripts/contact-sheet.lua:644"
)
command -v fish >/dev/null 2>&1 && files+=("fish/collage.fish:$fishdir/collage.fish:644")

if [ "$action" = uninstall ]; then
    for f in "${files[@]}"; do
        dest=$(cut -d: -f2 <<<"$f")
        [ -e "$dest" ] && { echo "removing $dest"; run rm -f "$dest"; }
    done
    input=$mpvdir/input.conf
    if [ -f "$input" ] && grep -qE 'contact_sheet/contact-sheet|collage/collage' "$input"; then
        echo "removing the key bindings from $input"
        run sed -i -E '/contact_sheet\/contact-sheet|collage\/collage/d' "$input"
    fi
    exit 0
fi

for tool in ffmpeg ffprobe; do
    command -v "$tool" >/dev/null 2>&1 || echo "warning: $tool not found (needed by both tools)" >&2
done
command -v magick >/dev/null 2>&1 || echo "warning: ImageMagick (magick) not found, mpv-contact-sheet needs it" >&2
python3 -c 'import PIL' 2>/dev/null || echo "warning: Python Pillow not found, mpv-collage needs it (e.g. pacman -S python-pillow)" >&2

for f in "${files[@]}"; do
    IFS=: read -r src dest mode <<<"$f"
    echo "installing $dest"
    run install -Dm"$mode" "$here/$src" "$dest"
done

input=$mpvdir/input.conf
if [ "$bind" = 1 ]; then
    [ -f "$input" ] || run mkdir -p "$mpvdir"
    eol=''
    [ -f "$input" ] && grep -q $'\r' "$input" && eol=$'\r'   # keep CRLF files consistent
    for line in "${keys[@]}"; do
        if [ -f "$input" ] && grep -qF "${line%%#!*}" "$input"; then continue; fi
        echo "adding to $input: ${line%%  *}"
        [ "$dry" = 1 ] || printf '%s%s\n' "$line" "$eol" >>"$input"
    done
else
    printf '\nAdd these lines to %s for the keys and the uosc menu entries (or run again with --bind):\n\n' "$input"
    printf '%s\n' "${keys[@]}"
fi

case ":$PATH:" in
    *":$bindir:"*) ;;
    *) echo "note: $bindir is not in your PATH; the mpv keys work anyway, the terminal commands need it." ;;
esac
