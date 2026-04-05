import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
import { createState, createComputed, createBinding } from "ags"
import GLib from "gi://GLib"
import Gtk4LayerShell from "gi://Gtk4LayerShell?version=1.0"
import Hyprland from "gi://AstalHyprland?version=0.1"
import Wp from "gi://AstalWp?version=0.1"
import { currentNotification } from "../lib/notifications"

const hyprland = Hyprland.get_default()
const wp = Wp.get_default()!
const audio = wp.audio!

// ── Workspaces ──────────────────────────────────

function Workspaces() {
  const buttons = [1, 2, 3, 4, 5]
  const workspaces = createBinding(hyprland, "workspaces")
  const focused = createBinding(hyprland, "focusedWorkspace")

  return (
    <box cssClasses={["workspaces"]}>
      {buttons.map((id) => {
        const classes = createComputed(() => {
          const ws = workspaces() || []
          const fw = focused()
          const fid = fw ? fw.get_id() : 0
          const occupied = new Set((ws as Hyprland.Workspace[]).map((w) => w.get_id()))
          const cls = ["workspace-btn"]
          if (id === fid) cls.push("active")
          else if (!occupied.has(id)) cls.push("empty")
          return cls
        })
        return (
          <button
            cssClasses={classes}
            onClicked={() => hyprland.dispatch("workspace", String(id))}
          >
            <label label={String(id)} />
          </button>
        )
      })}
    </box>
  )
}

// ── Clock ────────────────────────────────────────

function Clock() {
  const fmt = "%A, %d %B  %H:%M"
  const [time, setTime] = createState(GLib.DateTime.new_now_local()!.format(fmt)!)

  GLib.timeout_add(GLib.PRIORITY_DEFAULT, 30000, () => {
    setTime(GLib.DateTime.new_now_local()!.format(fmt)!)
    return GLib.SOURCE_CONTINUE
  })

  return <label label={time} cssClasses={["clock"]} />
}

// ── Audio ────────────────────────────────────────

function Audio() {
  const speaker = createBinding(audio, "defaultSpeaker")

  const volumeLabel = createComputed(() => {
    const s = speaker()
    if (!s) return "󰕾 --"
    const vol = s.get_volume()
    const mute = s.get_mute()
    if (mute) return "󰖁 muted"
    return `󰕾 ${Math.round(vol * 100)}%`
  })

  return (
    <button
      cssClasses={["bar-module"]}
      onClicked={() => {
        const s = audio.get_default_speaker()
        if (s) s.set_mute(!s.get_mute())
      }}
    >
      <label label={volumeLabel} />
    </button>
  )
}

// ── Center (clock + notification + expand) ───────

const [expanded, setExpanded] = createState(false)
const [collapsing, setCollapsing] = createState(false)
const centerWindows: Gtk.Window[] = []

function collapse() {
  setCollapsing(true)   // switch revealer to 0ms duration
  setExpanded(false)    // instant close (no animation frames = no reflow blink)
  for (const win of centerWindows) win.set_default_size(-1, 34)
  GLib.idle_add(GLib.PRIORITY_DEFAULT, () => {
    setCollapsing(false) // restore 200ms for next expand
    return GLib.SOURCE_REMOVE
  })
}

// Auto-collapse when notification clears
currentNotification.subscribe(() => {
  if (!currentNotification.peek()) collapse()
})

function Center() {
  const fullText = createComputed(() => {
    const notif = currentNotification()
    if (!notif) return ""
    return notif.body ? `${notif.summary}  ${notif.body}` : notif.summary
  })

  const previewText = createComputed(() => {
    const text = fullText()
    if (text.length <= 80) return text
    return expanded() ? text.slice(0, 80) : text.slice(0, 77) + "..."
  })

  // The remaining text that didn't fit in the preview
  const remainingText = createComputed(() => {
    const text = fullText()
    return text.length > 80 ? text.slice(80) : ""
  })

  const hasRemaining = createComputed(() => remainingText() !== "")

  const hasNotif = currentNotification.as((n) => n !== null)
  const showClock = currentNotification.as((n) => n === null)

  const centerClasses = createComputed(() => {
    const notif = currentNotification()
    const exp = expanded()
    const cls = ["center-section"]
    if (notif) cls.push(`urgency-${notif.urgency}`)
    if (exp) cls.push("expanded")
    return cls
  })

  return (
    <box halign={Gtk.Align.CENTER}>
    <button
      cssClasses={centerClasses}
      onClicked={() => {
        if (!currentNotification.peek()) return
        if (expanded.peek()) collapse()
        else setExpanded(true)
      }}
    >
      <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER}>
        {/* Clock */}
        <box visible={showClock} halign={Gtk.Align.CENTER}>
          <Clock />
        </box>
        {/* Notification preview — always visible */}
        <box visible={hasNotif}>
          <label label={previewText} cssClasses={["notif-text"]} ellipsize={3} />
        </box>
        {/* Continuation text — slides down below preview */}
        <revealer
          revealChild={createComputed(() => expanded() && hasRemaining())}
          transitionType={Gtk.RevealerTransitionType.SLIDE_DOWN}
          transitionDuration={collapsing.as((c) => c ? 0 : 200)}
        >
          <label
            label={remainingText}
            cssClasses={["notif-text"]}
            wrap
            maxWidthChars={80}
            xalign={0}
          />
        </revealer>
      </box>
    </button>
    </box>
  )
}

// ── Bar ──────────────────────────────────────────

export default function Bar(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  // Invisible spacer — full width, reserves 34px exclusive zone
  const spacer = (
    <window
      visible
      name="bar-spacer"
      namespace="bar-spacer"
      cssClasses={["bar-spacer"]}
      gdkmonitor={gdkmonitor}
      anchor={TOP | LEFT | RIGHT}
      layer={Astal.Layer.BOTTOM}
      application={app}
    >
      <box />
    </window>
  ) as Gtk.Window

  Gtk4LayerShell.set_exclusive_zone(spacer, 34)

  // Left window — workspaces
  const leftWin = (
    <window
      visible
      name="bar-left"
      namespace="bar-left"
      cssClasses={["bar-window"]}
      gdkmonitor={gdkmonitor}
      anchor={TOP | LEFT}
      exclusivity={Astal.Exclusivity.IGNORE}
      layer={Astal.Layer.TOP}
      application={app}
    >
      <box cssClasses={["bar-left-inner"]} heightRequest={34}>
        <Workspaces />
      </box>
    </window>
  )

  // Center window — clock/notification/expand, can grow freely
  const centerWin = (
    <window
      visible
      name="bar-center"
      namespace="bar-center"
      cssClasses={["bar-window"]}
      gdkmonitor={gdkmonitor}
      anchor={TOP | LEFT | RIGHT}
      exclusivity={Astal.Exclusivity.IGNORE}
      layer={Astal.Layer.TOP}
      application={app}
    >
      <Center />
    </window>
  ) as Gtk.Window

  // Force window to always shrink-wrap to content
  centerWin.set_default_size(-1, 34)
  centerWindows.push(centerWin)

  // Right window — audio, fixed 34px
  const rightWin = (
    <window
      visible
      name="bar-right"
      namespace="bar-right"
      cssClasses={["bar-window"]}
      gdkmonitor={gdkmonitor}
      anchor={TOP | RIGHT}
      exclusivity={Astal.Exclusivity.IGNORE}
      layer={Astal.Layer.TOP}
      application={app}
    >
      <box cssClasses={["bar-right-inner"]} heightRequest={34}>
        <Audio />
      </box>
    </window>
  )

  return [spacer, leftWin, centerWin, rightWin]
}
