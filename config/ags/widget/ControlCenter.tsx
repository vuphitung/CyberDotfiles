// CYBERTUNG // NEBULA CONTROL DECK — Control Center
// Floating panel toggled from the bar

import app from "ags/gtk3/app"
import { Astal, Gtk, Gdk } from "ags/gtk3"
import { execAsync } from "ags/process"
import { interval } from "ags/time"
import {
  getVolume, getBrightness, getBattery, getNetwork,
  getBluetooth, getPowerProfile, getMediaPlayer, getCpuTemp,
} from "../lib/system"

// ── Volume slider row ───────────────────────────────────────
function VolumeRow() {
  let volLabel: Gtk.Label

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
        label="󰕾 ?"
        $={(self: Gtk.Label) => {
          volLabel = self
          const update = () => getVolume().then(v => {
            if (volLabel) volLabel.set_text(v)
          })
          update()
          interval(2000, update)
        }}
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
  let briLabel: Gtk.Label

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
        label="󰃟 ?"
        $={(self: Gtk.Label) => {
          briLabel = self
          const update = () => getBrightness().then(v => {
            if (briLabel) briLabel.set_text(v)
          })
          update()
          interval(5000, update)
        }}
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
  let netLabel: Gtk.Label
  let btLabel: Gtk.Label

  return (
    <box class="cc-row" spacing={12}>
      <button
        class="cc-chip"
        onClicked={() => execAsync("nm-connection-editor")}
        $={() => {
          const update = () => getNetwork().then(v => {
            if (netLabel) netLabel.set_text(v)
          })
          update()
          interval(10000, update)
        }}
      >
        <label label="󰤭 ?" $={(self: Gtk.Label) => { netLabel = self }} />
      </button>
      <button
        class="cc-chip"
        onClicked={() => execAsync("blueman-manager")}
        $={() => {
          const update = () => getBluetooth().then(v => {
            if (btLabel) btLabel.set_text(v)
          })
          update()
          interval(10000, update)
        }}
      >
        <label label="󰂲" $={(self: Gtk.Label) => { btLabel = self }} />
      </button>
    </box>
  )
}

// ── Battery + Power profile ─────────────────────────────────
function PowerRow() {
  let batLabel: Gtk.Label
  let profLabel: Gtk.Label

  return (
    <box class="cc-row" spacing={12}>
      <label
        class="cc-value battery-cc"
        label="󰂑 ?"
        $={(self: Gtk.Label) => {
          batLabel = self
          const update = () => getBattery().then(b => {
            if (!batLabel) return
            if (b.pct < 0) { batLabel.set_text("No battery"); return }
            batLabel.set_text(`${b.icon} ${b.pct}%${b.charging ? " ⚡" : ""}`)
          })
          update()
          interval(15000, update)
        }}
      />
      <button
        class="cc-chip power-profile"
        onClicked={() => execAsync("bash -c \"P=$(powerprofilesctl get); case $P in balanced) powerprofilesctl set power-saver;; power-saver) powerprofilesctl set performance;; *) powerprofilesctl set balanced;; esac\"")}
        $={() => {
          const update = () => getPowerProfile().then(v => {
            if (profLabel) profLabel.set_text(v)
          })
          update()
          interval(5000, update)
        }}
      >
        <label label="?" $={(self: Gtk.Label) => { profLabel = self }} />
      </button>
    </box>
  )
}

// ── Media player ────────────────────────────────────────────
function MediaRow() {
  let mediaBox: Gtk.Box
  let titleLabel: Gtk.Label
  let artistLabel: Gtk.Label

  return (
    <box
      class="cc-row media-row"
      spacing={8}
      $={(self: Gtk.Box) => {
        mediaBox = self
        const update = () => getMediaPlayer().then(m => {
          if (!mediaBox) return
          mediaBox.visible = m !== null
          if (!m) return
          if (titleLabel) titleLabel.set_text(`♫ ${m.title}`)
          if (artistLabel) artistLabel.set_text(m.artist)
        })
        update()
        interval(3000, update)
      }}
    >
      <label
        class="media-title"
        label="♫"
        truncate
        maxWidthChars={35}
        $={(self: Gtk.Label) => { titleLabel = self }}
      />
      <label
        class="media-artist"
        label=""
        truncate
        maxWidthChars={25}
        $={(self: Gtk.Label) => { artistLabel = self }}
      />
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
  let tempLabel: Gtk.Label

  return (
    <box class="cc-row status-row" spacing={12}>
      <label
        class="cc-value"
        label=" ?"
        $={(self: Gtk.Label) => {
          tempLabel = self
          const update = () => getCpuTemp().then(v => {
            if (tempLabel) tempLabel.set_text(v)
          })
          update()
          interval(10000, update)
        }}
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
      onKeyPressEvent={(self: any, event: Gdk.Event) => {
        try {
          if (event.get_keyval()[1] === Gdk.KEY_Escape) {
            self.visible = false
          }
        } catch { /* ignore */ }
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
