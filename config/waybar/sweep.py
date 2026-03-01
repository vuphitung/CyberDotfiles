#!/usr/bin/env python3
import time
import sys

SPEED = 3.0  # giây để đi hết 1 lượt (tăng = chậm hơn)

direction = sys.argv[1] if len(sys.argv) > 1 else "ltr"
WIDTH = int(sys.argv[2]) if len(sys.argv) > 2 else 60

chars_dim    = "·"
chars_bright = "█"
chars_mid    = "▓"
chars_low    = "░"

def get_frame(t, reverse=False):
    # pos_norm: 0.0 → 1.0 → 0.0 (bounce), hoàn toàn dựa trên wall clock
    cycle = (t / SPEED) % 2.0  # 0..2
    pos_norm = cycle if cycle < 1.0 else (2.0 - cycle)  # 0→1→0
    
    if reverse:
        pos_norm = 1.0 - pos_norm  # đảo chiều
    
    pos = pos_norm * (WIDTH - 1)  # scale về WIDTH thực tế
    
    result = ""
    for i in range(WIDTH):
        dist = abs(i - pos)
        if dist < 0.5:
            result += chars_bright
        elif dist < 1.5:
            result += chars_mid
        elif dist < 2.5:
            result += chars_low
        else:
            result += chars_dim
    return result

try:
    while True:
        t = time.time()
        print(get_frame(t, reverse=(direction == "rtl")), flush=True)
        time.sleep(0.05)  # refresh 20fps, không ảnh hưởng tốc độ
except KeyboardInterrupt:
    pass
