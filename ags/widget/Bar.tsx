import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createState, createComputed, createBinding, For } from "ags"
import GLib from "gi://GLib"
import Gtk4LayerShell from "gi://Gtk4LayerShell?version=1.0"
import Hyprland from "gi://AstalHyprland?version=0.1"
import Wp from "gi://AstalWp?version=0.1"
import Tray from "gi://AstalTray?version=0.1"
import Network from "gi://AstalNetwork?version=0.1"
import Bluetooth from "gi://AstalBluetooth?version=0.1"
import { currentNotification } from "../lib/notifications"
import { dismissAll } from "./NotificationBar"

const hyprland = Hyprland.get_default()
const wp = Wp.get_default()!
const audio = wp.audio!
const tray = Tray.get_default()
const network = Network.get_default()
const bluetooth = Bluetooth.get_default()

// ── Workspaces ──────────────────────────────────

function getMonitorWorkspaces(gdkMonitor: Gdk.Monitor): number[] {
  const connector = gdkMonitor.get_connector()
  const monitors = (hyprland.get_monitors() as Hyprland.Monitor[])
    .slice()
    .sort((a, b) => a.get_x() - b.get_x())

  const count = monitors.length
  const perMonitor = Math.floor(10 / count)
  const remainder = 10 % count

  const index = monitors.findIndex(m => m.get_name() === connector)
  if (index < 0) return [1, 2, 3, 4, 5]

  let ws = 1
  for (let i = 0; i < index; i++) {
    ws += perMonitor + (i < remainder ? 1 : 0)
  }
  const n = perMonitor + (index < remainder ? 1 : 0)
  return Array.from({ length: n }, (_, i) => ws + i)
}

function Workspaces(wsIds: number[]) {
  const workspaces = createBinding(hyprland, "workspaces")
  const focused = createBinding(hyprland, "focusedWorkspace")

  return (
    <box cssClasses={["workspaces"]}>
      {wsIds.map((id) => {
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
  const [volumeLabel, setVolumeLabel] = createState("󰕾 --")
  let prevSpeaker: any = null
  let speakerHandlers: number[] = []

  const update = () => {
    const s = audio.get_default_speaker()
    if (!s) { setVolumeLabel("󰕾 --"); return }
    if (s.get_mute()) setVolumeLabel("󰖁 muted")
    else setVolumeLabel(`󰕾 ${Math.round(s.get_volume() * 100)}%`)
  }

  const connectSpeaker = () => {
    if (prevSpeaker) speakerHandlers.forEach(id => prevSpeaker.disconnect(id))
    speakerHandlers = []
    const s = audio.get_default_speaker()
    if (s) {
      speakerHandlers.push(s.connect("notify::volume", update))
      speakerHandlers.push(s.connect("notify::mute", update))
      prevSpeaker = s
    }
    update()
  }

  audio.connect("notify::default-speaker", connectSpeaker)
  connectSpeaker()

  return (
    <button
      cssClasses={["bar-module"]}
      onClicked={() => GLib.spawn_command_line_async("pavucontrol")}
      $={(self: Gtk.Widget) => {
        const rc = new Gtk.GestureClick({ button: 3 })
        rc.connect("released", () => {
          const s = audio.get_default_speaker()
          if (s) s.set_mute(!s.get_mute())
        })
        self.add_controller(rc)

        const scroll = new Gtk.EventControllerScroll({
          flags: Gtk.EventControllerScrollFlags.VERTICAL,
        })
        scroll.connect("scroll", (_c: any, _dx: number, dy: number) => {
          const s = audio.get_default_speaker()
          if (s) s.set_volume(Math.max(0, Math.min(1, s.get_volume() - dy * 0.05)))
        })
        self.add_controller(scroll)
      }}
    >
      <label label={volumeLabel} />
    </button>
  )
}

// ── Language ─────────────────────────────────────

const [langLabel, setLangLabel] = createState("󰌌 --")

function applyLayout(layout: string) {
  if (layout.startsWith("English")) setLangLabel("󰌌 EN")
  else if (layout.startsWith("Russian")) setLangLabel("󰌌 RU")
  else if (layout.startsWith("Armenian")) setLangLabel("󰌌 AM")
  else setLangLabel(`󰌌 ${layout.slice(0, 2).toUpperCase()}`)
}

hyprland.connect("keyboard-layout", (_self: any, _kb: string, layout: string) => applyLayout(layout))

// Init with current layout
try {
  const [ok, out] = GLib.spawn_command_line_sync("hyprctl devices -j")
  if (ok && out) {
    const devices = JSON.parse(new TextDecoder().decode(out))
    const main = devices.keyboards?.find((k: any) => k.main)
    if (main?.active_keymap) applyLayout(main.active_keymap)
  }
} catch {}

function Language() {
  return (
    <button
      cssClasses={["bar-module"]}
      onClicked={() => hyprland.dispatch("switchxkblayout", "all next")}
    >
      <label label={langLabel} />
    </button>
  )
}

// ��─ System Monitors ─────────────────────────────

function readFile(path: string): string {
  try {
    const [ok, contents] = GLib.file_get_contents(path)
    if (ok && contents) return new TextDecoder().decode(contents)
  } catch {}
  return ""
}

const [cpuLabel, setCpuLabel] = createState("󰻠 --%")
const [memLabel, setMemLabel] = createState("󰍛 --%")
const [tempLabel, setTempLabel] = createState("󰔏 --°C")

let prevIdle = 0, prevTotal = 0

GLib.timeout_add(GLib.PRIORITY_DEFAULT, 2000, () => {
  // CPU
  const statLine = readFile("/proc/stat").split("\n")[0]
  if (statLine) {
    const parts = statLine.split(/\s+/).slice(1).map(Number)
    const idle = parts[3] + (parts[4] || 0)
    const total = parts.reduce((a, b) => a + b, 0)
    if (prevTotal > 0 && total !== prevTotal) {
      const usage = 100 * (1 - (idle - prevIdle) / (total - prevTotal))
      setCpuLabel(`󰻠 ${Math.round(usage)}%`)
    }
    prevIdle = idle
    prevTotal = total
  }

  // Memory
  const meminfo = readFile("/proc/meminfo")
  const totalMatch = meminfo.match(/MemTotal:\s+(\d+)/)
  const availMatch = meminfo.match(/MemAvailable:\s+(\d+)/)
  if (totalMatch && availMatch) {
    const pct = 100 * (1 - Number(availMatch[1]) / Number(totalMatch[1]))
    setMemLabel(`󰍛 ${Math.round(pct)}%`)
  }

  // Temperature
  const tempRaw = readFile("/sys/class/thermal/thermal_zone0/temp").trim()
  if (tempRaw) setTempLabel(`󰔏 ${Math.round(Number(tempRaw) / 1000)}°C`)

  return GLib.SOURCE_CONTINUE
})

const scriptsDir = `${GLib.get_home_dir()}/.config/waybar/scripts`

function SystemMonitors() {
  return (
    <box>
      <button cssClasses={["bar-module"]} onClicked={() => GLib.spawn_command_line_async(`${scriptsDir}/cpu-info.sh`)}>
        <label label={cpuLabel} />
      </button>
      <button cssClasses={["bar-module"]} onClicked={() => GLib.spawn_command_line_async(`${scriptsDir}/memory-info.sh`)}>
        <label label={memLabel} />
      </button>
      <button cssClasses={["bar-module"]} onClicked={() => GLib.spawn_command_line_async(`${scriptsDir}/temp-info.sh`)}>
        <label label={tempLabel} />
      </button>
    </box>
  )
}

// ── Network ─────────────────────────────��───────

function NetworkModule() {
  const [netLabel, setNetLabel] = createState("󰤭")

  const update = () => {
    try {
      const wifi = network.get_wifi()
      const wired = network.get_wired()
      if (wifi && wifi.get_ssid()) {
        setNetLabel(`󰤨 ${wifi.get_ssid()}`)
      } else if (wired) {
        setNetLabel("󰈀 eth")
      } else {
        setNetLabel("󰤭")
      }
    } catch {
      setNetLabel("󰤭")
    }
  }

  update()
  GLib.timeout_add(GLib.PRIORITY_DEFAULT, 5000, () => { update(); return GLib.SOURCE_CONTINUE })

  return (
    <button cssClasses={["bar-module"]} onClicked={() => GLib.spawn_command_line_async(`${scriptsDir}/network-info.sh`)}>
      <label label={netLabel} />
    </button>
  )
}

// ── Bluetooth ───────────────────────────────────

function BluetoothModule() {
  const [btLabel, setBtLabel] = createState("")
  const [btVisible, setBtVisible] = createState(false)

  const update = () => {
    try {
      const adapters = bluetooth.get_adapters() as any[]
      if (!adapters || adapters.length === 0) { setBtVisible(false); return }
      setBtVisible(true)
      if (!bluetooth.get_is_powered()) { setBtLabel("󰂲"); return }
      const devs = bluetooth.get_devices() as Bluetooth.Device[]
      const connected = devs.find(d => d.get_connected())
      setBtLabel(connected ? `󰂯 ${connected.get_name()}` : "󰂯")
    } catch { setBtVisible(false) }
  }

  update()
  GLib.timeout_add(GLib.PRIORITY_DEFAULT, 3000, () => { update(); return GLib.SOURCE_CONTINUE })

  return (
    <button
      visible={btVisible}
      cssClasses={["bar-module"]}
      onClicked={() => GLib.spawn_command_line_async("ghostty -e bluetuith")}
    >
      <label label={btLabel} />
    </button>
  )
}

// ── System Tray ─────────────────────────────────

const [trayItems, setTrayItems] = createState<Tray.TrayItem[]>([])

// AstalTray bug: race condition during startup can produce phantom items
// with all-null properties. Filter out items with no identity.
tray.connect("notify::items", () => {
  const items = (tray.get_items() as Tray.TrayItem[])
    .filter(i => i.get_title() || i.get_icon_name() || i.get_gicon())
  setTrayItems([...items])
})

function SystemTray() {
  return (
    <box cssClasses={["system-tray"]}>
      <For each={trayItems}>
        {(item: Tray.TrayItem) => (
          <button
            cssClasses={["tray-item"]}
            onClicked={() => item.activate(0, 0)}
            $={(self: Gtk.Widget) => {
              self.insert_action_group("dbusmenu", item.get_action_group())
              const rc = new Gtk.GestureClick({ button: 3 })
              rc.connect("released", (_g: any, _n: any, x: number, y: number) => {
                const menu = item.get_menu_model()
                if (menu) {
                  const popover = new Gtk.PopoverMenu({ menuModel: menu })
                  popover.set_parent(self)
                  popover.connect("closed", () => popover.unparent())
                  popover.popup()
                } else {
                  item.secondary_activate(Math.round(x), Math.round(y))
                }
              })
              self.add_controller(rc)
            }}
          >
            {item.get_gicon()
              ? <image gicon={item.get_gicon()} iconSize={Gtk.IconSize.NORMAL} />
              : <label label={item.get_title() || "?"} />
            }
          </button>
        )}
      </For>
    </box>
  )
}

// ── Center (clock + notification + expand) ───────

export const [expanded, setExpanded] = createState(false)
const [collapsing, setCollapsing] = createState(false)
const centerWindows: Gtk.Window[] = []

export function toggleExpand() {
  if (!currentNotification.peek()) return
  if (expanded.peek()) collapse()
  else setExpanded(true)
}

function collapse() {
  setCollapsing(true)   // switch revealer to 0ms duration
  setExpanded(false)    // instant close (no animation frames = no reflow blink)
  for (const win of centerWindows) {
    try { win.set_default_size(-1, 34) } catch {}
  }
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

  const flatText = createComputed(() => fullText().replace(/\n/g, " "))

  const previewText = createComputed(() => {
    const text = flatText()
    if (text.length <= 80) return text
    return expanded() ? text.slice(0, 80) : text.slice(0, 77) + "..."
  })

  const remainingText = createComputed(() => {
    const notif = currentNotification()
    if (!notif) return ""
    // For multiline bodies, show full body when expanded
    if (notif.body && notif.body.includes("\n")) return notif.body
    // For single-line, show the overflow past 80 chars
    const text = flatText()
    return text.length > 80 ? text.slice(80) : ""
  })

  const hasRemaining = createComputed(() => remainingText() !== "" || flatText().length > 80)

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
      onClicked={() => toggleExpand()}
      $={(self: Gtk.Widget) => {
        const rc = new Gtk.GestureClick({ button: 3 })
        rc.connect("released", () => dismissAll())
        self.add_controller(rc)
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

let barIndex = 0

export default function Bar(gdkmonitor: Gdk.Monitor) {
  const wsIds = getMonitorWorkspaces(gdkmonitor)
  const id = barIndex++
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  // Invisible spacer — full width, reserves 34px exclusive zone
  const spacer = (
    <window
      visible
      name={`bar-spacer-${id}`}
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
      name={`bar-left-${id}`}
      namespace="bar-left"
      cssClasses={["bar-window"]}
      gdkmonitor={gdkmonitor}
      anchor={TOP | LEFT}
      exclusivity={Astal.Exclusivity.IGNORE}
      layer={Astal.Layer.TOP}
      application={app}
    >
      <box cssClasses={["bar-left-inner"]} heightRequest={34}>
        {Workspaces(wsIds)}
      </box>
    </window>
  )

  // Center window — clock/notification/expand, can grow freely
  const centerWin = (
    <window
      visible
      name={`bar-center-${id}`}
      namespace="bar-center"
      cssClasses={["bar-window"]}
      gdkmonitor={gdkmonitor}
      anchor={TOP}
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
      name={`bar-right-${id}`}
      namespace="bar-right"
      cssClasses={["bar-window"]}
      gdkmonitor={gdkmonitor}
      anchor={TOP | RIGHT}
      exclusivity={Astal.Exclusivity.IGNORE}
      layer={Astal.Layer.TOP}
      application={app}
    >
      <box cssClasses={["bar-right-inner"]} heightRequest={34}>
        <SystemTray />
        <box cssClasses={["bar-separator"]} />
        <SystemMonitors />
        <NetworkModule />
        <BluetoothModule />
        <Language />
        <Audio />
        <button
          cssClasses={["bar-module"]}
          onClicked={() => GLib.spawn_command_line_async(
            `wlogout --layout ${GLib.get_home_dir()}/.config/wlogout/layout --css ${GLib.get_home_dir()}/.config/wlogout/style.css -b 4 -r 1`
          )}
        >
          <label label="󰐥" />
        </button>
      </box>
    </window>
  )

  return [spacer, leftWin, centerWin, rightWin]
}
