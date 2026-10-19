// Helpers — subprocess calls for system info.
// Ponytail: no Astal service libs installed, so we shell out to standard tools.
// Each function returns a string or struct from one subprocess call.

import { exec, execAsync } from "ags/process"

export function getVolume(): Promise<string> {
  return execAsync("wpctl get-volume @DEFAULT_AUDIO_SINK@")
    .then(out => {
      const m = out.match(/Volume:\s+([\d.]+)/)
      const muted = out.includes("[MUTED]")
      if (!m) return "󰕾 ?"
      const pct = Math.round(parseFloat(m[1]) * 100)
      if (muted) return "󰝟 MUTE"
      if (pct > 66) return `󰕾 ${pct}%`
      if (pct > 33) return `󰖀 ${pct}%`
      return `󰕿 ${pct}%`
    })
    .catch(() => "󰕾 ?")
}

export function getBrightness(): Promise<string> {
  return execAsync("brightnessctl -m")
    .then(out => {
      const parts = out.split(",")
      const pct = parts[3] || "?"
      return `󰃟 ${pct}`
    })
    .catch(() => "󰃟 ?")
}

export function getBattery(): Promise<{ pct: number; charging: boolean; icon: string }> {
  return execAsync("bash -c 'cat /sys/class/power_supply/BAT*/capacity 2>/dev/null'")
    .then(async cap => {
      const pct = parseInt(cap.trim()) || 0
      let charging = false
      try {
        const st = await execAsync("bash -c 'cat /sys/class/power_supply/BAT*/status 2>/dev/null'")
        charging = st.trim().toLowerCase() !== "discharging"
      } catch { /* no battery status */ }
      let icon = ""
      if (charging) icon = "󰂄"
      else if (pct > 90) icon = "󰁹"
      else if (pct > 70) icon = "󰂁"
      else if (pct > 50) icon = "󰁾"
      else if (pct > 30) icon = "󰁼"
      else if (pct > 10) icon = "󰁺"
      else icon = "󰂃"
      return { pct, charging, icon }
    })
    .catch(() => ({ pct: -1, charging: false, icon: "󰂑" }))
}

export function getNetwork(): Promise<string> {
  return execAsync("nmcli -t -f TYPE,STATE,CONNECTION device")
    .then(out => {
      for (const line of out.split("\n")) {
        const [type, state, name] = line.split(":")
        if (type === "wifi" && state === "connected") return `󰤨 ${name}`
        if (type === "ethernet" && state === "connected") return `󰈀 ${name}`
      }
      return "󰤭 Off"
    })
    .catch(() => "󰤭 ?")
}

export function getBluetooth(): Promise<string> {
  return execAsync("bluetoothctl show")
    .then(out => {
      const powered = out.includes("Powered: yes")
      if (!powered) return "󰂲"
      return execAsync("bluetoothctl devices Connected")
        .then(devs => {
          const lines = devs.trim().split("\n").filter(l => l.length > 0)
          return lines.length > 0 ? `󰂱 ${lines.length}` : "󰂯"
        })
        .catch(() => "󰂯")
    })
    .catch(() => "󰂲")
}

export function getPowerProfile(): Promise<string> {
  return execAsync("powerprofilesctl get")
    .then(p => {
      const profile = p.trim()
      if (profile === "performance") return "⚡ Performance"
      if (profile === "power-saver") return "🔋 Saver"
      return "⚖ Balanced"
    })
    .catch(() => "?")
}

export function getMediaPlayer(): Promise<{ title: string; artist: string; status: string } | null> {
  return execAsync("playerctl metadata --format '{{artist}}\\t{{title}}\\t{{status}}'")
    .then(out => {
      const [artist, title, status] = out.split("\t")
      if (!title) return null
      return { title: title.substring(0, 40), artist: artist.substring(0, 30), status }
    })
    .catch(() => null)
}

export function getCpuTemp(): Promise<string> {
  return execAsync("bash -c \"cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -rn | head -1\"")
    .then(out => {
      const t = Math.round(parseInt(out.trim()) / 1000)
      if (t > 0 && t < 120) return ` ${t}°C`
      return " ?"
    })
    .catch(() => " ?")
}
