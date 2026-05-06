#!/bin/sh

if ! command -v xrandr >/dev/null 2>&1; then
    exit 0
fi

connected_outputs="$(xrandr --query | awk '/ connected/{print $1}')"

internal="$(printf '%s\n' "$connected_outputs" | awk '/^(eDP|LVDS|DSI)/{print; exit}')"
external="$(printf '%s\n' "$connected_outputs" | awk -v internal="$internal" '$1 != internal { print; exit }')"

if [ -n "$internal" ] && [ -n "$external" ]; then
    xrandr --output "$internal" --primary --auto --output "$external" --auto --left-of "$internal"
elif [ -n "$internal" ]; then
    xrandr --output "$internal" --primary --auto
elif [ -n "$external" ]; then
    xrandr --output "$external" --primary --auto
fi

# Apply wallpaper after xrandr so feh uses the final screen layout.
if command -v feh >/dev/null 2>&1; then
    feh --no-fehbg --bg-scale /home/muggle/Pictures/bg/bg1.jpeg
fi
