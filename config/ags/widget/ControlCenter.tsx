// CYBERTUNG // NEBULA CONTROL DECK — Control Center
// Orbital Cybernetic Control Surface with interactive sliders and real system telemetry

import app from "ags/gtk3/app"
import { Astal, Gtk, Gdk } from "ags/gtk3"
import { execAsync } from "ags/process"
import { interval } from "ags/time"
import {
  getVolume, setVolume, toggleMute,
  getBrightness, setBrightness,
  getBattery,
  getNetwork,
  getBluetooth,
  getPowerProfile, cyclePowerProfile,
  getMediaPlayer, mediaPlayPause, mediaNext, mediaPrev,
  getCpuTemp,
} from "../lib/system"

function setClass(widget: Gtk.Widget, name: string, enable: boolean) {
  const ctx = widget.get_style_context()
  if (enable) ctx.add_class(name)
  else ctx.remove_class(name)
}

// ── Volume Slider Row ───────────────────────────────────────
function VolumeControl() {
  let sliderRef: Astal.Slider
  let labelRef: Gtk.Label
  let iconRef: Gtk.Label
  let muteBtnRef: Gtk.Button

  const syncState = () => {
    getVolume().then(v => {
      if (sliderRef && !sliderRef.get_dragging()) {
        sliderRef.set_value(v.volume)
      }
      if (labelRef) {
        labelRef.set_text(v.muted ? "MUTED" : `${v.volume}%`)
      }
      if (iconRef) {
        iconRef.set_text(v.icon)
      }
      if (muteBtnRef) {
        setClass(muteBtnRef, "active", !v.muted)
        setClass(muteBtnRef, "muted", v.muted)
      }
    })
  }

  return (
    <box class="cc-card volume-card" vertical spacing={6}>
      <box spacing={10}>
        <button
          class="cc-icon-btn"
          tooltipText="Toggle Mute"
          onClicked={() => {
            toggleMute().then(syncState)
          }}
          $={(self: Gtk.Button) => {
            muteBtnRef = self
          }}
        >
          <label label="󰕾" $={(self: Gtk.Label) => { iconRef = self }} />
        </button>

        <slider
          class="cc-slider volume-slider"
          hexpand
          $={(self: Astal.Slider) => {
            sliderRef = self
            self.set_range(0, 100)
            syncState()
            interval(2000, syncState)
          }}
          onDragged={(self: Astal.Slider) => {
            const val = Math.round(self.get_value())
            if (labelRef) labelRef.set_text(`${val}%`)
            setVolume(val)
          }}
        />

        <label
          class="cc-val-badge"
          label="--%"
          $={(self: Gtk.Label) => { labelRef = self }}
        />
      </box>
    </box>
  )
}

// ── Brightness Slider Row ───────────────────────────────────
function BrightnessControl() {
  let sliderRef: Astal.Slider
  let labelRef: Gtk.Label
  let iconRef: Gtk.Label

  const syncState = () => {
    getBrightness().then(b => {
      if (sliderRef && !sliderRef.get_dragging()) {
        sliderRef.set_value(b.percent)
      }
      if (labelRef) {
        labelRef.set_text(`${b.percent}%`)
      }
      if (iconRef) {
        iconRef.set_text(b.icon)
      }
    })
  }

  return (
    <box class="cc-card brightness-card" vertical spacing={6}>
      <box spacing={10}>
        <button
          class="cc-icon-btn static"
          tooltipText="Screen Brightness"
        >
          <label label="󰃟" $={(self: Gtk.Label) => { iconRef = self }} />
        </button>

        <slider
          class="cc-slider brightness-slider"
          hexpand
          $={(self: Astal.Slider) => {
            sliderRef = self
            self.set_range(5, 100)
            syncState()
            interval(4000, syncState)
          }}
          onDragged={(self: Astal.Slider) => {
            const val = Math.round(self.get_value())
            if (labelRef) labelRef.set_text(`${val}%`)
            setBrightness(val)
          }}
        />

        <label
          class="cc-val-badge"
          label="--%"
          $={(self: Gtk.Label) => { labelRef = self }}
        />
      </box>
    </box>
  )
}

// ── Quick Toggle Grid ───────────────────────────────────────
function TogglesGrid() {
  let netLabel: Gtk.Label
  let netBtn: Gtk.Button
  let btLabel: Gtk.Label
  let btBtn: Gtk.Button
  let profLabel: Gtk.Label

  return (
    <box class="cc-grid" spacing={8} homogeneous>
      {/* Network */}
      <button
        class="cc-tile network-tile"
        tooltipText="Configure Network"
        onClicked={() => execAsync("nm-connection-editor")}
        $={(self: Gtk.Button) => {
          netBtn = self
          const update = () => getNetwork().then(n => {
            if (netLabel) {
              const display = n.name.length > 11 ? n.name.substring(0, 9) + "…" : n.name
              netLabel.set_text(`${n.icon} ${display}`)
            }
            setClass(self, "active", n.type === "wifi" || n.type === "ethernet")
          })
          update()
          interval(10000, update)
        }}
      >
        <label label="󰤭 Offline" $={(self: Gtk.Label) => { netLabel = self }} />
      </button>

      {/* Bluetooth */}
      <button
        class="cc-tile bluetooth-tile"
        tooltipText="Manage Bluetooth"
        onClicked={() => execAsync("blueman-manager")}
        $={(self: Gtk.Button) => {
          btBtn = self
          const update = () => getBluetooth().then(b => {
            if (btLabel) btLabel.set_text(`${b.icon} ${b.text}`)
            setClass(self, "active", b.powered)
          })
          update()
          interval(10000, update)
        }}
      >
        <label label="󰂲 Disabled" $={(self: Gtk.Label) => { btLabel = self }} />
      </button>

      {/* Power Profile */}
      <button
        class="cc-tile power-tile"
        tooltipText="Cycle Power Profile"
        onClicked={() => {
          cyclePowerProfile().then(() => {
            getPowerProfile().then(p => {
              if (profLabel) profLabel.set_text(`${p.icon} ${p.text}`)
            })
          })
        }}
        $={() => {
          const update = () => getPowerProfile().then(p => {
            if (profLabel) profLabel.set_text(`${p.icon} ${p.text}`)
          })
          update()
          interval(5000, update)
        }}
      >
        <label label="󰾆 Balanced" $={(self: Gtk.Label) => { profLabel = self }} />
      </button>

      {/* SwayNC / DND */}
      <button
        class="cc-tile dnd-tile"
        tooltipText="Open Notifications"
        onClicked={() => execAsync("swaync-client -t")}
      >
        <label label="󰂚 Alerts" />
      </button>
    </box>
  )
}

// ── Media Player Deck ───────────────────────────────────────
function MediaDeck() {
  let container: Gtk.Box
  let titleLabel: Gtk.Label
  let artistLabel: Gtk.Label
  let playPauseIcon: Gtk.Label

  return (
    <box
      class="cc-card media-deck"
      vertical
      spacing={8}
      $={(self: Gtk.Box) => {
        container = self
        const update = () => getMediaPlayer().then(m => {
          if (!container) return
          if (!m) {
            container.visible = false
            return
          }
          container.visible = true
          if (titleLabel) titleLabel.set_text(m.title)
          if (artistLabel) artistLabel.set_text(m.artist)
          if (playPauseIcon) playPauseIcon.set_text(m.isPlaying ? "󰏤" : "󰐊")
        })
        update()
        interval(3000, update)
      }}
    >
      <box spacing={10}>
        <box class="media-art-placeholder">
          <label label="" />
        </box>
        <box vertical hexpand valign={Gtk.Align.CENTER}>
          <label
            class="media-track-title"
            label="Nothing Playing"
            truncate
            xalign={0}
            maxWidthChars={26}
            $={(self: Gtk.Label) => { titleLabel = self }}
          />
          <label
            class="media-track-artist"
            label="Offline"
            truncate
            xalign={0}
            maxWidthChars={26}
            $={(self: Gtk.Label) => { artistLabel = self }}
          />
        </box>
        <box spacing={4} valign={Gtk.Align.CENTER}>
          <button
            class="media-btn"
            tooltipText="Previous Track"
            onClicked={() => mediaPrev()}
          >
            <label label="󰒮" />
          </button>
          <button
            class="media-btn primary"
            tooltipText="Play / Pause"
            onClicked={() => mediaPlayPause()}
          >
            <label label="󰐊" $={(self: Gtk.Label) => { playPauseIcon = self }} />
          </button>
          <button
            class="media-btn"
            tooltipText="Next Track"
            onClicked={() => mediaNext()}
          >
            <label label="󰒭" />
          </button>
        </box>
      </box>
    </box>
  )
}

// ── Telemetry Row (Battery & CPU) ───────────────────────────
function TelemetryRow() {
  let batLabel: Gtk.Label
  let batBox: Gtk.Box
  let tempLabel: Gtk.Label

  return (
    <box class="cc-telemetry" spacing={8}>
      <box
        class="telem-item battery-telem"
        spacing={6}
        hexpand
        $={(self: Gtk.Box) => {
          batBox = self
          const update = () => getBattery().then(b => {
            if (!b.present) {
              if (batLabel) batLabel.set_text("󰂑 AC Connected")
              return
            }
            if (batLabel) {
              const chg = b.charging ? " ⚡" : ""
              batLabel.set_text(`${b.icon} ${b.pct}%${chg}`)
            }
          })
          update()
          interval(15000, update)
        }}
      >
        <label label="󰁹 --%" $={(self: Gtk.Label) => { batLabel = self }} />
      </box>

      <box
        class="telem-item cpu-telem"
        spacing={6}
        hexpand
        $={() => {
          const update = () => getCpuTemp().then(t => {
            if (tempLabel) tempLabel.set_text(t.text)
          })
          update()
          interval(10000, update)
        }}
      >
        <label label=" --°C" $={(self: Gtk.Label) => { tempLabel = self }} />
      </box>
    </box>
  )
}

// ── Quick Command Shortcuts ─────────────────────────────────
function Shortcuts() {
  const shortcuts = [
    { icon: "󰸉", label: "Wallpaper", cmd: "kitty --class wall-picker ~/CyberDotfiles/scripts/wall-picker.sh" },
    { icon: "󰀻", label: "Launcher", cmd: "rofi -show drun" },
    { icon: "󰂚", label: "Alerts", cmd: "swaync-client -t" },
    { icon: "⏻", label: "Power", cmd: "wlogout" },
  ]

  return (
    <box class="cc-shortcuts" spacing={8} homogeneous>
      {shortcuts.map(s => (
        <button
          class="cc-launch-btn"
          tooltipText={s.label}
          onClicked={() => execAsync(s.cmd)}
        >
          <label label={s.icon} />
        </button>
      ))}
    </box>
  )
}

// ── Control Center Window Assembly ──────────────────────────
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
      <box class="cc-panel" vertical spacing={10}>
        {/* Header */}
        <box class="cc-header" spacing={8}>
          <box vertical spacing={2}>
            <label class="cc-title" label="ASTRAL SIGNAL" xalign={0} />
            <label class="cc-subtitle" label="ORBITAL CONTROL DECK" xalign={0} />
          </box>
          <box hexpand />
          <button
            class="cc-close-btn"
            tooltipText="Close (Esc)"
            onClicked={() => {
              const win = app.get_window("control-center")
              if (win) win.visible = false
            }}
          >
            <label label="✕" />
          </button>
        </box>

        {/* Sliders */}
        <VolumeControl />
        <BrightnessControl />

        {/* Quick Toggles */}
        <TogglesGrid />

        {/* Media Deck */}
        <MediaDeck />

        {/* Telemetry */}
        <TelemetryRow />

        {/* Launchers */}
        <Shortcuts />
      </box>
    </window>
  )
}
