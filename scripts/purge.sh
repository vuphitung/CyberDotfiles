#!/bin/bash
# ============================================================
# purge.sh — CyberTung Emergency Purge v2.0
# Arch Linux + Hyprland
#
# Dùng khi máy lag đột ngột, CPU/RAM bùng lên
# Có 2 chế độ:
#   purge.sh          ← dọn nhẹ, giữ app đang mở
#   purge.sh --hard   ← dọn mạnh, kill hết scopes
# ============================================================

SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
HARD_MODE=false
[ "$1" = "--hard" ] && HARD_MODE=true

log() {
    echo "[PURGE] $1"
}

# ── BƯỚC 1: Dọn zombie processes ──────────────────────────
log "Tìm và dọn zombie processes..."
ZOMBIES=$(ps aux | awk '$8=="Z" {print $2}')
if [ -n "$ZOMBIES" ]; then
    for pid in $ZOMBIES; do
        kill -9 "$pid" 2>/dev/null
    done
    log "Đã kill $(echo "$ZOMBIES" | wc -w) zombie(s)"
else
    log "Không có zombie"
fi

# ── BƯỚC 2: Renice các process đang ăn CPU nhiều ──────────
log "Renice processes ngốn CPU..."
ps -eo pid,%cpu,comm --sort=-%cpu \
    | grep -vE "(waybar|hyprland|Xwayland|pipewire|systemd|kitty)" \
    | awk 'NR>1 && $2>30 {print $1, $3}' \
    | while read -r pid name; do
        renice -n 15 -p "$pid" 2>/dev/null
        log "  Renice $name (PID=$pid) → nice=15"
    done

# ── BƯỚC 3: Hard mode — kill hết app scopes ───────────────
if [ "$HARD_MODE" = true ]; then
    log "HARD MODE: Dừng tất cả app scopes..."
    systemctl --user list-units --type=scope 2>/dev/null \
        | grep "smart-" \
        | awk '{print $1}' \
        | while read -r unit; do
            systemctl --user stop "$unit" 2>/dev/null
            log "  Stopped: $unit"
        done
fi

# ── BƯỚC 4: Giảm limit thermal tạm thời ──────────────────
log "Throttle mạnh tất cả scopes đang chạy..."
systemctl --user list-units --type=scope 2>/dev/null \
    | grep "smart-" \
    | awk '{print $1}' \
    | while read -r unit; do
        systemctl --user set-property "$unit" CPUQuota=15% 2>/dev/null
    done

# ── BƯỚC 5: Dọn RAM page cache (an toàn) ──────────────────
log "Dọn RAM page cache..."
sync
if echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null 2>&1; then
    log "RAM cache cleared"
else
    log "RAM cache: cần sudo (xem README để config sudoers)"
fi

# ── BƯỚC 6: Dọn /tmp rác ─────────────────────────────────
log "Dọn /tmp..."
rm -f /tmp/smartd.log.old 2>/dev/null
# Truncate log nếu quá 1MB
if [ -f /tmp/smartd.log ] && [ "$(wc -c < /tmp/smartd.log)" -gt 1048576 ]; then
    tail -100 /tmp/smartd.log > /tmp/smartd.log.tmp
    mv /tmp/smartd.log.tmp /tmp/smartd.log
    log "Truncated smartd.log"
fi

# ── DONE ──────────────────────────────────────────────────
RAM_FREE=$(free -h | awk '/^Mem:/{print $7}')
CPU_TEMP=$(sensors 2>/dev/null | grep "Package id 0" | awk '{print $4}')

if [ "$HARD_MODE" = true ]; then
    TITLE="🧹 Hard Purge xong"
    MSG="Đã kill scopes + dọn RAM cache\nRAM free: $RAM_FREE | CPU: $CPU_TEMP"
else
    TITLE="✅ Purge xong"
    MSG="Đã renice + throttle apps + dọn cache\nRAM free: $RAM_FREE | CPU: $CPU_TEMP"
fi

notify-send "$TITLE" "$MSG" -t 5000
log "Done. RAM free: $RAM_FREE | CPU: $CPU_TEMP"
echo ""
echo "✅ Purge hoàn tất"
echo "   RAM free: $RAM_FREE"
echo "   CPU temp: $CPU_TEMP"
