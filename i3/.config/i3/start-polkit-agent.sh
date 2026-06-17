#!/bin/sh

pgrep -u "$USER" -f 'polkit.*authentication|lxpolkit|lxqt-policykit-agent' >/dev/null 2>&1 && exit 0

for candidate in \
    /usr/libexec/polkit-gnome-authentication-agent-1 \
    /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 \
    lxpolkit \
    lxqt-policykit-agent \
    xfce-polkit \
    mate-polkit \
    deepin-polkit-agent
do
    if [ -x "$candidate" ]; then
        "$candidate" >/dev/null 2>&1 &
        exit 0
    fi

    agent=$(command -v "$candidate" 2>/dev/null) || continue
    [ -n "$agent" ] || continue
    "$agent" >/dev/null 2>&1 &
    exit 0
done
