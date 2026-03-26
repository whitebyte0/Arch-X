import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createState, createComputed, For } from "ags"
import GLib from "gi://GLib"

const pointer = new Gdk.Cursor({ name: "pointer" })
import {
  notifd,
  dnd,
  toggleDnd,
  focusDismiss,
  history,
  dismissNotification,
  clearHistory,
  relativeTime,
  type HistoryEntry,
} from "../lib/notifications"

const [sidebarVisible, setSidebarVisible] = createState(false)

const [tick, setTick] = createState(0)
GLib.timeout_add(GLib.PRIORITY_DEFAULT, 30000, () => {
  setTick(tick.peek() + 1)
  return GLib.SOURCE_CONTINUE
})

export function toggleSidebar() {
  setSidebarVisible(!sidebarVisible.peek())
}

function closeSidebar() {
  setSidebarVisible(false)
}

const scrimVisible = createComputed(() => sidebarVisible() && focusDismiss())

function NotificationItem(entry: HistoryEntry) {
  const timeLabel = createComputed(() => {
    tick()
    return relativeTime(entry.time)
  })

  const bodyFull = entry.body
    ? entry.body.replace(/<[^>]*>/g, "")
    : ""

  const isLong = bodyFull.length > 120
  const [expanded, setExpanded] = createState(false)

  const bodyText = expanded.as((exp) => {
    if (!bodyFull) return ""
    if (exp || !isLong) return bodyFull
    return bodyFull.slice(0, 120) + "…"
  })

  const expandIcon = expanded.as((exp) => exp ? "󰁝" : "󰁅")

  return (
    <box orientation={Gtk.Orientation.VERTICAL} cssClasses={["notification-item"]}>
      <box cssClasses={["notification-item-header"]}>
        <label label={entry.appName} cssClasses={["notification-app-name"]} />
        <label label={timeLabel} cssClasses={["notification-time"]} hexpand xalign={1} />
        <button
          cssClasses={["notification-dismiss"]}
          cursor={pointer}
          onClicked={() => dismissNotification(entry.id)}
        >
          <label label="󰅖" />
        </button>
      </box>
      <label
        label={entry.summary}
        cssClasses={["notification-item-summary"]}
        xalign={0}
        ellipsize={3}
        maxWidthChars={45}
      />
      {bodyFull ? (
        <box orientation={Gtk.Orientation.VERTICAL}>
          <label
            label={bodyText}
            cssClasses={["notification-item-body"]}
            xalign={0}
            wrap
            maxWidthChars={45}
          />
          {isLong ? (
            <button
              cssClasses={["notification-expand"]}
              cursor={pointer}
              onClicked={() => setExpanded(!expanded.peek())}
              halign={Gtk.Align.START}
            >
              <label label={expandIcon} />
            </button>
          ) : (
            <box />
          )}
        </box>
      ) : (
        <box />
      )}
      {entry.actions.length > 0 ? (
        <box cssClasses={["notification-actions"]}>
          {entry.actions.map((action) => (
            <button
              cssClasses={["notification-action"]}
              cursor={pointer}
              onClicked={() => {
                const n = notifd.get_notification(entry.id)
                if (n) n.invoke(action.id)
              }}
            >
              <label label={action.label} />
            </button>
          ))}
        </box>
      ) : (
        <box />
      )}
    </box>
  )
}

export default function NotificationSidebar(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT, BOTTOM } = Astal.WindowAnchor

  const count = history.as((h) => {
    const len = h.length
    return len === 0 ? "No notifications" : `${len} notification${len === 1 ? "" : "s"}`
  })

  const dndIcon = dnd.as((d) => d ? "󰂛" : "󰂚")
  const dndClasses = dnd.as((d) =>
    d ? ["dnd-toggle", "active"] : ["dnd-toggle"]
  )

  // transparent scrim — click to close sidebar
  const scrim = (
    <window
      visible={scrimVisible}
      name="notification-scrim"
      cssClasses={["notification-scrim"]}
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.NORMAL}
      anchor={TOP | LEFT | RIGHT | BOTTOM}
      layer={Astal.Layer.TOP}
      application={app}
      keymode={Astal.Keymode.NONE}
    >
      <button
        hexpand
        vexpand
        cssClasses={["scrim-button"]}
        onClicked={() => closeSidebar()}
      >
        <box />
      </button>
    </window>
  )

  const sidebar = (
    <window
      visible={sidebarVisible}
      name="notification-sidebar"
      cssClasses={["notification-sidebar"]}
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.NORMAL}
      anchor={TOP | RIGHT | BOTTOM}
      layer={Astal.Layer.TOP}
      application={app}
      keymode={Astal.Keymode.NONE}
    >
      <box orientation={Gtk.Orientation.VERTICAL} cssClasses={["sidebar-container"]} widthRequest={380}>
        <box cssClasses={["sidebar-header"]}>
          <label label="Notifications" cssClasses={["sidebar-title"]} />
          <box hexpand halign={Gtk.Align.END}>
            <button cssClasses={dndClasses} cursor={pointer} onClicked={() => toggleDnd()}>
              <label label={dndIcon} />
            </button>
            <button cssClasses={["clear-all"]} cursor={pointer} onClicked={() => clearHistory()}>
              <label label="󰩺" />
            </button>
          </box>
        </box>
        <Gtk.ScrolledWindow vexpand cssClasses={["sidebar-scroll"]}>
          <box orientation={Gtk.Orientation.VERTICAL} cssClasses={["sidebar-list"]}>
            <For each={history}>
              {(entry: HistoryEntry) => NotificationItem(entry)}
            </For>
          </box>
        </Gtk.ScrolledWindow>
        <box cssClasses={["sidebar-footer"]}>
          <label label={count} cssClasses={["sidebar-count"]} />
        </box>
      </box>
    </window>
  )

  return [scrim, sidebar]
}
