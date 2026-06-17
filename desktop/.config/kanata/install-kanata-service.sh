#!/usr/bin/env sh
set -eu

install -Dm644 /home/muggle/.config/kanata/kanata.service /etc/systemd/system/kanata.service
mkdir -p /etc/systemd/system/multi-user.target.d
printf '%s\n' '[Unit]' 'Wants=kanata.service' > /etc/systemd/system/multi-user.target.d/kanata.conf
rm -f /etc/systemd/system/multi-user.target.wants/kanata.service
systemctl daemon-reload
systemctl restart kanata.service
systemctl status kanata.service --no-pager
