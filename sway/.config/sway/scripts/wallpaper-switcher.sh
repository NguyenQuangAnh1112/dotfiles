#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Sway Wallpaper Switcher (Grid Thumbnail View)
# ==============================================================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WOFI_CONF="$SCRIPT_DIR/../wofi/wallpaper.conf"
WOFI_STYLE="$SCRIPT_DIR/../wofi/wallpaper.css"

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/bg}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
THUMB_DIR="$CACHE_DIR/wallpaper_thumbnails"
CURRENT_WALLPAPER="$CACHE_DIR/current_wallpaper"
DEFAULT_WALLPAPER="$WALLPAPER_DIR/japan-artistic-3840x2160-25406.jpg"
FALLBACK_COLOR="#191724"

mkdir -p "$CACHE_DIR" "$THUMB_DIR"

apply_wallpaper() {
    local target="$1"
    local notify="${2:-false}"
    if [ ! -f "$target" ]; then
        return 1
    fi

    # Update symlink for persistence across Sway reloads and reboots
    ln -sfn "$target" "$CURRENT_WALLPAPER"

    # Update Sway wallpaper dynamically
    if command -v swaymsg >/dev/null 2>&1 && swaymsg -t get_version >/dev/null 2>&1; then
        swaymsg "output * bg '$CURRENT_WALLPAPER' fill $FALLBACK_COLOR" >/dev/null 2>&1 || true
    fi

    # Notification (only when explicitly requested, auto-dismiss after 3s)
    if [ "$notify" = "true" ]; then
        local base_name
        base_name="$(basename "$target")"
        if command -v notify-send >/dev/null 2>&1; then
            notify-send -i "$target" "Wallpaper" "Đã đổi hình nền: $base_name" 2>/dev/null || true
        fi
    fi
}

generate_thumb() {
    local img="$1"
    local thumb="$2"
    if [ ! -f "$thumb" ] || [ "$img" -nt "$thumb" ]; then
        if command -v magick >/dev/null 2>&1; then
            magick "$img" -thumbnail 400x225^ -gravity center -extent 400x225 "$thumb" 2>/dev/null || cp "$img" "$thumb" 2>/dev/null || true
        elif command -v convert >/dev/null 2>&1; then
            convert "$img" -thumbnail 400x225^ -gravity center -extent 400x225 "$thumb" 2>/dev/null || cp "$img" "$thumb" 2>/dev/null || true
        else
            cp "$img" "$thumb" 2>/dev/null || true
        fi
    fi
}

init_wallpaper() {
    if [ -e "$CURRENT_WALLPAPER" ]; then
        apply_wallpaper "$(readlink -f "$CURRENT_WALLPAPER")"
    elif [ -f "$DEFAULT_WALLPAPER" ]; then
        apply_wallpaper "$DEFAULT_WALLPAPER"
    else
        local first_file
        first_file=$(find "$WALLPAPER_DIR" -maxdepth 2 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.bmp" \) 2>/dev/null | sort | head -n 1 || true)
        if [ -n "$first_file" ] && [ -f "$first_file" ]; then
            apply_wallpaper "$first_file"
        fi
    fi

    # Pre-generate any missing thumbnails in background
    if [ -d "$WALLPAPER_DIR" ]; then
        (
            for img in "$WALLPAPER_DIR"/*; do
                [ -f "$img" ] || continue
                bn=$(basename "$img")
                generate_thumb "$img" "$THUMB_DIR/${bn}.png"
            done
        ) >/dev/null 2>&1 &
    fi
}

# Handle flags
if [ "${1:-}" = "--init" ]; then
    init_wallpaper
    exit 0
elif [ -n "${1:-}" ] && [ -f "${1:-}" ]; then
    apply_wallpaper "$1" true
    exit 0
fi

# Check directory
if [ ! -d "$WALLPAPER_DIR" ]; then
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Wallpaper" "Thư mục không tồn tại: $WALLPAPER_DIR" -u critical 2>/dev/null || true
    fi
    exit 1
fi

# Find wallpaper files
mapfile -d '' files < <(find "$WALLPAPER_DIR" -maxdepth 2 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.bmp" \) -print0 2>/dev/null | sort -z)

if [ ${#files[@]} -eq 0 ]; then
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Wallpaper" "Không tìm thấy hình ảnh nào trong $WALLPAPER_DIR" 2>/dev/null || true
    fi
    exit 0
fi

# Pre-generate any missing thumbnails in parallel
missing_thumbs=()
for img in "${files[@]}"; do
    [ -f "$img" ] || continue
    bn=$(basename "$img")
    thumb="$THUMB_DIR/${bn}.png"
    if [ ! -f "$thumb" ] || [ "$img" -nt "$thumb" ]; then
        missing_thumbs+=("$img")
    fi
done

if [ ${#missing_thumbs[@]} -gt 0 ]; then
    for img in "${missing_thumbs[@]}"; do
        bn=$(basename "$img")
        generate_thumb "$img" "$THUMB_DIR/${bn}.png" &
    done
    wait
fi

# Detect launcher
launcher="wofi"
if command -v rofi >/dev/null 2>&1; then
    launcher="rofi"
elif command -v wofi >/dev/null 2>&1; then
    launcher="wofi"
elif command -v dmenu >/dev/null 2>&1; then
    launcher="dmenu"
fi

entries=()
for img in "${files[@]}"; do
    [ -f "$img" ] || continue
    bn=$(basename "$img")
    thumb="$THUMB_DIR/${bn}.png"
    [ -f "$thumb" ] || thumb="$img"

    if [ "$launcher" = "wofi" ]; then
        entries+=("img:$thumb:text:$bn")
    elif [ "$launcher" = "rofi" ]; then
        entries+=("$bn\0icon\x1f$thumb")
    else
        entries+=("$bn")
    fi
done

selected=""
if [ "$launcher" = "wofi" ]; then
    selected=$(printf '%s\n' "${entries[@]}" | wofi -c "$WOFI_CONF" -s "$WOFI_STYLE" 2>/dev/null || true)
elif [ "$launcher" = "rofi" ]; then
    selected=$(printf '%b\n' "${entries[@]}" | rofi -dmenu -i -show-icons -theme-str 'listview { columns: 2; lines: 2; } element-text { display: none; } element-icon { size: 200px; }' 2>/dev/null || true)
elif [ "$launcher" = "dmenu" ]; then
    selected=$(printf '%s\n' "${entries[@]}" | dmenu -i -p "Chọn hình nền:" 2>/dev/null || true)
fi

# Exit if cancelled
if [ -z "$selected" ]; then
    exit 0
fi

# Extract filename
clean_name="${selected##*:text:}"
clean_name="$(printf '%s' "$clean_name" | tr -d '\r\n')"

target="$WALLPAPER_DIR/$clean_name"
if [ -f "$target" ]; then
    apply_wallpaper "$target" true
elif [ -f "$selected" ]; then
    apply_wallpaper "$selected" true
fi
