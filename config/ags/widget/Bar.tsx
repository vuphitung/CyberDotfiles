// CYBERTUNG // NEBULA CONTROL DECK — Bar
// AGS v3 + GTK3 + AstalHyprland

import app from "ags/gtk3/app"
import { Astal, Gtk, Gdk } from "ags/gtk3"
import { execAsync } from "ags/process"
import { createPoll, interval } from "ags/time"
import Hyprland from "gi://AstalHyprland"
import { getVolume, getBattery, getNetwork, getBrightness } from "../lib/system"

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
      {Array.from({ length: 6 }, (_, i) => i + 1).map(id => (
        <button
          class="ws-btn"
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
                console.error(e)
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
        maxWidthChars={50}
        $={(self: Gtk.Label) => {
          const update = () => {
            try {
              const client = hypr.get_focused_client()
              self.set_text(client ? client.get_title() || "" : "")
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
      onClicked={() => execAsync("bash -c 'swaync-client -t'")}
    >
      <box>
        <label class="clock-time" label={time} />
        <label class="clock-sep" label="·" />
        <label class="clock-date" label={date} />
      </box>
    </button>
  )
}

// ── System tray module with polling ─────────────────────────
function SysTray() {
  let volLabel: Gtk.Label
  let briLabel: Gtk.Label
  let netLabel: Gtk.Label
  let batLabel: Gtk.Label

  return (
    <box class="systray" spacing={2}>
      {/* Volume */}
      <button
        class="sys-btn"
        onClicked={() => execAsync("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")}
        $={() => {
          const update = () => getVolume().then(v => {
            if (volLabel) volLabel.set_text(v)
          })
          update()
          interval(3000, update)
        }}
      >
        <label label="󰕾 ?" $={(self: Gtk.Label) => { volLabel = self }} />
      </button>

      {/* Brightness */}
      <button
        class="sys-btn"
        $={() => {
          const update = () => getBrightness().then(v => {
            if (briLabel) briLabel.set_text(v)
          })
          update()
          interval(5000, update)
        }}
      >
        <label label="󰃟 ?" $={(self: Gtk.Label) => { briLabel = self }} />
      </button>

      {/* Network */}
      <button
        class="sys-btn"
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

      {/* Battery */}
      <button
        class="sys-btn battery"
        $={(self: Gtk.Button) => {
          const update = () => getBattery().then(b => {
            if (b.pct < 0) {
              self.visible = false
              return
            }
            self.visible = true
            if (batLabel) batLabel.set_text(`${b.icon} ${b.pct}%`)
            setClass(self, "low", b.pct <= 15)
            setClass(self, "charging", b.charging)
          })
          update()
          interval(15000, update)
        }}
      >
        <label label="󰂑 ?" $={(self: Gtk.Label) => { batLabel = self }} />
      </button>
    </box>
  )
}

// ── Control Center toggle button ────────────────────────────
function CCToggle() {
  return (
    <button
      class="cc-toggle"
      onClicked={() => {
        const win = app.get_window("control-center")
        if (win) win.visible = !win.visible
      }}
    >
      <label label="󱄅" />
    </button>
  )
}

// ── Bar assembly ────────────────────────────────────────────
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
