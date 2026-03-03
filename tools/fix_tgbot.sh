#!/bin/sh
# fix_tgbot.sh — Patch ShellCrash TG Bot for routers where curl lacks proxy support
# Usage: sh fix_tgbot.sh [CRASHDIR]
# Default: auto-detect ShellCrash install path

set -e

BRANCH="fix/telegram-bot-gfw"
RAW="https://raw.githubusercontent.com/cyrilkong/ShellCrash/$BRANCH/scripts"

CRASHDIR="${1:-}"
if [ -z "$CRASHDIR" ]; then
    for d in /data/ShellCrash /jffs/ShellCrash /etc/ShellCrash /opt/ShellCrash; do
        [ -d "$d" ] && CRASHDIR="$d" && break
    done
fi
if [ -z "$CRASHDIR" ] || [ ! -d "$CRASHDIR" ]; then
    echo "ERROR: ShellCrash not found. Usage: sh fix_tgbot.sh /path/to/ShellCrash" >&2
    exit 1
fi

echo "CRASHDIR=$CRASHDIR"

_download(){
    if command -v wget >/dev/null 2>&1; then
        wget -q -O "$2" "$1"
    elif command -v curl >/dev/null 2>&1; then
        curl -fsSL -o "$2" "$1"
    else
        echo "ERROR: neither wget nor curl available" >&2
        exit 1
    fi
}

TARGETS="libs/web_json.sh libs/web_get_lite.sh menus/bot_tg.sh"

for f in $TARGETS; do
    DST="$CRASHDIR/$f"
    [ ! -f "$DST" ] && echo "SKIP: $DST not found" && continue

    cp -f "$DST" "${DST}.orig"
    _download "$RAW/$f" "$DST"
    echo "PATCHED: $f (backup → ${f}.orig)"
done

echo ""
echo "Done. Restart bot:"
echo "  killall bot_tg.sh 2>/dev/null"
echo "  cd $CRASHDIR && nohup sh menus/bot_tg.sh >/dev/null 2>&1 &"
