#!/bin/bash
# NC2077 // LAUNCHER v3
CFG="$HOME/CyberDotfiles/config/eww"

# Kill sạch
eww --config "$CFG" kill 2>/dev/null
pkill -f "wintitle.sh"   2>/dev/null
pkill -f "workspaces.sh" 2>/dev/null
pkill -f "hub.sh"        2>/dev/null
sleep 0.5

# Start daemon và chờ nó sẵn sàng
eww --config "$CFG" daemon &
sleep 1.0

# Ping thử — chờ tối đa 5s
for i in 1 2 3 4 5; do
  eww --config "$CFG" ping &>/dev/null && break
  sleep 0.5
done

eww --config "$CFG" open bar
























