import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createState, createComputed } from "ags"
import Notifd from "gi://AstalNotifd?version=0.1"
import GLib from "gi://GLib"

const TIMEOUT_LOW = 8000
const TIMEOUT_NORMAL = 12000

export default function NotificationBar(gdkmonitor: Gdk.Monitor) {
  const notifd = Notifd.get_default()
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
  }

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
    if (n) show(n)
  })

  notifd.connect("resolved", () => {
    hide()
  })

  const { BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible={visible}
      name="notification-bar"
      cssClasses={createComputed(() => ["notification-bar", urgencyClass()])}
      gdkmonitor={gdkmonitor}
      exclusivity={visible.as((v) => v ? Astal.Exclusivity.EXCLUSIVE : Astal.Exclusivity.NORMAL)}
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
