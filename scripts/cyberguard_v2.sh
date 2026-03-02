#!/bin/bash
# ============================================================
# cyberguard_v2.sh — CyberTung CPU/Thermal Monitor v2.0
# Arch Linux + Hyprland + i7-6600U
#
# Nâng cấp từ cyberguard.sh:
#   ✅ Bắt được thorium/electron (v1 bỏ qua)
#   ✅ Ngưỡng 70% cảnh báo, 88% hành động (v1 là 90%)
#   ✅ Check nhiệt độ, tự throttle khi > 82°C (v1 không có)
#   ✅ Anti-spam notification với state machine
#   ✅ Double-check trước khi throttle (giữ từ v1)
#
# Chạy độc lập song song với smartd.sh
# smartd.sh xử lý launch, cyberguard xử lý monitor liên tục
# ============================================================

# ── CẤU HÌNH — chỉnh theo ý muốn ─────────────────────────
THRESHOLD_WARN=70       # % CPU → cảnh báo nhẹ
THRESHOLD_ACT=88        # % CPU → hành động (throttle/notify)
TEMP_WARN=75            # °C → cảnh báo nhiệt
TEMP_CRIT=82            # °C → throttle khẩn cấp
CHECK_INTERVAL=15       # giây giữa mỗi lần check
DOUBLE_CHECK_WAIT=8     # giây chờ trước khi double-check
NOTIFY_COOLDOWN=60      # giây chờ giữa các notify cùng loại
# ──────────────────────────────────────────────────────────

# Processes hệ thống, không bao giờ throttle
WHITELIST="waybar|swww|hyprland|Xwayland|pipewire|systemd|kworker|ksoftirqd|rcu|wl-paste|mako|nm-applet|fcitx|cyberguard|smartd|sensors|ps|grep"

# State tracking
LAST_TEMP_STATE="normal"
declare -A LAST_NOTIFY_TIME

# ──────────────────────────────────────────────────────────
get_temp() {
    sensors 2>/dev/null \
        | grep "Package id 0" \
        | awk '{print $4}' \
        | tr -d '+°C' \
        | cut -d. -f1
}

can_notify() {
    local key="$1"
    local now
    now=$(date +%s)
    local last="${LAST_NOTIFY_TIME[$key]:-0}"
    if [ $((now - last)) -gt "$NOTIFY_COOLDOWN" ]; then
        LAST_NOTIFY_TIME[$key]=$now
        return 0
    fi
    return 1
}

throttle_all_scopes() {
    local quota="$1"
    systemctl --user list-units --type=scope 2>/dev/null \
        | grep "smart-" \
        | awk '{print $1}' \
        | xargs -I{} systemctl --user set-property {} CPUQuota="${quota}%" 2>/dev/null
}

log() {
    echo "[$(date '+%H:%M:%S')] [guard] $1"
}

# ──────────────────────────────────────────────────────────
log "🛡️  cyberguard_v2 started"
log "   Warn: CPU>${THRESHOLD_WARN}% | Act: CPU>${THRESHOLD_ACT}%"
log "   Temp warn: >${TEMP_WARN}°C | Temp crit: >${TEMP_CRIT}°C"

while true; do

    # ═══ THERMAL CHECK ════════════════════════════════════
    TEMP=$(get_temp)

    if [[ "$TEMP" =~ ^[0-9]+$ ]]; then

        if [ "$TEMP" -gt "$TEMP_CRIT" ]; then
            if [ "$LAST_TEMP_STATE" != "critical" ]; then
                log "🔥 CRITICAL temp=${TEMP}°C → throttle all → 15%"
                throttle_all_scopes 15
                notify-send -u critical \
                    "🔥 CPU NGUY HIỂM: ${TEMP}°C" \
                    "Đang throttle tất cả app xuống 15%!\nFan: $(sensors 2>/dev/null | grep -i fan | head -1 | awk '{print $2, $3}')" \
                    -t 10000
                LAST_TEMP_STATE="critical"
            fi

        elif [ "$TEMP" -gt "$TEMP_WARN" ]; then
            if [ "$LAST_TEMP_STATE" = "normal" ]; then
                log "⚠️  WARM temp=${TEMP}°C → throttle all → 50%"
                throttle_all_scopes 50
                if can_notify "temp_warn"; then
                    notify-send "🌡️ CPU nóng: ${TEMP}°C" \
                        "Đã giảm quota app xuống 50%" \
                        -t 5000
                fi
                LAST_TEMP_STATE="warm"
            fi

        else
            # Nhiệt bình thường
            if [ "$LAST_TEMP_STATE" != "normal" ]; then
                log "❄️  COOL temp=${TEMP}°C → state restored"
                notify-send "❄️ CPU mát: ${TEMP}°C" \
                    "Hệ thống ổn định, quota khôi phục" \
                    -t 3000
                LAST_TEMP_STATE="normal"
            fi
        fi
    fi

    # ═══ CPU PROCESS CHECK ════════════════════════════════
    TOP_PROC=$(ps -eo comm,%cpu --sort=-%cpu 2>/dev/null \
        | grep -vE "^($WHITELIST)" \
        | awk 'NR==2{print}')  # skip header

    PROC_NAME=$(echo "$TOP_PROC" | awk '{print $1}')
    PROC_CPU=$(echo "$TOP_PROC"  | awk '{print $2}' | cut -d. -f1)

    if [[ "$PROC_CPU" =~ ^[0-9]+$ ]] && [ -n "$PROC_NAME" ]; then

        # ── Mức HÀNH ĐỘNG: > THRESHOLD_ACT ───────────────
        if [ "$PROC_CPU" -gt "$THRESHOLD_ACT" ]; then
            log "⚡ HIGH CPU: $PROC_NAME=${PROC_CPU}% — waiting ${DOUBLE_CHECK_WAIT}s to double-check..."
            sleep "$DOUBLE_CHECK_WAIT"

            # Double-check — tránh throttle nhất thời
            RECHECK=$(ps -eo comm,%cpu 2>/dev/null \
                | grep "^$PROC_NAME" \
                | awk '{print $2}' \
                | cut -d. -f1 \
                | head -1)

            if [[ "$RECHECK" =~ ^[0-9]+$ ]] && [ "$RECHECK" -gt "$THRESHOLD_ACT" ]; then
                log "⚡ CONFIRMED: $PROC_NAME=${RECHECK}% → throttle"

                # Tạm dừng rồi tiếp tục để giảm tải ngay
                PROC_PID=$(pgrep -f "^$PROC_NAME" | head -1)
                if [ -n "$PROC_PID" ]; then
                    kill -STOP "$PROC_PID" 2>/dev/null
                    sleep 2
                    kill -CONT "$PROC_PID" 2>/dev/null
                fi

                if can_notify "cpu_high_$PROC_NAME"; then
                    notify-send -u critical \
                        "⚡ THROTTLE: $PROC_NAME" \
                        "Đang ăn ${RECHECK}% CPU liên tục\nĐã tạm dừng + tiếp tục để giảm tải" \
                        -t 6000
                fi
            else
                log "✅ $PROC_NAME: ${PROC_CPU}% → ${RECHECK:-0}% (nhất thời, OK)"
            fi

        # ── Mức CẢNH BÁO: > THRESHOLD_WARN ───────────────
        elif [ "$PROC_CPU" -gt "$THRESHOLD_WARN" ]; then
            if can_notify "cpu_warn_$PROC_NAME"; then
                log "⚠️  WARN: $PROC_NAME=${PROC_CPU}%"
                notify-send \
                    "⚠️ CPU cao: $PROC_NAME" \
                    "Đang dùng ${PROC_CPU}%\nTheo dõi thêm..." \
                    -t 4000
            fi
        fi
    fi

    sleep "$CHECK_INTERVAL"
done
