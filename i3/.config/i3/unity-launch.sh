#!/bin/sh

set -eu

workspace=10
unityhub=${UNITYHUB:-unityhub}

command -v "$unityhub" >/dev/null 2>&1 || exit 1

external_output() {
    command -v xrandr >/dev/null 2>&1 || return 1

    xrandr --query | awk '
        / connected/ {
            output = $1
            if (output !~ /^(eDP|LVDS|DSI)/) {
                print output
                exit
            }
        }
    '
}

external=$(external_output || true)

if command -v i3-msg >/dev/null 2>&1; then
    i3-msg "workspace number $workspace" >/dev/null
    if [ -n "$external" ]; then
        i3-msg "move workspace to output $external" >/dev/null
    fi
fi

export XDG_SESSION_TYPE=x11
export XCURSOR_THEME=Bibata-Modern-Ice
export XCURSOR_SIZE=32

if [ -n "$external" ]; then
    export DRI_PRIME=1
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
fi

exec "$unityhub" "$@"
