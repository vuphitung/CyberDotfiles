// CYBERTUNG // NEBULA CONTROL DECK — Control Center
// Floating panel toggled from the bar

import app from "ags/gtk3/app"
import { Astal, Gtk, Gdk } from "ags/gtk3"
import { execAsync } from "ags/process"
import { createPoll, interval } from "ags/time"
import {
  getVolume, getBrightness, getBattery, getNetwork,
  getBluetooth, getPowerProfile, getMediaPlayer, getCpuTemp,
} from "../lib/system"

// ── Volume slider row ───────────────────────────────────────
function VolumeRow() {
  return (
    <box class="cc-row" spacing={12}>
      <button
        class="cc-icon-btn"
        onClicked={() => execAsync("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")}
      >
        <label label="󰕾" />
      </button>
      <button
        class="cc-action-btn"
        onClicked={() => execAsync("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")}
      >
        <label label="−" />
      </button>
      <label
        class="cc-value"
        setup={(self: Gtk.Label) => {
          const update = () => getVolume().then(v => self.label = v)
          update()
          interval(2000, update)
        }}
        label=" ?"
      />
      <button
        class="cc-action-btn"
        onClicked={() => execAsync("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+")}
      >
        <label label="+" />
      </button>
    </box>
  )
}

// ── Brightness slider row ───────────────────────────────────
function BrightnessRow() {
  return (
    <box class="cc-row" spacing={12}>
      <label class="cc-icon" label="󰃟" />
      <button
        class="cc-action-btn"
        onClicked={() => execAsync("brightnessctl set 5%-")}
      >
        <label label="−" />
      </button>
      <label
        class="cc-value"
        setup={(self: Gtk.Label) => {
          const update = () => getBrightness().then(v => self.label = v)
          update()
          interval(5000, update)
        }}
        label="󰃟 ?"
      />
      <button
        class="cc-action-btn"
        onClicked={() => execAsync("brightnessctl set 5%+")}
      >
        <label label="+" />
      </button>
    </box>
  )
}

// ── Network + Bluetooth row ─────────────────────────────────
function ConnectivityRow() {
  return (
    <box class="cc-row" spacing={12}>
      <button
        class="cc-chip"
        onClicked={() => execAsync("nm-connection-editor")}
        setup={(self: Gtk.Button) => {
          const update = () => getNetwork().then(v => {
            (self.get_child() as Gtk.Label).label = v
          })
          update()
          interval(10000, update)
        }}
      >
        <label label="󰤭 ?" />
      </button>
      <button
        class="cc-chip"
        onClicked={() => execAsync("blueman-manager")}
        setup={(self: Gtk.Button) => {
          const update = () => getBluetooth().then(v => {
            (self.get_child() as Gtk.Label).label = v
          })
          update()
          interval(10000, update)
        }}
      >
        <label label="󰂲" />
      </button>
    </box>
  )
}

// ── Battery + Power profile ─────────────────────────────────
function PowerRow() {
  return (
    <box class="cc-row" spacing={12}>
      <label
        class="cc-value battery-cc"
        setup={(self: Gtk.Label) => {
          const update = () => getBattery().then(b => {
            if (b.pct < 0) { self.label = "No battery"; return }
            self.label = `${b.icon} ${b.pct}%${b.charging ? " ⚡" : ""}`
          })
          update()
          interval(15000, update)
        }}
        label="󰂑 ?"
      />
      <button
        class="cc-chip power-profile"
        onClicked={() => execAsync("bash -c \"P=$(powerprofilesctl get); case $P in balanced) powerprofilesctl set power-saver;; power-saver) powerprofilesctl set performance;; *) powerprofilesctl set balanced;; esac\"")}
        setup={(self: Gtk.Button) => {
          const update = () => getPowerProfile().then(v => {
            (self.get_child() as Gtk.Label).label = v
          })
          update()
          interval(5000, update)
        }}
      >
        <label label="?" />
      </button>
    </box>
  )
}

// ── Media player ────────────────────────────────────────────
function MediaRow() {
  return (
    <box
      class="cc-row media-row"
      spacing={8}
      setup={(self: Gtk.Box) => {
        const update = () => getMediaPlayer().then(m => {
          self.visible = m !== null
          if (!m) return
          const children = self.get_children()
          if (children.length >= 2) {
            (children[0] as Gtk.Label).label = `♫ ${m.title}`
            ;(children[1] as Gtk.Label).label = m.artist
          }
        })
        update()
        interval(3000, update)
      }}
    >
      <label class="media-title" label="♫" truncate maxWidthChars={35} />
      <label class="media-artist" label="" truncate maxWidthChars={25} />
      <box spacing={4}>
        <button class="cc-action-btn" onClicked={() => execAsync("playerctl previous")}>
          <label label="󰒮" />
        </button>
        <button class="cc-action-btn" onClicked={() => execAsync("playerctl play-pause")}>
          <label label="󰐎" />
        </button>
        <button class="cc-action-btn" onClicked={() => execAsync("playerctl next")}>
          <label label="󰒭" />
        </button>
      </box>
    </box>
  )
}

// ── System status row ───────────────────────────────────────
function StatusRow() {
  return (
    <box class="cc-row status-row" spacing={12}>
      <label
        class="cc-value"
        setup={(self: Gtk.Label) => {
          const update = () => getCpuTemp().then(v => self.label = v)
          update()
          interval(10000, update)
        }}
        label=" ?"
      />
    </box>
  )
}

// ── Quick shortcuts ─────────────────────────────────────────
function Shortcuts() {
  const shortcuts = [
    { icon: "󰸉", action: "kitty --class wall-picker ~/CyberDotfiles/scripts/wall-picker.sh", tip: "Wallpaper" },
    { icon: "󰂚", action: "swaync-client -t", tip: "Notifications" },
    { icon: "󰀻", action: "rofi -show drun", tip: "Launcher" },
    { icon: "⏻", action: "wlogout", tip: "Power" },
  ]

  return (
    <box class="cc-row shortcuts" spacing={8}>
      {shortcuts.map(s => (
        <button
          class="cc-shortcut-btn"
          onClicked={() => execAsync(s.action)}
          tooltipText={s.tip}
        >
          <label label={s.icon} />
        </button>
      ))}
    </box>
  )
}

// ── Control Center window ───────────────────────────────────
export default function ControlCenter() {
  const { TOP, RIGHT } = Astal.WindowAnchor

  return (
    <window
      name="control-center"
      class="ControlCenter"
      anchor={TOP | RIGHT}
      application={app}
      visible={false}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.ON_DEMAND}
      // Close on Escape
      onKeyPressEvent={(self: any, event: Gdk.Event) => {
        if (event.get_keyval()[1] === Gdk.KEY_Escape) {
          self.visible = false
        }
      }}
    >
      <box class="cc-panel" vertical spacing={8}>
        <box class="cc-header" spacing={8}>
          <label class="cc-title" label="NEBULA CONTROL" />
          <box hexpand />
          <button
            class="cc-close"
            onClicked={() => {
              const win = app.get_window("control-center")
              if (win) win.visible = false
            }}
          >
            <label label="✕" />
          </button>
        </box>

        <VolumeRow />
        <BrightnessRow />
        <ConnectivityRow />
        <PowerRow />
        <MediaRow />
        <StatusRow />

        <box class="cc-divider" />

        <Shortcuts />
      </box>
    </window>
  )
}
