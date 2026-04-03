import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createState, createComputed } from "ags"
import GLib from "gi://GLib"
import Notifd from "gi://AstalNotifd?version=0.1"
import { notifd, mode, dnd, shouldAllowNotification } from "../lib/notifications"

const TIMEOUT_LOW = 8000
const TIMEOUT_NORMAL = 12000

const _hiders: Set<() => void> = new Set()

export function dismissAll() {
  _hiders.forEach((h) => h())
}

export default function NotificationBar(gdkmonitor: Gdk.Monitor) {
  const [visible, setVisible] = createState(false)
  const [summary, setSummary] = createState("")
  const [body, setBody] = createState("")
  const [urgencyClass, setUrgencyClass] = createState("urgency-normal")

  const bodyText = body.as((b) => {
    if (!b) return ""
    const stripped = b.replace(/<[^>]*>/g, "")
    const oneline = stripped.replace(/\n/g, "  ")
    return oneline ? `  ${oneline}` : ""
  })

  const exclusivity = createComputed(() => {
    const m = mode()
    const v = visible()
    if (m === "reserved") return Astal.Exclusivity.EXCLUSIVE
    if (m === "dynamic" && v) return Astal.Exclusivity.EXCLUSIVE
    return Astal.Exclusivity.NORMAL
  })

  const windowVisible = createComputed(() => {
    if (mode() === "reserved") return true
    return visible()
  })

  let hideTimer: number | null = null

  function clearTimer() {
    if (hideTimer !== null) {
      GLib.source_remove(hideTimer)
      hideTimer = null
    }
  }

  function hide() {
    clearTimer()
    setVisible(false)
    setSummary("")
    setBody("")
  }

  _hiders.add(hide)

  function show(n: Notifd.Notification) {
    clearTimer()
    setSummary(n.summary || "")
    setBody(n.body || "")

    const urg = n.urgency
    if (urg === Notifd.Urgency.CRITICAL) {
      setUrgencyClass("urgency-critical")
    } else if (urg === Notifd.Urgency.LOW) {
      setUrgencyClass("urgency-low")
    } else {
      setUrgencyClass("urgency-normal")
    }

    setVisible(true)

    if (urg !== Notifd.Urgency.CRITICAL) {
      const ms = urg === Notifd.Urgency.LOW ? TIMEOUT_LOW : TIMEOUT_NORMAL
      hideTimer = GLib.timeout_add(GLib.PRIORITY_DEFAULT, ms, () => {
        hide()
        return GLib.SOURCE_REMOVE
      })
    }
  }

  notifd.connect("notified", (_self: Notifd.Notifd, id: number) => {
    const n = notifd.get_notification(id)
    if (!n) return
    if (shouldAllowNotification(n) && !dnd.peek()) show(n)
  })

  notifd.connect("resolved", () => {
    hide()
  })

  const { BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible={windowVisible}
      name="notification-bar"
      cssClasses={createComputed(() => ["notification-bar", urgencyClass()])}
      gdkmonitor={gdkmonitor}
      exclusivity={exclusivity}
      anchor={BOTTOM | LEFT | RIGHT}
      layer={Astal.Layer.TOP}
      application={app}
    >
      <box hexpand cssClasses={["bar-content"]}>
        <button hexpand onClicked={() => hide()} cssClasses={["notification-button"]}>
          <box hexpand>
            <label
              label={summary}
              cssClasses={["summary"]}
              ellipsize={3}
              maxWidthChars={80}
            />
            <label
              label={bodyText}
              cssClasses={["body"]}
              hexpand
              ellipsize={3}
              xalign={0}
            />
          </box>
        </button>
      </box>
    </window>
  )
}
