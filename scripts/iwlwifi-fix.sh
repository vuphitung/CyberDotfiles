#!/bin/bash
# NC2077 — iwlwifi stability fix
# Fix: tắt power save + 11n_disable để tránh mất kết nối

echo "=== WIFI INFO ==="
iw dev 2>/dev/null | grep -E "Interface|type|ssid"
iwconfig 2>/dev/null | grep -E "ESSID|Power Management"

echo ""
echo "=== CURRENT POWER SAVE ==="
iw dev $(iw dev | awk '/Interface/{print $2}' | head -1) get power_save 2>/dev/null

echo ""
echo "=== APPLYING FIX ==="

# Lấy tên interface wifi
WIFI=$(iw dev 2>/dev/null | awk '/Interface/{print $2}' | head -1)
echo "Interface: $WIFI"

# 1. Tắt power management ngay lập tức
sudo iw dev "$WIFI" set power_save off
echo "Power save: OFF"

# 2. Tạo file config vĩnh viễn
sudo tee /etc/NetworkManager/conf.d/wifi-powersave.conf << 'EOF'
[connection]
wifi.powersave = 2
EOF
echo "NetworkManager config: created"

# 3. Tạo modprobe config cho iwlwifi
sudo tee /etc/modprobe.d/iwlwifi.conf << 'EOF'
# Tắt power save và 11n để tránh mất beacon/kết nối
options iwlwifi power_save=0 d0i3_disable=1 uapsd_disable=1
options iwlmvm power_scheme=1
EOF
echo "iwlwifi modprobe config: created"

echo ""
echo "=== VERIFY ==="
iw dev "$WIFI" get power_save 2>/dev/null
echo ""
echo "Reboot để modprobe config có hiệu lực"
echo "Hoặc chạy: sudo modprobe -r iwlwifi && sudo modprobe iwlwifi"
