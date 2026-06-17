#!/bin/sh

command -v xrandr >/dev/null 2>&1 || exit 0

xrandr_query=$(xrandr --query)
connected_outputs=$(printf '%s\n' "$xrandr_query" | awk '/ connected/{print $1}')

internal=$(printf '%s\n' "$connected_outputs" | awk '/^(eDP|LVDS|DSI)/{print; exit}')
external=$(printf '%s\n' "$connected_outputs" | awk -v internal="$internal" '$1 != internal { print; exit }')

refresh_for() {
    output=$1
    target=$2

    printf '%s\n' "$xrandr_query" | awk -v output="$output" -v target="$target" '
        $1 == output && $2 == "connected" { in_output = 1; next }
        in_output && /^[A-Za-z0-9-]+ connected/ { exit }
        in_output && $1 ~ /^[0-9]+x[0-9]+$/ {
            for (i = 2; i <= NF; i++) {
                refresh = $i
                gsub(/[^0-9.]/, "", refresh)
                if (int(refresh + 0.5) == target) {
                    print refresh
                    exit
                }
            }
        }
    '
}

mode_args() {
    output=$1
    target_rate=$2

    [ -n "$output" ] || return 0

    if [ -n "$target_rate" ]; then
        refresh=$(refresh_for "$output" "$target_rate")
    fi

    if [ -n "$refresh" ]; then
        printf '%s\n' "--output $output --auto --rate $refresh"
    else
        printf '%s\n' "--output $output --auto"
    fi
}

if [ -n "$internal" ] && [ -n "$external" ]; then
    internal_args=$(mode_args "$internal" "")
    external_args=$(mode_args "$external" "100")
    # shellcheck disable=SC2086
    xrandr $external_args --left-of "$internal" $internal_args --primary
elif [ -n "$internal" ]; then
    internal_args=$(mode_args "$internal" "")
    # shellcheck disable=SC2086
    xrandr $internal_args --primary
elif [ -n "$external" ]; then
    external_args=$(mode_args "$external" "100")
    # shellcheck disable=SC2086
    xrandr $external_args --primary
fi
