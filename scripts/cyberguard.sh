#!/bin/bash
THRESHOLD=90 # Chỉ báo khi thực sự bốc hỏa

while true; do
    # Lấy tiến trình ăn CPU cao nhất, loại bỏ Chrome và hệ thống cốt lõi
    TOP_PROCESS=$(ps -eo comm,%cpu --sort=-%cpu | grep -vE "(chrome|Chrome|google-chrome|waybar|swww|hyprland|Xorg)" | head -n 1)
    
    if [ -n "$TOP_PROCESS" ]; then
        PROC_NAME=$(echo $TOP_PROCESS | awk '{print $1}')
        PROC_CPU=$(echo $TOP_PROCESS | awk '{print $2}' | cut -d. -f1)

        if [[ "$PROC_CPU" =~ ^[0-9]+$ ]] && [ "$PROC_CPU" -gt "$THRESHOLD" ]; then
            sleep 10 # Chờ 10s check lại xem có phải lag nhất thời không
            CHECK_AGAIN=$(ps -eo comm,%cpu | grep "$PROC_NAME" | awk '{print $2}' | cut -d. -f1 | head -n 1)
            
            if [[ "$CHECK_AGAIN" =~ ^[0-9]+$ ]] && [ "$CHECK_AGAIN" -gt "$THRESHOLD" ]; then
                notify-send -u critical "🚀 CPU CĂNG THẲNG" "Tiến trình [$PROC_NAME] đang ngốn $CHECK_AGAIN% CPU!"
                sleep 60 
            fi
        fi
    fi
    sleep 20 
done
