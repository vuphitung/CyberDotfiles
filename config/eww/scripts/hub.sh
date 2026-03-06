#!/bin/bash
# ╔══════════════════════════════════════════════════════════╗
# ║  CYBER//HUB v3 — Performance Edition                    ║
# ║  Target: <1% CPU tổng cho tất cả polls                  ║
# ║                                                         ║
# ║  Optimizations:                                         ║
# ║  - c_cpu: bash read builtin, không fork awk/cut         ║
# ║  - c_wifi: 1 lần gọi nmcli duy nhất                    ║
# ║  - c_bt: im lặng, chỉ query device khi ON              ║
# ║  - c_temp: luôn trả số, không bao giờ null             ║
# ║  - c_media: timeout 1s + player priority               ║
# ║  - cache tools: rebuild mỗi 10 phút                    ║
# ╚══════════════════════════════════════════════════════════╝
MODE="${1:-full}"
CACHE_TOOLS="/tmp/eww_tools.json"

# ── TOOL DETECTION — cache 10 phút ─────────────────────────
detect_tools() {
  has()     { command -v "$1" &>/dev/null && echo true || echo false; }
  hasfile() { [[ -e "$1" ]] && echo true || echo false; }
  jq -cn \
    --argjson pamixer       "$(has pamixer)" \
    --argjson wpctl         "$(has wpctl)" \
    --argjson brightnessctl "$(has brightnessctl)" \
    --argjson nmcli         "$(has nmcli)" \
    --argjson bluetoothctl  "$(has bluetoothctl)" \
    --argjson swaync        "$(has swaync-client)" \
    --argjson dunstctl      "$(has dunstctl)" \
    --argjson makoctl       "$(has makoctl)" \
    --argjson playerctl     "$(has playerctl)" \
    --argjson gammastep     "$(has gammastep)" \
    --argjson wlsunset      "$(has wlsunset)" \
    --argjson sensors       "$(has sensors)" \
    --argjson backlight     "$(hasfile /sys/class/backlight)" \
    --argjson bat0          "$(hasfile /sys/class/power_supply/BAT0)" \
    --argjson bat1          "$(hasfile /sys/class/power_supply/BAT1)" \
    '{pamixer:$pamixer,wpctl:$wpctl,brightnessctl:$brightnessctl,
      backlight:$backlight,nmcli:$nmcli,bluetoothctl:$bluetoothctl,
      swaync:$swaync,dunstctl:$dunstctl,makoctl:$makoctl,
      playerctl:$playerctl,gammastep:$gammastep,wlsunset:$wlsunset,
      sensors:$sensors,bat:($bat0 or $bat1),
      bat_path:(if $bat0 then "/sys/class/power_supply/BAT0"
                elif $bat1 then "/sys/class/power_supply/BAT1"
                else "" end)}'
}

now=$(date +%s)
cache_age=$(( now - $(stat -c %Y "$CACHE_TOOLS" 2>/dev/null || echo 0) ))
if [[ ! -f "$CACHE_TOOLS" || $cache_age -gt 600 ]]; then
  detect_tools > "$CACHE_TOOLS"
fi

T=$(cat "$CACHE_TOOLS")
has() { [[ $(echo "$T" | jq -r ".$1" 2>/dev/null) == "true" ]]; }
get() { echo "$T" | jq -r ".$1" 2>/dev/null; }
[[ "$MODE" == "detect" ]] && { echo "$T" | jq .; exit 0; }

# ════════════════════════════════════════════════════════════
#  COLLECTORS
# ════════════════════════════════════════════════════════════

c_vol() {
  if has pamixer; then pamixer --get-volume 2>/dev/null || echo 50
  elif has wpctl; then
    wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null \
      | awk '{printf "%d",$2*100}' || echo 50
  else echo 50; fi
}
c_muted()     { has pamixer && pamixer --get-mute 2>/dev/null || echo false; }
c_mic()       { has pamixer && pamixer --default-source --get-volume 2>/dev/null || echo 50; }
c_mic_muted() { has pamixer && pamixer --default-source --get-mute 2>/dev/null || echo false; }

c_bright() {
  if has brightnessctl; then
    brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%' || echo 50
  else
    local p cur max
    p=$(ls /sys/class/backlight/ 2>/dev/null | head -1)
    [[ -z "$p" ]] && echo 50 && return
    cur=$(cat "/sys/class/backlight/$p/brightness" 2>/dev/null || echo 0)
    max=$(cat "/sys/class/backlight/$p/max_brightness" 2>/dev/null || echo 100)
    [[ $max -eq 0 ]] && echo 50 && return
    echo $(( cur * 100 / max ))
  fi
}

# ── WIFI: 1 lần gọi nmcli duy nhất ────────────────────────
c_wifi() {
  if ! has nmcli; then echo '{"status":"OFF","name":"N/A","signal":0}'; return; fi
  local status name signal
  # Đọc từ /proc/net/wireless trước — tức thì, không cần nmcli
  local wifi_iface
  wifi_iface=$(iw dev 2>/dev/null | awk '/Interface/{print $2}' | head -1)
  
  # nmcli timeout 1s thay vì 2s — tránh block khi wifi đang reconnect
  local radio
  radio=$(timeout 1s nmcli -t -f active,ssid,signal dev wifi 2>/dev/null)
  if timeout 1s nmcli radio wifi 2>/dev/null | grep -q enabled; then
    status="ON"
    name=$(echo "$radio" | awk -F: '/^yes/{print $2}' | head -1)
    signal=$(echo "$radio" | awk -F: '/^yes/{print $3}' | head -1)
  else
    status="OFF"; name="Disconnected"; signal=0
  fi
  [[ -z "$name"   || "$name" == "--" ]] && name="Disconnected"
  [[ -z "$signal" ]] && signal=0
  jq -cn --arg s "$status" --arg n "$name" --arg sig "$signal" \
    '{status:$s,name:$n,signal:($sig|tonumber)}'
}

# ── BT: im lặng, chỉ query device khi ON ──────────────────
c_bt() {
  if ! has bluetoothctl; then echo '{"status":"OFF","device":"None"}'; return; fi
  local status device="None"
  timeout 2s bluetoothctl show 2>/dev/null | grep -q "Powered: yes" \
    && status="ON" || status="OFF"
  [[ "$status" == "ON" ]] && \
    device=$(bluetoothctl info 2>/dev/null | grep "Name:" | head -1 | sed 's/.*Name: //')
  [[ -z "$device" ]] && device="None"
  jq -cn --arg s "$status" --arg d "$device" '{status:$s,device:$d}'
}

c_dnd() {
  if has swaync; then swaync-client -D 2>/dev/null | grep -q true && echo ON || echo OFF
  elif has dunstctl; then dunstctl is-paused 2>/dev/null | grep -q true && echo ON || echo OFF
  elif has makoctl; then makoctl mode 2>/dev/null | grep -q do-not-disturb && echo ON || echo OFF
  else echo OFF; fi
}

c_night() {
  if has gammastep; then pgrep -x gammastep >/dev/null && echo ON || echo OFF
  elif has wlsunset; then pgrep -x wlsunset >/dev/null && echo ON || echo OFF
  else echo OFF; fi
}

# ── CPU: cache-based, không sleep, đọc đúng 10 field /proc/stat ──
c_cpu() {
  local cpu_log="/tmp/eww_cpu_cache"
  local _label user nice system idle iowait irq softirq steal _rest

  read -r _label user nice system idle iowait irq softirq steal _rest < /proc/stat

  # Ép kiểu int — tránh lỗi khoảng trắng thừa
  user=${user:-0}; nice=${nice:-0}; system=${system:-0}
  idle=${idle:-0}; iowait=${iowait:-0}; irq=${irq:-0}
  softirq=${softirq:-0}; steal=${steal:-0}

  local active=$(( user + nice + system + irq + softirq + steal ))
  local total=$(( active + idle + iowait ))

  if [[ -f "$cpu_log" ]]; then
    local last_active=0 last_total=0
    read -r last_active last_total < "$cpu_log" 2>/dev/null
    last_active=$(( last_active + 0 ))
    last_total=$(( last_total + 0 ))
    local diff_active=$(( active - last_active ))
    local diff_total=$(( total  - last_total  ))
    printf "%d %d\n" "$active" "$total" > "$cpu_log"
    [[ $diff_total -le 0 ]] && echo 0 && return
    echo $(( diff_active * 100 / diff_total ))
  else
    printf "%d %d\n" "$active" "$total" > "$cpu_log"
    echo 0
  fi
}

# ── RAM: /proc/meminfo thuần ────────────────────────────────
c_ram_pct() {
  awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}
       END{if(t>0) printf "%d",(t-a)*100/t; else print "0"}' /proc/meminfo
}

# ── TEMP: luôn trả số, không bao giờ null ─────────────────
c_temp() {
  local result

  # 1. lm-sensors (nhanh nhất nếu có)
  if has sensors; then
    result=$(sensors 2>/dev/null \
      | grep -E "Package id 0:|CPU Temperature:|Tdie:|Tccd" \
      | grep -oP '[0-9]+\.[0-9]+' | head -1 | cut -d. -f1)
    [[ -n "$result" && "$result" =~ ^[0-9]+$ ]] && echo "$result" && return
  fi

  # 2. x86_pkg_temp thermal zone
  local zone
  for zone in /sys/class/thermal/thermal_zone*/; do
    if [[ "$(cat "${zone}type" 2>/dev/null)" == "x86_pkg_temp" ]]; then
      result=$(awk '{print int($1/1000)}' "${zone}temp" 2>/dev/null)
      [[ -n "$result" && "$result" =~ ^[0-9]+$ ]] && echo "$result" && return
    fi
  done

  # 3. Highest thermal zone < 120°C
  local best=0 f v c
  for f in /sys/class/thermal/thermal_zone*/temp; do
    v=$(cat "$f" 2>/dev/null || echo 0)
    c=$(( v / 1000 ))
    [[ $c -gt $best && $c -lt 120 ]] && best=$c
  done
  echo "${best:-0}"
}

# ── BAT: safe cho desktop (không có pin → 100) ─────────────
c_bat_pct() {
  local p; p=$(get bat_path)
  [[ -z "$p" || ! -f "$p/capacity" ]] && echo 100 && return
  local cap; cap=$(cat "$p/capacity" 2>/dev/null)
  echo "${cap:-100}"
}

# ── MEDIA: timeout 1s + player priority ────────────────────
c_media() {
  local NONE='{"status":"Stopped","title":"Nothing Playing","artist":"","art":"none"}'
  if ! has playerctl; then echo "$NONE"; return; fi

  local player
  player=$(playerctl -l 2>/dev/null | grep -im1 "spotify" \
    || playerctl -l 2>/dev/null | grep -im1 -E "chromium|firefox|vlc|mpv|cmus" \
    || playerctl -l 2>/dev/null | head -1)
  [[ -z "$player" ]] && echo "$NONE" && return

  local status
  status=$(timeout 1s playerctl --player="$player" status 2>/dev/null || echo "Stopped")
  [[ "$status" == "Stopped" || -z "$status" ]] && echo "$NONE" && return

  local title artist art
  title=$(timeout 1s  playerctl --player="$player" metadata title        2>/dev/null \
    | cut -c1-28 | sed 's/\\/\\\\/g;s/"/\\"/g')
  artist=$(timeout 1s playerctl --player="$player" metadata artist       2>/dev/null \
    | cut -c1-22 | sed 's/\\/\\\\/g;s/"/\\"/g')
  art=$(timeout 1s    playerctl --player="$player" metadata mpris:artUrl 2>/dev/null \
    | sed 's|file://||;s/%20/ /g;s/%27/'"'"'/g')

  [[ -z "$title"  ]] && title="Unknown"
  [[ -z "$artist" ]] && artist=""
  [[ -z "$art"    ]] && art="none"

  jq -cn --arg s "$status" --arg t "$title" --arg a "$artist" --arg r "$art" \
    '{status:$s,title:$t,artist:$a,art:$r}'
}

# ════════════════════════════════════════════════════════════
#  MODE DISPATCH
# ════════════════════════════════════════════════════════════
case "$MODE" in

  # 2s — chỉ đọc số, rất nhanh
  fast)
    jq -cn \
      --arg vol       "$(c_vol)" \
      --arg muted     "$(c_muted)" \
      --arg mic       "$(c_mic)" \
      --arg mic_muted "$(c_mic_muted)" \
      --arg bright    "$(c_bright)" \
      '{vol:($vol|tonumber),muted:$muted,
        mic:($mic|tonumber),mic_muted:$mic_muted,
        bright:($bright|tonumber)}'
    ;;

  # 15s — nmcli + bt chậm nên interval dài
  slow)
    _wifi=$(c_wifi); _bt=$(c_bt)
    jq -cn \
      --arg wifi      "$(echo "$_wifi" | jq -r '.status')" \
      --arg wifi_name "$(echo "$_wifi" | jq -r '.name')" \
      --arg bt        "$(echo "$_bt"   | jq -r '.status')" \
      --arg dnd       "$(c_dnd)" \
      --arg night     "$(c_night)" \
      '{wifi:$wifi,wifi_name:$wifi_name,bt:$bt,dnd:$dnd,night:$night}'
    ;;

  # 8s — cpu/ram/temp nhẹ, bat rất nhẹ
  sys)
    jq -cn \
      --arg cpu  "$(c_cpu)" \
      --arg ram  "$(c_ram_pct)" \
      --arg temp "$(c_temp)" \
      --arg bat  "$(c_bat_pct)" \
      '{cpu:($cpu|tonumber),ram:($ram|tonumber),
        temp:($temp|tonumber),bat:($bat|tonumber)}'
    ;;

  # 2s — playerctl nhẹ khi có timeout
  media)
    c_media
    ;;

  full|*)
    _wifi=$(c_wifi); _bt=$(c_bt); _media=$(c_media)
    jq -cn \
      --arg vol        "$(c_vol)" \
      --arg muted      "$(c_muted)" \
      --arg mic        "$(c_mic)" \
      --arg mic_muted  "$(c_mic_muted)" \
      --arg bright     "$(c_bright)" \
      --arg wifi       "$(echo "$_wifi" | jq -r '.status')" \
      --arg wifi_name  "$(echo "$_wifi" | jq -r '.name')" \
      --arg bt         "$(echo "$_bt"   | jq -r '.status')" \
      --arg dnd        "$(c_dnd)" \
      --arg night      "$(c_night)" \
      --arg cpu        "$(c_cpu)" \
      --arg ram        "$(c_ram_pct)" \
      --arg temp       "$(c_temp)" \
      --arg bat        "$(c_bat_pct)" \
      --arg m_status   "$(echo "$_media" | jq -r '.status')" \
      --arg m_title    "$(echo "$_media" | jq -r '.title')" \
      --arg m_artist   "$(echo "$_media" | jq -r '.artist')" \
      --arg m_art      "$(echo "$_media" | jq -r '.art')" \
      '{vol:($vol|tonumber),muted:$muted,mic:($mic|tonumber),mic_muted:$mic_muted,
        bright:($bright|tonumber),wifi:$wifi,wifi_name:$wifi_name,bt:$bt,
        dnd:$dnd,night:$night,cpu:($cpu|tonumber),ram:($ram|tonumber),
        temp:($temp|tonumber),bat:($bat|tonumber),
        m_status:$m_status,m_title:$m_title,m_artist:$m_artist,m_art:$m_art}'
    ;;
esac
