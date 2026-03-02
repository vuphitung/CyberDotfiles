#!/bin/bash
# ============================================================
# smartd.sh — CyberTung Smart Daemon v2.0
# Arch Linux + Hyprland + i7-6600U
#
# Chức năng:
#   - Tự detect Electron app → tự throttle CPU
#   - Điều chỉnh limit theo nhiệt độ realtime
#   - Tự tạo profile cho app mới chưa biết
#   - Plug & play, không cần config thủ công
#
# Dùng:
#   smartd.sh start              ← chạy daemon nền
#   smartd.sh launch <app> [args] ← launch app có throttle
#   smartd.sh status             ← xem scopes + profiles + nhiệt
#   smartd.sh log                ← xem log realtime
#   smartd.sh profiles           ← xem/sửa profiles
#   smartd.sh stop               ← dừng daemon
# ============================================================

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PROFILES_DIR="$SCRIPTS_DIR/profiles"
LOG_FILE="/tmp/smartd.log"
PID_FILE="/tmp/smartd.pid"

mkdir -p "$PROFILES_DIR"

# ============================================================
# DEFAULT PROFILES — built-in, không cần sửa
# Thêm app mới vào đây nếu muốn override mặc định 30%
# ============================================================
declare -A DEFAULT_CPU=(
    # Browsers
    [thorium]=45
    [thorium-browser]=45
    [chrome]=45
    [google-chrome]=45
    [chromium]=45
    [firefox]=40
    [brave]=45
    [vivaldi]=45
    # Communication
    [vesktop]=35
    [discord]=35
    [slack]=30
    [teams]=35
    [telegram-desktop]=25
    [signal-desktop]=25
    # Media
    [spotify]=20
    [vlc]=25
    [mpv]=20
    # Dev tools
    [code]=35
    [code-oss]=35
    [vscodium]=35
    [obsidian]=30
    [zed]=35
    # Video call
    [zoom]=40
    [skypeforlinux]=35
    # Fallback cho mọi electron app chưa biết
    [electron]=30
)

declare -A DEFAULT_MEM=(
    [thorium]=900M
    [thorium-browser]=900M
    [chrome]=1G
    [google-chrome]=1G
    [chromium]=900M
    [firefox]=800M
    [brave]=900M
    [vesktop]=600M
    [discord]=600M
    [slack]=600M
    [teams]=700M
    [spotify]=400M
    [code]=800M
    [code-oss]=800M
    [vscodium]=800M
    [obsidian]=500M
    [zoom]=600M
    [electron]=500M
)

# ============================================================
# ELECTRON DETECTION
# ============================================================
is_electron() {
    local cmd="$1"
    local pid

    pid=$(pgrep -f "^$cmd" 2>/dev/null | head -1)

    # Check cmdline của process
    if [ -n "$pid" ]; then
        grep -qiE "(electron|--type=renderer|--enable-crash-reporter|chrome_crashpad)" \
            "/proc/$pid/cmdline" 2>/dev/null && return 0
    fi

    # Check binary symlink
    local bin_path
    bin_path=$(readlink -f "$(which "$cmd" 2>/dev/null)" 2>/dev/null)
    echo "$bin_path" | grep -qi "electron" && return 0

    # Check /usr/lib/<app>/<app> pattern (phổ biến với Electron apps trên Arch)
    [ -f "/usr/lib/$cmd/$cmd" ] && return 0
    [ -f "/opt/$cmd/$cmd" ] && return 0

    return 1
}

# ============================================================
# PROFILE MANAGEMENT
# ============================================================
get_cpu_limit() {
    local app="$1"
    local profile="$PROFILES_DIR/${app}.conf"

    # 1. Profile riêng đã tạo/học
    if [ -f "$profile" ]; then
        # shellcheck disable=SC1090
        source "$profile"
        echo "${CPU_LIMIT:-30}"
        return
    fi

    # 2. Default built-in — exact match
    if [ -n "${DEFAULT_CPU[$app]}" ]; then
        echo "${DEFAULT_CPU[$app]}"
        return
    fi

    # 3. Default built-in — partial match (ví dụ: thorium-browser match thorium)
    for key in "${!DEFAULT_CPU[@]}"; do
        if [[ "$app" == *"$key"* ]] || [[ "$key" == *"$app"* ]]; then
            echo "${DEFAULT_CPU[$key]}"
            return
        fi
    done

    # 4. Detect electron tự động
    if is_electron "$app"; then
        echo "30"
        return
    fi

    # 5. Không phải electron → không throttle
    echo "0"
}

get_mem_limit() {
    local app="$1"
    local profile="$PROFILES_DIR/${app}.conf"

    if [ -f "$profile" ]; then
        # shellcheck disable=SC1090
        source "$profile"
        echo "${MEM_LIMIT:-500M}"
        return
    fi

    if [ -n "${DEFAULT_MEM[$app]}" ]; then
        echo "${DEFAULT_MEM[$app]}"
        return
    fi

    for key in "${!DEFAULT_MEM[@]}"; do
        if [[ "$app" == *"$key"* ]] || [[ "$key" == *"$app"* ]]; then
            echo "${DEFAULT_MEM[$key]}"
            return
        fi
    done

    echo "500M"
}

save_profile() {
    local app="$1"
    local cpu="$2"
    local mem="$3"
    local reason="${4:-auto-detected}"

    cat > "$PROFILES_DIR/${app}.conf" << EOF
# CyberTung Auto Profile — $app
# Created: $(date '+%Y-%m-%d %H:%M:%S')
# Reason: $reason
#
# Chỉnh sửa CPU_LIMIT (%) và MEM_LIMIT (M/G) theo nhu cầu
# Có hiệu lực ngay lần launch tiếp theo

CPU_LIMIT=$cpu
MEM_LIMIT=$mem
EOF

    log "📝 Profile mới: $app (CPU=${cpu}% MEM=${mem}) [$reason]"
}

# ============================================================
# LAUNCH CÓ THROTTLE
# ============================================================
launch_throttled() {
    local app="$1"
    shift
    local args=("$@")

    local cpu_limit
    local mem_limit
    cpu_limit=$(get_cpu_limit "$app")
    mem_limit=$(get_mem_limit "$app")

    # App không phải electron → chạy bình thường, không throttle
    if [ "$cpu_limit" = "0" ]; then
        log "▶  Launch (no throttle): $app"
        exec "$app" "${args[@]}"
        return
    fi

    # Tạo profile nếu chưa có
    if [ ! -f "$PROFILES_DIR/${app}.conf" ]; then
        save_profile "$app" "$cpu_limit" "$mem_limit" "auto-detected on first launch"
    fi

    log "🚀 Launch throttled: $app (CPU≤${cpu_limit}% MEM≤${mem_limit})"

    systemd-run --user --scope \
        -p CPUQuota="${cpu_limit}%" \
        -p MemoryHigh="$mem_limit" \
        -p CPUWeight=50 \
        -p ManagedOOMPreference=kill \
        --unit="smart-${app}-$$" \
        -- "$app" "${args[@]}" &>/dev/null &
}

# ============================================================
# THERMAL MANAGEMENT
# ============================================================
get_temp() {
    sensors 2>/dev/null \
        | grep "Package id 0" \
        | awk '{print $4}' \
        | tr -d '+°C' \
        | cut -d. -f1
}

get_thermal_multiplier() {
    local temp="$1"
    # Nhiệt càng cao → multiplier càng nhỏ → quota càng thấp
    if   [ "$temp" -gt 85 ]; then echo "0.30"   # Nguy hiểm: còn 30%
    elif [ "$temp" -gt 80 ]; then echo "0.45"   # Rất nóng: còn 45%
    elif [ "$temp" -gt 75 ]; then echo "0.65"   # Nóng: còn 65%
    elif [ "$temp" -gt 70 ]; then echo "0.80"   # Hơi ấm: còn 80%
    else echo "1.0"                              # Mát: giữ nguyên
    fi
}

apply_thermal_throttle() {
    local multiplier="$1"
    [ "$multiplier" = "1.0" ] && return

    systemctl --user list-units --type=scope 2>/dev/null \
        | grep "smart-" \
        | awk '{print $1}' \
        | while read -r unit; do
            # Lấy tên app từ unit name: smart-thorium-browser-12345.scope → thorium-browser
            local app
            app=$(echo "$unit" | sed 's/^smart-//;s/-[0-9]*\.scope$//')
            local base_cpu
            base_cpu=$(get_cpu_limit "$app")
            local new_cpu
            new_cpu=$(echo "$base_cpu $multiplier" | awk '{printf "%d", $1 * $2}')
            # Tối thiểu 10% để app không bị treo hoàn toàn
            [ "$new_cpu" -lt 10 ] && new_cpu=10
            systemctl --user set-property "$unit" CPUQuota="${new_cpu}%" 2>/dev/null
        done
}

# ============================================================
# MONITOR LOOP — chạy nền liên tục
# ============================================================

# ── Throttle các scope có sẵn không do smartd tạo ──────────
throttle_existing_scopes() {
    systemctl --user list-units --type=scope --no-legend 2>/dev/null \
        | awk '{print $1}' | grep -vE "^(init|kitty)" \
        | while read -r unit; do
            local pid app current_quota cpu_limit
            pid=$(systemctl --user show "$unit" --property=ControlGroup 2>/dev/null | cut -d= -f2 | xargs -I{} cat /sys/fs/cgroup{}/cgroup.procs 2>/dev/null | head -1)
            if [ -z "$pid" ] || [ "$pid" = "0" ]; then continue; fi
            app=$(cat "/proc/$pid/comm" 2>/dev/null)
            if [ -z "$app" ]; then continue; fi
            current_quota=$(systemctl --user show "$unit" --property=CPUQuotaPerSecUSec 2>/dev/null | cut -d= -f2)
            if [ "$current_quota" = "infinity" ]; then
                cpu_limit=$(get_cpu_limit "$app")
                if [ "$cpu_limit" -gt 0 ]; then
                    systemctl --user set-property "$unit" CPUQuota="${cpu_limit}%" 2>/dev/null
                    log "🔧 Throttle existing: $unit (${cpu_limit}%)"
                fi
            fi
        done
}
monitor_loop() {

    log "🟢 smartd v2.0 started (PID=$$)"
    log "📁 Profiles dir: $PROFILES_DIR"

    local last_temp_state="normal"
    local last_notify_time=0

    while true; do

        # ── THERMAL CHECK ──────────────────────────────────────
        local temp
        temp=$(get_temp)

        if [[ "$temp" =~ ^[0-9]+$ ]]; then
            local mult
            mult=$(get_thermal_multiplier "$temp")

            if [ "$temp" -gt 85 ] && [ "$last_temp_state" != "danger" ]; then
                notify-send -u critical "🔥 NGUY HIỂM: ${temp}°C" \
                    "CPU quá nóng! Throttle tất cả app xuống 30%!" \
                    -t 8000
                apply_thermal_throttle "$mult"
                log "🔥 DANGER temp=${temp}°C → throttle x${mult}"
                last_temp_state="danger"

            elif [ "$temp" -gt 80 ] && [ "$last_temp_state" = "normal" ]; then
                notify-send -u critical "🌡️ QUÁ NÓNG: ${temp}°C" \
                    "Đang giảm CPU quota tất cả app" \
                    -t 5000
                apply_thermal_throttle "$mult"
                log "🌡️ HOT temp=${temp}°C → throttle x${mult}"
                last_temp_state="hot"

            elif [ "$temp" -gt 75 ] && [ "$last_temp_state" = "normal" ]; then
                notify-send "⚠️ CPU ấm: ${temp}°C" "Đang giảm nhẹ quota" -t 3000
                apply_thermal_throttle "$mult"
                log "⚠️  WARM temp=${temp}°C → throttle x${mult}"
                last_temp_state="warm"

            elif [ "$temp" -le 68 ] && [ "$last_temp_state" != "normal" ]; then
                notify-send "❄️ CPU mát: ${temp}°C" "Quota đã khôi phục" -t 3000
                log "❄️  COOL temp=${temp}°C → restored normal state"
                last_temp_state="normal"
                # Scope tự restore quota gốc khi app được restart
            fi
        fi

        # ── AUTO-DETECT PROCESS NGỐN CPU CHƯA CÓ SCOPE ────────
        local top_proc
        top_proc=$(ps -eo comm,pid,%cpu --sort=-%cpu 2>/dev/null \
            | grep -vE "^(waybar|swww|hyprland|Xwayland|pipewire|systemd|kworker|ksoftirq|ps|grep|smartd|sensors)" \
            | awk 'NR==2{print}')  # NR==2 vì NR==1 là header

        local proc_name proc_pid proc_cpu
        proc_name=$(echo "$top_proc" | awk '{print $1}')
        proc_pid=$(echo "$top_proc"  | awk '{print $2}')
        proc_cpu=$(echo "$top_proc"  | awk '{print $3}' | cut -d. -f1)

        if [[ "$proc_cpu" =~ ^[0-9]+$ ]] && [ "$proc_cpu" -gt 70 ]; then
            # Kiểm tra có đang trong scope chưa
            local in_scope
            in_scope=$(systemctl --user list-units --type=scope 2>/dev/null \
                | grep -c "smart-${proc_name}")

            if [ "$in_scope" -eq 0 ]; then
                local cpu_limit
                cpu_limit=$(get_cpu_limit "$proc_name")

                if [ "$cpu_limit" -gt 0 ]; then
                    # Renice ngay để giảm tải tức thì
                    renice -n 10 -p "$proc_pid" 2>/dev/null

                    local now
                    now=$(date +%s)
                    # Anti-spam: chỉ notify mỗi 60s
                    if [ $((now - last_notify_time)) -gt 60 ]; then
                        notify-send "⚡ Auto-throttle" \
                            "[$proc_name] ăn ${proc_cpu}% CPU\nĐã renice, sẽ throttle ở lần launch tiếp" \
                            -t 4000
                        last_notify_time=$now
                    fi
                    log "⚡ Auto-throttle: $proc_name (${proc_cpu}%) pid=$proc_pid → renice+10"
                fi
            fi
        fi

        throttle_existing_scopes
        sleep 12
    done
}

# ============================================================
# LOGGING
# ============================================================
log() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# ============================================================
# ENTRY POINT
# ============================================================
case "$1" in

    start)
        # Kiểm tra đã chạy chưa
        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            echo "smartd đã đang chạy (PID=$(cat $PID_FILE))"
            exit 0
        fi
        monitor_loop &
        BGPID=$!
        echo $BGPID > "$PID_FILE"
        ;;

    stop)
        if [ -f "$PID_FILE" ]; then
            kill "$(cat "$PID_FILE")" 2>/dev/null
            rm -f "$PID_FILE"
            echo "⏹️  smartd stopped"
        else
            echo "smartd không đang chạy"
        fi
        ;;

    restart)
        "$0" stop
        sleep 1
        "$0" start
        ;;

    launch)
        shift
        launch_throttled "$@"
        ;;

    status)
        echo ""
        echo "╔══════════════════════════════════════╗"
        echo "║         smartd STATUS                ║"
        echo "╚══════════════════════════════════════╝"
        echo ""

        echo "── Daemon ─────────────────────────────"
        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            echo "  🟢 Running (PID=$(cat $PID_FILE))"
        else
            echo "  🔴 Not running"
        fi
        echo ""

        echo "── App Scopes đang chạy ────────────────"
        scopes=$(systemctl --user list-units --type=scope 2>/dev/null | grep "smart-")
        if [ -n "$scopes" ]; then
            echo "$scopes" | while read -r line; do echo "  $line"; done
        else
            echo "  (không có scope nào)"
        fi
        echo ""

        echo "── Profiles đã học ─────────────────────"
        if ls "$PROFILES_DIR"/*.conf &>/dev/null; then
            for f in "$PROFILES_DIR"/*.conf; do
                app_name=$(basename "$f" .conf)
                # shellcheck disable=SC1090
                source "$f"
                echo "  📄 $app_name → CPU=${CPU_LIMIT}% MEM=${MEM_LIMIT}"
            done
        else
            echo "  (chưa có profile nào)"
        fi
        echo ""

        echo "── Nhiệt độ hiện tại ───────────────────"
        sensors 2>/dev/null | grep -E "Package id 0|Core [0-9]:" | while read -r line; do
            echo "  $line"
        done
        echo ""
        ;;

    log)
        echo "📋 Log smartd (Ctrl+C để thoát):"
        tail -f "$LOG_FILE"
        ;;

    profiles)
        echo ""
        echo "╔══════════════════════════════════════╗"
        echo "║         App Profiles                 ║"
        echo "╚══════════════════════════════════════╝"
        echo ""
        if ls "$PROFILES_DIR"/*.conf &>/dev/null; then
            for f in "$PROFILES_DIR"/*.conf; do
                echo "── $(basename "$f") ──"
                cat "$f"
                echo ""
            done
        else
            echo "Chưa có profile nào. Launch 1 app để tạo profile đầu tiên."
        fi
        ;;

    edit-profile)
        # smartd.sh edit-profile <app>
        local target="$PROFILES_DIR/${2}.conf"
        if [ ! -f "$target" ]; then
            echo "Profile chưa tồn tại. Tạo mới..."
            cpu=$(get_cpu_limit "$2")
            mem=$(get_mem_limit "$2")
            save_profile "$2" "$cpu" "$mem" "manually created"
        fi
        "${EDITOR:-nano}" "$target"
        ;;

    reset-profile)
        # smartd.sh reset-profile <app>
        rm -f "$PROFILES_DIR/${2}.conf"
        echo "🗑️  Đã xóa profile: $2 (sẽ dùng lại default)"
        ;;

    *)
        echo ""
        echo "CyberTung smartd v2.0"
        echo ""
        echo "Dùng:"
        echo "  smartd.sh start                  ← Chạy daemon"
        echo "  smartd.sh stop                   ← Dừng daemon"
        echo "  smartd.sh restart                ← Restart daemon"
        echo "  smartd.sh launch <app> [args...]  ← Launch app có throttle"
        echo "  smartd.sh status                  ← Xem trạng thái"
        echo "  smartd.sh log                     ← Xem log realtime"
        echo "  smartd.sh profiles                ← Xem tất cả profiles"
        echo "  smartd.sh edit-profile <app>      ← Sửa profile của app"
        echo "  smartd.sh reset-profile <app>     ← Reset về default"
        echo ""
        ;;
esac

# ── PATCH: Throttle các scope có sẵn (không phải do smartd tạo) ──
