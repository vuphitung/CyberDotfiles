// CYBERTUNG // NEBULA CONTROL DECK — Bar
// AGS v3 + GTK3 + AstalHyprland

import app from "ags/gtk3/app"
import { Astal, Gtk, Gdk } from "ags/gtk3"
import { execAsync } from "ags/process"
import { createPoll, interval } from "ags/time"
import Hyprland from "gi://AstalHyprland"
import { getVolume, getBattery, getNetwork, getBrightness } from "../lib/system"

// ── Workspaces ──────────────────────────────────────────────
function Workspaces() {
  const hypr = Hyprland.get_default()

  return (
    <box class="workspaces">
      {Array.from({ length: 6 }, (_, i) => i + 1).map(id => (
        <button
          class="ws-btn"
          onClicked={() => hypr.dispatch("workspace", String(id))}
          setup={(self: Gtk.Button) => {
            const update = () => {
              const active = hypr.get_focused_workspace()?.get_id() === id
              const occupied = hypr.get_workspaces().some(
                (w: any) => w.get_id() === id && w.get_clients().length > 0
              )
              self.toggleClassName("active", active)
              self.toggleClassName("occupied", occupied)
            }
            update()
            hypr.connect("notify::focused-workspace", update)
            hypr.connect("workspace-added", update)
            hypr.connect("workspace-removed", update)
            hypr.connect("client-added", update)
            hypr.connect("client-removed", update)
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
        setup={(self: Gtk.Label) => {
          const update = () => {
            const client = hypr.get_focused_client()
            self.label = client?.get_title() || ""
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
  return (
    <box class="systray" spacing={2}>
      {/* Volume */}
      <button
        class="sys-btn"
        onClicked={() => execAsync("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")}
        setup={(self: Gtk.Button) => {
          const update = () => getVolume().then(v => {
            (self.get_child() as Gtk.Label).label = v
          })
          update()
          interval(3000, update)
        }}
      >
        <label label="󰕾 ?" />
      </button>

      {/* Brightness */}
      <button
        class="sys-btn"
        setup={(self: Gtk.Button) => {
          const update = () => getBrightness().then(v => {
            (self.get_child() as Gtk.Label).label = v
          })
          update()
          interval(5000, update)
        }}
      >
        <label label="󰃟 ?" />
      </button>

      {/* Network */}
      <button
        class="sys-btn"
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

      {/* Battery */}
      <button
        class="sys-btn battery"
        setup={(self: Gtk.Button) => {
          const update = () => getBattery().then(b => {
            if (b.pct < 0) {
              self.visible = false
              return
            }
            self.visible = true
            ;(self.get_child() as Gtk.Label).label = `${b.icon} ${b.pct}%`
            self.toggleClassName("low", b.pct <= 15)
            self.toggleClassName("charging", b.charging)
          })
          update()
          interval(15000, update)
        }}
      >
        <label label="󰂑 ?" />
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
