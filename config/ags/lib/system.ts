// CYBERTUNG // NEBULA CONTROL DECK — System Integration Backend
// Strongly-typed system state helpers with robust fallback & action handlers

import { execAsync } from "ags/process"

export interface VolumeData {
  volume: number // 0-100
  muted: boolean
  icon: string
  text: string
  available: boolean
}

export interface BrightnessData {
  percent: number // 0-100
  icon: string
  text: string
  available: boolean
}

export interface BatteryData {
  pct: number
  charging: boolean
  icon: string
  text: string
  present: boolean
}

export interface NetworkData {
  type: "wifi" | "ethernet" | "disconnected" | "none"
  name: string
  icon: string
  text: string
}

export interface BluetoothData {
  powered: boolean
  connected: number
  icon: string
  text: string
}

export interface PowerProfileData {
  profile: "performance" | "balanced" | "power-saver" | "unknown"
  icon: string
  text: string
}

export interface MediaData {
  title: string
  artist: string
  status: string
  isPlaying: boolean
}

export interface CpuTempData {
  temp: number
  text: string
}

// ── Volume ──────────────────────────────────────────────────
export async function getVolume(): Promise<VolumeData> {
  try {
    const out = await execAsync("wpctl get-volume @DEFAULT_AUDIO_SINK@")
    const match = out.match(/Volume:\s+([\d.]+)/)
    const muted = out.includes("[MUTED]")

    if (!match) {
      return { volume: 0, muted: false, icon: "󰕾", text: "--%", available: false }
    }

    const volume = Math.min(100, Math.max(0, Math.round(parseFloat(match[1]) * 100)))
    let icon = "󰕾"
    if (muted) icon = "󰝟"
    else if (volume > 66) icon = "󰕾"
    else if (volume > 33) icon = "󰖀"
    else if (volume > 0) icon = "󰕿"
    else icon = "󰝟"

    return {
      volume,
      muted,
      icon,
      text: muted ? "MUTED" : `${volume}%`,
      available: true,
    }
  } catch {
    return { volume: 0, muted: false, icon: "󰕾", text: "--%", available: false }
  }
}

export async function setVolume(percent: number): Promise<void> {
  const clamped = Math.min(100, Math.max(0, Math.round(percent)))
  const decimal = (clamped / 100).toFixed(2)
  try {
    await execAsync(`wpctl set-volume @DEFAULT_AUDIO_SINK@ ${decimal}`)
  } catch (e) {
    console.error("Failed to set volume:", e)
  }
}

export async function toggleMute(): Promise<void> {
  try {
    await execAsync("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
  } catch (e) {
    console.error("Failed to toggle mute:", e)
  }
}

// ── Brightness ──────────────────────────────────────────────
export async function getBrightness(): Promise<BrightnessData> {
  try {
    const out = await execAsync("brightnessctl -m")
    const parts = out.split(",")
    const rawPct = parts[3] ? parseInt(parts[3].replace("%", "")) : 0
    const percent = isNaN(rawPct) ? 0 : Math.min(100, Math.max(0, rawPct))

    let icon = "󰃟"
    if (percent > 70) icon = "󰃠"
    else if (percent > 30) icon = "󰃟"
    else icon = "󰃞"

    return {
      percent,
      icon,
      text: `${percent}%`,
      available: true,
    }
  } catch {
    return { percent: 0, icon: "󰃟", text: "--%", available: false }
  }
}

export async function setBrightness(percent: number): Promise<void> {
  const clamped = Math.min(100, Math.max(5, Math.round(percent)))
  try {
    await execAsync(`brightnessctl set ${clamped}%`)
  } catch (e) {
    console.error("Failed to set brightness:", e)
  }
}

// ── Battery ─────────────────────────────────────────────────
export async function getBattery(): Promise<BatteryData> {
  try {
    const cap = await execAsync("bash -c 'cat /sys/class/power_supply/BAT*/capacity 2>/dev/null'")
    const raw = parseInt(cap.trim())
    if (isNaN(raw) || raw < 0) {
      return { pct: -1, charging: false, icon: "󰂑", text: "AC Only", present: false }
    }

    const pct = Math.min(100, Math.max(0, raw))
    let charging = false
    try {
      const st = await execAsync("bash -c 'cat /sys/class/power_supply/BAT*/status 2>/dev/null'")
      charging = st.trim().toLowerCase() === "charging"
    } catch { /* ignore */ }

    let icon = "󰁹"
    if (charging) icon = "󰂄"
    else if (pct > 90) icon = "󰁹"
    else if (pct > 70) icon = "󰂁"
    else if (pct > 50) icon = "󰁾"
    else if (pct > 30) icon = "󰁼"
    else if (pct > 15) icon = "󰁺"
    else icon = "󰂃"

    return {
      pct,
      charging,
      icon,
      text: `${pct}%`,
      present: true,
    }
  } catch {
    return { pct: -1, charging: false, icon: "󰂑", text: "N/A", present: false }
  }
}

// ── Network ─────────────────────────────────────────────────
export async function getNetwork(): Promise<NetworkData> {
  try {
    const out = await execAsync("nmcli -t -f TYPE,STATE,CONNECTION device")
    const lines = out.split("\n")
    for (const line of lines) {
      const [type, state, name] = line.split(":")
      if (type === "wifi" && state === "connected") {
        return {
          type: "wifi",
          name: name || "WiFi",
          icon: "󰤨",
          text: name || "Connected",
        }
      }
      if (type === "ethernet" && state === "connected") {
        return {
          type: "ethernet",
          name: name || "Ethernet",
          icon: "󰈀",
          text: "Wired",
        }
      }
    }
    return {
      type: "disconnected",
      name: "Offline",
      icon: "󰤭",
      text: "Disconnected",
    }
  } catch {
    return {
      type: "none",
      name: "Unavailable",
      icon: "󰤭",
      text: "Offline",
    }
  }
}

// ── Bluetooth ───────────────────────────────────────────────
export async function getBluetooth(): Promise<BluetoothData> {
  try {
    const out = await execAsync("bluetoothctl show")
    const powered = out.includes("Powered: yes")
    if (!powered) {
      return { powered: false, connected: 0, icon: "󰂲", text: "Disabled" }
    }

    try {
      const devs = await execAsync("bluetoothctl devices Connected")
      const lines = devs.trim().split("\n").filter(l => l.length > 0)
      const count = lines.length
      return {
        powered: true,
        connected: count,
        icon: count > 0 ? "󰂱" : "󰂯",
        text: count > 0 ? `${count} Connected` : "Active",
      }
    } catch {
      return { powered: true, connected: 0, icon: "󰂯", text: "Active" }
    }
  } catch {
    return { powered: false, connected: 0, icon: "󰂲", text: "N/A" }
  }
}

// ── Power Profile ───────────────────────────────────────────
export async function getPowerProfile(): Promise<PowerProfileData> {
  try {
    const p = await execAsync("powerprofilesctl get")
    const profile = p.trim().toLowerCase()
    if (profile === "performance") {
      return { profile: "performance", icon: "󱐋", text: "Performance" }
    }
    if (profile === "power-saver") {
      return { profile: "power-saver", icon: "󰌪", text: "Power Saver" }
    }
    return { profile: "balanced", icon: "󰾆", text: "Balanced" }
  } catch {
    return { profile: "unknown", icon: "󰌪", text: "Standard" }
  }
}

export async function cyclePowerProfile(): Promise<void> {
  try {
    const curr = await getPowerProfile()
    let next = "balanced"
    if (curr.profile === "balanced") next = "power-saver"
    else if (curr.profile === "power-saver") next = "performance"
    else next = "balanced"
    await execAsync(`powerprofilesctl set ${next}`)
  } catch (e) {
    console.error("Failed to cycle power profile:", e)
  }
}

// ── Media Player ────────────────────────────────────────────
export async function getMediaPlayer(): Promise<MediaData | null> {
  try {
    const out = await execAsync("playerctl metadata --format '{{artist}}\t{{title}}\t{{status}}'")
    const [artist, title, status] = out.split("\t")
    if (!title || title.trim() === "") return null

    return {
      title: title.trim().substring(0, 36),
      artist: (artist || "Unknown Artist").trim().substring(0, 28),
      status: status ? status.trim() : "Stopped",
      isPlaying: status ? status.trim().toLowerCase() === "playing" : false,
    }
  } catch {
    return null
  }
}

export async function mediaPlayPause(): Promise<void> {
  try {
    await execAsync("playerctl play-pause")
  } catch (e) {
    console.error("Failed to toggle play-pause:", e)
  }
}

export async function mediaNext(): Promise<void> {
  try {
    await execAsync("playerctl next")
  } catch (e) {
    console.error("Failed to trigger next track:", e)
  }
}

export async function mediaPrev(): Promise<void> {
  try {
    await execAsync("playerctl previous")
  } catch (e) {
    console.error("Failed to trigger previous track:", e)
  }
}

// ── CPU Thermal ─────────────────────────────────────────────
export async function getCpuTemp(): Promise<CpuTempData> {
  try {
    const out = await execAsync("bash -c 'cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -rn | head -1'")
    const raw = parseInt(out.trim())
    if (isNaN(raw) || raw <= 0) {
      return { temp: 0, text: " --°C" }
    }
    const temp = Math.round(raw / 1000)
    return {
      temp,
      text: ` ${temp}°C`,
    }
  } catch {
    return { temp: 0, text: " --°C" }
  }
}
