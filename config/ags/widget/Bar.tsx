// CYBERTUNG // NEBULA CONTROL DECK — Bar
// AGS v3 + GTK3 + AstalHyprland

import app from "ags/gtk3/app"
import { Astal, Gtk, Gdk } from "ags/gtk3"
import { execAsync } from "ags/process"
import { createPoll, interval } from "ags/time"
import Hyprland from "gi://AstalHyprland"
import {
  getVolume, toggleMute,
  getBrightness,
  getBattery,
  getNetwork,
} from "../lib/system"

function setClass(widget: Gtk.Widget, name: string, enable: boolean) {
  const ctx = widget.get_style_context()
  if (enable) ctx.add_class(name)
  else ctx.remove_class(name)
}

// ── Workspaces ──────────────────────────────────────────────
function Workspaces() {
  const hypr = Hyprland.get_default()

  return (
    <box class="workspaces">
      {[1, 2, 3, 4, 5, 6].map(id => (
        <button
          class="ws-btn"
          tooltipText={`Workspace ${id}`}
          onClicked={() => hypr.dispatch("workspace", String(id))}
          $={(self: Gtk.Button) => {
            const update = () => {
              try {
                const focused = hypr.get_focused_workspace()
                const active = focused ? focused.get_id() === id : false
                const workspaces = hypr.get_workspaces() || []
                const occupied = workspaces.some(
                  (w: any) => w.get_id() === id && (w.get_clients() || []).length > 0
                )
                setClass(self, "active", active)
                setClass(self, "occupied", occupied)
              } catch (e) {
                console.error("Workspace update error:", e)
              }
            }
            update()
            hypr.connect("notify::focused-workspace", update)
            hypr.connect("notify::workspaces", update)
            hypr.connect("notify::clients", update)
          }}
        >
          <label label={String(id)} />
        </button>
      ))}
    </box>
  )
}

// ── Active Window ───────────────────────────────────────────
function ActiveWindow() {
  const hypr = Hyprland.get_default()

  return (
    <box class="active-window">
      <label
        class="win-title"
        truncate
        maxWidthChars={42}
        $={(self: Gtk.Label) => {
          const update = () => {
            try {
              const client = hypr.get_focused_client()
              const title = client ? client.get_title() || "" : ""
              self.set_text(title)
              self.set_tooltip_text(title)
            } catch {
              self.set_text("")
            }
          }
          update()
          hypr.connect("notify::focused-client", update)
        }}
      />
    </box>
  )
}

// ── Clock ───────────────────────────────────────────────────
function Clock() {
  const time = createPoll("", 1000, "date +'%H:%M'")
  const date = createPoll("", 60000, "date +'%a %d %b'")

  return (
    <button
      class="clock"
      tooltipText="Open Notifications (Super+I)"
      onClicked={() => execAsync("swaync-client -t")}
    >
      <box spacing={6}>
        <label class="clock-time" label={time} />
        <label class="clock-sep" label="·" />
        <label class="clock-date" label={date} />
      </box>
    </button>
  )
}

// ── System Tray Indicators ──────────────────────────────────
function SysTray() {
  let volLabel: Gtk.Label
  let volBtn: Gtk.Button
  let briLabel: Gtk.Label
  let netLabel: Gtk.Label
  let batLabel: Gtk.Label

  return (
    <box class="systray" spacing={3}>
      {/* Volume */}
      <button
        class="sys-btn volume-btn"
        tooltipText="Click to toggle Mute"
        onClicked={() => {
          toggleMute().then(() => {
            getVolume().then(v => {
              if (volLabel) volLabel.set_text(`${v.icon} ${v.text}`)
              if (volBtn) setClass(volBtn, "muted", v.muted)
            })
          })
        }}
        $={(self: Gtk.Button) => {
          volBtn = self
          const update = () => getVolume().then(v => {
            if (volLabel) volLabel.set_text(`${v.icon} ${v.text}`)
            setClass(self, "muted", v.muted)
          })
          update()
          interval(3000, update)
        }}
      >
        <label label="󰕾 --" $={(self: Gtk.Label) => { volLabel = self }} />
      </button>

      {/* Brightness */}
      <button
        class="sys-btn brightness-btn"
        tooltipText="Display Brightness"
        $={() => {
          const update = () => getBrightness().then(b => {
            if (briLabel) briLabel.set_text(`${b.icon} ${b.text}`)
          })
          update()
          interval(5000, update)
        }}
      >
        <label label="󰃟 --" $={(self: Gtk.Label) => { briLabel = self }} />
      </button>

      {/* Network */}
      <button
        class="sys-btn network-btn"
        tooltipText="Network Connections"
        onClicked={() => execAsync("nm-connection-editor")}
        $={() => {
          const update = () => getNetwork().then(n => {
            if (netLabel) {
              const display = n.name.length > 12 ? n.name.substring(0, 10) + "…" : n.name
              netLabel.set_text(`${n.icon} ${display}`)
            }
          })
          update()
          interval(10000, update)
        }}
      >
        <label label="󰤭 Offline" $={(self: Gtk.Label) => { netLabel = self }} />
      </button>

      {/* Battery */}
      <button
        class="sys-btn battery-btn"
        tooltipText="Battery Status"
        $={(self: Gtk.Button) => {
          const update = () => getBattery().then(b => {
            if (!b.present) {
              self.visible = false
              return
            }
            self.visible = true
            if (batLabel) batLabel.set_text(`${b.icon} ${b.pct}%`)
            setClass(self, "low", b.pct <= 18 && !b.charging)
            setClass(self, "charging", b.charging)
          })
          update()
          interval(15000, update)
        }}
      >
        <label label="󰂑 --" $={(self: Gtk.Label) => { batLabel = self }} />
      </button>
    </box>
  )
}

// ── Control Center Toggle Button ────────────────────────────
function CCToggle() {
  return (
    <button
      class="cc-toggle"
      tooltipText="Toggle Control Deck (Super+B)"
      onClicked={() => {
        const win = app.get_window("control-center")
        if (win) win.visible = !win.visible
      }}
    >
      <label label="󱄅" />
    </button>
  )
}

// ── Bar Assembly ────────────────────────────────────────────
export default function Bar(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  return (
    <window
      class="Bar"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={app}
    >
      <centerbox class="bar-inner">
        <box $type="start" spacing={8}>
          <Workspaces />
          <ActiveWindow />
        </box>
        <box $type="center">
          <Clock />
        </box>
        <box $type="end" spacing={4}>
          <SysTray />
          <CCToggle />
        </box>
      </centerbox>
    </window>
  )
}
