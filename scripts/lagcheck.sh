#!/usr/bin/env bash
# CYBERDOTFILES v8 — LAG CHECK: chạy khi đang lag (đặc biệt lúc pin <= 30%), gửi kết quả cho tui.
# Dùng: bash lagcheck.sh        (lấy mẫu 10 giây, KHÔNG cần sudo)
cd /sys/devices/system/cpu || exit 1
sec() { printf '\n== %s ==\n' "$*"; }
bat=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)

sec "NGUỒN / PIN"
[ -n "$bat" ] && { echo "trạng thái=$(<$bat/status) dung lượng=$(<$bat/capacity)%"
  [ -r $bat/energy_full ] && echo "độ chai: full=$(<$bat/energy_full) / thiết kế=$(<$bat/energy_full_design) (µWh) => $(( $(<$bat/energy_full)*100 / $(<$bat/energy_full_design) ))% sức khoẻ"
  [ -r $bat/power_now ] && echo "công suất hút=$(( $(<$bat/power_now)/1000 )) mW"; }
echo "power profile: $(powerprofilesctl get 2>/dev/null)  | mode hiệu ứng: $(cat ${XDG_RUNTIME_DIR:-/tmp}/cyber-mode 2>/dev/null || echo full)"

sec "CPU (lấy mẫu 10s)"
echo "driver=$(<cpu0/cpufreq/scaling_driver) governor=$(<cpu0/cpufreq/scaling_governor) EPP=$(<cpu0/cpufreq/energy_performance_preference) max=$(( $(<cpu0/cpufreq/scaling_max_freq)/1000 ))MHz"
echo "no_turbo=$(cat intel_pstate/no_turbo 2>/dev/null)"
t0=$(cat cpu*/thermal_throttle/*_throttle_count 2>/dev/null | paste -sd+ | bc)
for i in 1 2 3 4 5; do
  echo "  $(( $(sort -n cpu*/cpufreq/scaling_cur_freq | tail -1)/1000 )) MHz (core nhanh nhất) | $(( $(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -n | tail -1)/1000 ))°C"; sleep 2
done
t1=$(cat cpu*/thermal_throttle/*_throttle_count 2>/dev/null | paste -sd+ | bc)
echo "số lần bị bóp xung nhiệt trong 10s: $(( ${t1:-0} - ${t0:-0} ))   (>0 = CPU bị bóp)"
for r in /sys/class/powercap/intel-rapl:0/constraint_{0,1}_{name,power_limit_uw}; do [ -r $r ] && echo "  $(basename $r)=$(<$r)"; done

sec "GPU i915"
for f in /sys/class/drm/card*/gt_{cur,min,max,boost}_freq_mhz; do [ -r $f ] && echo "  $(basename $f)=$(<$f)"; done

sec "KERNEL: throttle / PROCHOT"
journalctl -k -b --no-pager 2>/dev/null | grep -iE "throttl|prochot|thermal|Package temperature" | tail -5

sec "TOP CPU"
ps -eo pid,pcpu,comm --sort=-pcpu | head -8

sec "CỬA SỔ ĐANG CHẠY XWAYLAND? (xwayland:true = mờ + nặng ở scale 1.25)"
hyprctl clients -j 2>/dev/null | jq -r '.[] | "\(.class)\txwayland=\(.xwayland)"'
sec "MONITOR"
hyprctl monitors -j 2>/dev/null | jq -r '.[] | "\(.name) \(.width)x\(.height)@\(.refreshRate|floor) scale=\(.scale)"'
hyprctl configerrors 2>/dev/null
