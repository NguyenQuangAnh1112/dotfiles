#!/usr/bin/env sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
  echo "Vui lòng chạy script với quyền root hoặc sudo: sudo $0" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Cài đặt file service
install -Dm644 "${SCRIPT_DIR}/kanata.service" /etc/systemd/system/kanata.service

# Dọn dẹp drop-in cũ nếu có
rm -f /etc/systemd/system/multi-user.target.d/kanata.conf
rmdir /etc/systemd/system/multi-user.target.d 2>/dev/null || true

# Kích hoạt và khởi động lại service chuẩn systemd
systemctl daemon-reload
systemctl enable --now kanata.service
systemctl restart kanata.service
systemctl status kanata.service --no-pager
