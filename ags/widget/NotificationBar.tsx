import GLib from "gi://GLib"
import Notifd from "gi://AstalNotifd?version=0.1"
import { notifd, shouldAllowNotification, setCurrentNotification, clearCurrentNotification } from "../lib/notifications"

const TIMEOUT_LOW = 8000
const TIMEOUT_NORMAL = 12000

let hideTimer: number | null = null

function clearTimer() {
  if (hideTimer !== null) {
    GLib.source_remove(hideTimer)
    hideTimer = null
  }
}

function hide() {
  clearTimer()
  clearCurrentNotification()
}

function show(n: Notifd.Notification) {
  clearTimer()
  setCurrentNotification(n)

  if (n.urgency !== Notifd.Urgency.CRITICAL) {
    const ms = n.urgency === Notifd.Urgency.LOW ? TIMEOUT_LOW : TIMEOUT_NORMAL
    hideTimer = GLib.timeout_add(GLib.PRIORITY_DEFAULT, ms, () => {
      hide()
      return GLib.SOURCE_REMOVE
    })
  }
}

export function dismissAll() {
  hide()
}

export function setupNotificationBridge() {
  notifd.connect("notified", (_self: Notifd.Notifd, id: number) => {
    const n = notifd.get_notification(id)
    if (!n) return
    if (shouldAllowNotification(n)) show(n)
  })

  notifd.connect("resolved", () => {
    hide()
  })
}
