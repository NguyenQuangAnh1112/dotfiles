#!/bin/sh
set -eu

wallpaper_dirs=${WALLPAPER_DIRS:-"$HOME/Pictures/Wallpapers:$HOME/Pictures:$HOME/Downloads"}
cache_dir=${XDG_CACHE_HOME:-"$HOME/.cache"}/i3
state_file=$cache_dir/wallpaper

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "i3 wallpaper" "$1"
    fi
}

apply_wallpaper() {
    image=$1

    if ! command -v feh >/dev/null 2>&1; then
        notify "Missing dependency: feh"
        exit 1
    fi

    feh --no-fehbg --bg-fill "$image"
    mkdir -p "$cache_dir"
    printf '%s\n' "$image" > "$state_file"
}

if [ "${1:-}" = "--restore" ]; then
    if [ -r "$state_file" ]; then
        image=$(sed -n '1p' "$state_file")
        [ -n "$image" ] && [ -f "$image" ] && apply_wallpaper "$image"
    fi
    exit 0
fi

if ! command -v rofi >/dev/null 2>&1; then
    notify "Missing dependency: rofi"
    exit 1
fi

list_images() {
    old_ifs=$IFS
    IFS=:
    for dir in $wallpaper_dirs; do
        if [ -d "$dir" ]; then
            find "$dir" -type f \( \
                -iname '*.jpg' -o \
                -iname '*.jpeg' -o \
                -iname '*.png' -o \
                -iname '*.webp' -o \
                -iname '*.bmp' \
            \) \
                ! -iname '*screenshot*' \
                ! -iname '*screen shot*' \
                ! -iname '*screencap*' \
                ! -iname '*flameshot*' \
                -print
        fi
    done
    IFS=$old_ifs
}

selection=$(
    list_images |
        sort -u |
        while IFS= read -r image; do
            printf '%s\t%s\0icon\x1f%s\n' "$(basename "$image")" "$image" "$image"
        done |
        rofi -dmenu -i -show-icons -p "Wallpaper"
)

[ -n "$selection" ] || exit 0

image=${selection#*	}
[ -f "$image" ] || exit 1

apply_wallpaper "$image"
