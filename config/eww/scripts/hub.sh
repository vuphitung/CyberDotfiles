#!/bin/bash
# ╔══════════════════════════════════════════════════════════╗
# ║  CYBER//HUB — Smart Data Collector                      ║
# ║  Auto-detects tools, split by update frequency          ║
# ╚══════════════════════════════════════════════════════════╝
#
# Modes (used by eww defpoll):
#   hub.sh fast    → vol, mic, bright        (poll 1s)
#   hub.sh slow    → wifi, bt, dnd, night    (poll 5s)
#   hub.sh sys     → cpu, ram, temp, bat     (poll 3s)
#   hub.sh media   → playerctl               (poll 2s)
#   hub.sh detect  → print detected tools    (debug)
#   hub.sh         → full all-in-one         (fallback)

MODE="${1:-full}"

# ════════════════════════════════════════════════════════════
#  TOOL DETECTION — cached in /tmp, rebuilt every 5 min
# ════════════════════════════════════════════════════════════
CACHE_TOOLS="/tmp/eww_tools.json"

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
    '{
      pamixer:$pamixer, wpctl:$wpctl,
      brightnessctl:$brightnessctl, backlight:$backlight,
      nmcli:$nmcli,
      bluetoothctl:$bluetoothctl,
      swaync:$swaync, dunstctl:$dunstctl, makoctl:$makoctl,
      playerctl:$playerctl,
      gammastep:$gammastep, wlsunset:$wlsunset,
      sensors:$sensors,
      bat: ($bat0 or $bat1),
      bat_path: (if $bat0 then "/sys/class/power_supply/BAT0"
                 elif $bat1 then "/sys/class/power_supply/BAT1"
                 else "" end)
    }'
}

# Rebuild cache if stale (>5 min) or missing
now=$(date +%s)
cache_age=$(( now - $(stat -c %Y "$CACHE_TOOLS" 2>/dev/null || echo 0) ))
if [[ ! -f "$CACHE_TOOLS" || $cache_age -gt 300 ]]; then
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
  if has pamixer; then
    pamixer --get-volume 2>/dev/null || echo 50
  elif has wpctl; then
    wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null \
      | awk '{printf "%d", $2*100}' || echo 50
  else echo 50; fi
}

c_muted() {
  has pamixer && pamixer --get-mute 2>/dev/null || echo false
}

c_mic() {
  has pamixer && pamixer --default-source --get-volume 2>/dev/null || echo 50
}

c_mic_muted() {
  has pamixer && pamixer --default-source --get-mute 2>/dev/null || echo false
}

c_bright() {
  if has brightnessctl; then
    brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%' || echo 50
  elif has backlight; then
    local p cur max
    p=$(ls /sys/class/backlight/ 2>/dev/null | head -1)
    [[ -z "$p" ]] && echo 50 && return
    cur=$(cat "/sys/class/backlight/$p/brightness")
    max=$(cat "/sys/class/backlight/$p/max_brightness")
    echo $(( cur * 100 / max ))
  else echo 50; fi
}

c_wifi() {
  if ! has nmcli; then
    echo '{"status":"OFF","name":"N/A","signal":0}'; return
  fi
  local status name signal
  nmcli radio wifi 2>/dev/null | grep -q enabled && status="ON" || status="OFF"
  name=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2 | head -1)
  signal=$(nmcli -t -f active,signal dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2 | head -1)
  [[ -z "$name" ]]   && name="Disconnected"
  [[ -z "$signal" ]] && signal=0
  jq -cn --arg s "$status" --arg n "$name" --arg sig "$signal" \
    '{status:$s,name:$n,signal:($sig|tonumber)}'
}

c_bt() {
  if ! has bluetoothctl; then
    echo '{"status":"OFF","device":"None"}'; return
  fi
  local status device
  bluetoothctl show 2>/dev/null | grep -q "Powered: yes" \
    && status="ON" || status="OFF"
  device=$(bluetoothctl info 2>/dev/null | grep "Name:" | head -1 | sed 's/.*Name: //')
  [[ -z "$device" ]] && device="None"
  jq -cn --arg s "$status" --arg d "$device" '{status:$s,device:$d}'
}

c_dnd() {
  if has swaync; then
    swaync-client -D 2>/dev/null | grep -q true && echo ON || echo OFF
  elif has dunstctl; then
    dunstctl is-paused 2>/dev/null | grep -q true && echo ON || echo OFF
  elif has makoctl; then
    makoctl mode 2>/dev/null | grep -q do-not-disturb && echo ON || echo OFF
  else echo OFF; fi
}

c_night() {
  if has gammastep; then
    pgrep -x gammastep >/dev/null && echo ON || echo OFF
  elif has wlsunset; then
    pgrep -x wlsunset >/dev/null && echo ON || echo OFF
  else echo OFF; fi
}

c_cpu() {
  # Two-sample diff for accurate reading
  local s1 s2 u1 t1 u2 t2
  s1=$(awk '/^cpu /{print $2+$4,$2+$3+$4+$5}' /proc/stat)
  sleep 0.15
  s2=$(awk '/^cpu /{print $2+$4,$2+$3+$4+$5}' /proc/stat)
  u1=$(cut -d' ' -f1 <<<"$s1"); t1=$(cut -d' ' -f2 <<<"$s1")
  u2=$(cut -d' ' -f1 <<<"$s2"); t2=$(cut -d' ' -f2 <<<"$s2")
  local dt=$(( t2 - t1 ))
  [[ $dt -eq 0 ]] && echo 0 || echo $(( (u2-u1)*100/dt ))
}

c_ram() {
  awk '/MemTotal/{t=$2} /MemAvailable/{a=$2}
    END{printf "{\"pct\":%d,\"used\":\"%.1fG\",\"total\":\"%.1fG\"}",
    (t-a)*100/t,(t-a)/1048576,t/1048576}' /proc/meminfo
}

c_temp() {
  # Prefer labeled sensor
  if has sensors; then
    local t
    t=$(sensors 2>/dev/null \
        | grep -E "Package id 0:|CPU Temperature:|Tdie:" \
        | grep -oP '[0-9]+\.[0-9]+' | head -1 | cut -d. -f1)
    [[ -n "$t" ]] && echo "$t" && return
  fi
  # x86_pkg_temp zone
  for zone in /sys/class/thermal/thermal_zone*/; do
    [[ $(cat "${zone}type" 2>/dev/null) == "x86_pkg_temp" ]] \
      && awk '{print int($1/1000)}' "${zone}temp" 2>/dev/null && return
  done
  # Highest zone fallback
  local best=0
  for f in /sys/class/thermal/thermal_zone*/temp; do
    local v c
    v=$(cat "$f" 2>/dev/null); c=$(( v/1000 ))
    [[ $c -gt $best && $c -lt 120 ]] && best=$c
  done
  echo "$best"
}

c_bat() {
  local p
  p=$(get bat_path)
  if [[ -z "$p" ]]; then
    echo '{"pct":100,"status":"AC","icon":"󱘖"}'; return
  fi
  local cap status icon
  cap=$(cat "$p/capacity" 2>/dev/null || echo 100)
  status=$(cat "$p/status" 2>/dev/null || echo Unknown)
  if [[ "$status" == "Charging" ]]; then       icon="󰂄"
  elif [[ $cap -gt 90 ]]; then                 icon="󰁹"
  elif [[ $cap -gt 70 ]]; then                 icon="󰂀"
  elif [[ $cap -gt 50 ]]; then                 icon="󰁿"
  elif [[ $cap -gt 30 ]]; then                 icon="󰁾"
  elif [[ $cap -gt 15 ]]; then                 icon="󰁻"
  else                                          icon="󰁺"; fi
  jq -cn --arg p "$cap" --arg s "$status" --arg i "$icon" \
    '{pct:($p|tonumber),status:$s,icon:$i}'
}

c_media() {
  if ! has playerctl || ! playerctl status &>/dev/null 2>&1; then
    echo '{"status":"Stopped","title":"Nothing Playing","artist":"","art":""}'; return
  fi
  local status title artist art
  status=$(playerctl status 2>/dev/null || echo Stopped)
  title=$(playerctl  metadata title     2>/dev/null | cut -c1-25 | sed 's/"/\\"/g')
  artist=$(playerctl metadata artist    2>/dev/null | cut -c1-20 | sed 's/"/\\"/g')
  art=$(playerctl    metadata mpris:artUrl 2>/dev/null \
        | sed 's|file://||;s/%20/ /g')
  [[ -z "$art" ]] && art="none"
  jq -cn --arg s "$status" --arg t "$title" --arg a "$artist" --arg r "$art" \
    '{status:$s,title:$t,artist:$a,art:$r}'
}

# ════════════════════════════════════════════════════════════
#  MODE DISPATCH — collect only what eww needs right now
# ════════════════════════════════════════════════════════════
case "$MODE" in

  fast)   # poll every 1s — vol, mic, bright
    jq -cn \
      --arg vol      "$(c_vol)" \
      --arg muted    "$(c_muted)" \
      --arg mic      "$(c_mic)" \
      --arg mic_muted "$(c_mic_muted)" \
      --arg bright   "$(c_bright)" \
      '{vol:($vol|tonumber),muted:$muted,
        mic:($mic|tonumber),mic_muted:$mic_muted,
        bright:($bright|tonumber)}'
    ;;

  slow)   # poll every 5s — wifi, bt, dnd, night
    jq -cn \
      --argjson wifi  "$(c_wifi)" \
      --argjson bt    "$(c_bt)" \
      --arg dnd       "$(c_dnd)" \
      --arg night     "$(c_night)" \
      '{wifi:$wifi,bt:$bt,dnd:$dnd,night:$night}'
    ;;

  sys)    # poll every 3s — cpu, ram, temp, bat
    jq -cn \
      --arg cpu   "$(c_cpu)" \
      --argjson ram "$(c_ram)" \
      --arg temp  "$(c_temp)" \
      --argjson bat "$(c_bat)" \
      '{cpu:($cpu|tonumber),ram:$ram,temp:($temp|tonumber),bat:$bat}'
    ;;

  media)  # poll every 2s
    c_media
    ;;

  full|*) # all-in-one — flat fields for direct yuck access
    _wifi=$(c_wifi); _bt=$(c_bt); _ram=$(c_ram); _bat=$(c_bat); _media=$(c_media)
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
      --arg ram        "$(echo "$_ram"  | jq -r '.pct')" \
      --arg ram_used   "$(echo "$_ram"  | jq -r '.used')" \
      --arg temp       "$(c_temp)" \
      --arg bat        "$(echo "$_bat"  | jq -r '.pct')" \
      --arg bat_status "$(echo "$_bat"  | jq -r '.status')" \
      --arg m_status   "$(echo "$_media"| jq -r '.status')" \
      --arg m_title    "$(echo "$_media"| jq -r '.title')" \
      --arg m_artist   "$(echo "$_media"| jq -r '.artist')" \
      --arg m_art      "$(echo "$_media"| jq -r '.art')" \
      '{
        vol:($vol|tonumber), muted:$muted,
        mic:($mic|tonumber), mic_muted:$mic_muted,
        bright:($bright|tonumber),
        wifi:$wifi, wifi_name:$wifi_name,
        bt:$bt, dnd:$dnd, night:$night,
        cpu:($cpu|tonumber),
        ram:($ram|tonumber), ram_used:$ram_used,
        temp:($temp|tonumber),
        bat:($bat|tonumber), bat_status:$bat_status,
        m_status:$m_status, m_title:$m_title,
        m_artist:$m_artist, m_art:$m_art
      }'
    ;;
esac
