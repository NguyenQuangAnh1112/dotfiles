#!/bin/sh
# unity-workspace-watcher.sh
# Tự động gán workspace cho Unity Editor:
# - Có màn hình rời -> workspace F2 ($wsF2)
# - Chỉ dùng màn hình laptop -> workspace 2 ($ws2)

set -eu

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/sway"
CONFIG_FILE="$CONFIG_DIR/unity.conf"
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/sway-unity-watcher.pid"

# Đảm bảo chỉ có một instance chạy thông qua PID file (không dùng pgrep)
if [ -f "$PIDFILE" ]; then
    old_pid=$(cat "$PIDFILE" 2>/dev/null || true)
    if [ -n "$old_pid" ] && [ "$old_pid" != "$$" ] && kill -0 "$old_pid" 2>/dev/null; then
        kill "$old_pid" 2>/dev/null || true
    fi
fi
echo "$$" > "$PIDFILE"

cleanup() {
    if [ -f "$PIDFILE" ]; then
        stored_pid=$(cat "$PIDFILE" 2>/dev/null || true)
        if [ "$stored_pid" = "$$" ]; then
            rm -f "$PIDFILE"
        fi
    fi
}
trap cleanup EXIT INT TERM

check_and_update() {
    has_ext=$(swaymsg -t get_outputs 2>/dev/null | jq -r '[.[] | select((.name | test("^(eDP|LVDS|DSI)") | not) and .active == true)] | length' 2>/dev/null || echo 0)

    if [ "${has_ext:-0}" -gt 0 ]; then
        target_rule='assign [class="^Unity\.bin$"] workspace number $wsF2'
    else
        target_rule='assign [class="^Unity\.bin$"] workspace number $ws2'
    fi

    current_rule=""
    if [ -f "$CONFIG_FILE" ]; then
        current_rule=$(cat "$CONFIG_FILE" 2>/dev/null || true)
    fi

    # Chỉ ghi file và reload nếu cấu hình thực sự thay đổi
    if [ "$current_rule" != "$target_rule" ]; then
        printf "%s\n" "$target_rule" > "$CONFIG_FILE"
        swaymsg reload >/dev/null 2>&1 || true
        exit 0
    fi
}

# 1. Kiểm tra ngay khi khởi động
check_and_update

# 2. Lắng nghe sự kiện cắm/rút màn hình từ Sway IPC
swaymsg -m -t subscribe '["output"]' 2>/dev/null | while read -r _event; do
    check_and_update
done
