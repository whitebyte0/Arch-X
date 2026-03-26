import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createState, createComputed, For } from "ags"
import GLib from "gi://GLib"
import {
  notifd,
  dnd,
  toggleDnd,
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

function NotificationItem(entry: HistoryEntry) {
  const timeLabel = createComputed(() => {
    tick()
    return relativeTime(entry.time)
  })

  const bodyStripped = entry.body
    ? entry.body.replace(/<[^>]*>/g, "").replace(/\n/g, " ")
    : ""

  return (
    <box orientation={Gtk.Orientation.VERTICAL} cssClasses={["notification-item"]}>
      <box cssClasses={["notification-item-header"]}>
        <label label={entry.appName} cssClasses={["notification-app-name"]} />
        <label label={timeLabel} cssClasses={["notification-time"]} hexpand xalign={1} />
        <button
          cssClasses={["notification-dismiss"]}
          onClicked={() => dismissNotification(entry.id)}
        >
          <label label="✕" />
        </button>
      </box>
      <label
        label={entry.summary}
        cssClasses={["notification-item-summary"]}
        xalign={0}
        ellipsize={3}
        maxWidthChars={45}
      />
      {bodyStripped ? (
        <label
          label={bodyStripped}
          cssClasses={["notification-item-body"]}
          xalign={0}
          wrap
          maxWidthChars={45}
        />
      ) : (
        <box />
      )}
      {entry.actions.length > 0 ? (
        <box cssClasses={["notification-actions"]}>
          {entry.actions.map((action) => (
            <button
              cssClasses={["notification-action"]}
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
  const { TOP, RIGHT, BOTTOM } = Astal.WindowAnchor

  const count = history.as((h) => {
    const len = h.length
    return len === 0 ? "No notifications" : `${len} notification${len === 1 ? "" : "s"}`
  })

  const dndIcon = dnd.as((d) => d ? "󰂛" : "󰂚")
  const dndClasses = dnd.as((d) =>
    d ? ["dnd-toggle", "active"] : ["dnd-toggle"]
  )

  return (
    <window
      visible={sidebarVisible}
      name="notification-sidebar"
      cssClasses={["notification-sidebar"]}
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.NORMAL}
      anchor={TOP | RIGHT | BOTTOM}
      layer={Astal.Layer.TOP}
      application={app}
      keymode={Astal.Keymode.ON_DEMAND}
    >
      <box orientation={Gtk.Orientation.VERTICAL} cssClasses={["sidebar-container"]} widthRequest={380}>
        <box cssClasses={["sidebar-header"]}>
          <label label="Notifications" cssClasses={["sidebar-title"]} />
          <box hexpand halign={Gtk.Align.END}>
            <button cssClasses={dndClasses} onClicked={() => toggleDnd()}>
              <label label={dndIcon} />
            </button>
            <button cssClasses={["clear-all"]} onClicked={() => clearHistory()}>
              <label label="Clear" />
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
}
