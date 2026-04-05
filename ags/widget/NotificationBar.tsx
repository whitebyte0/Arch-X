import GLib from "gi://GLib"
import Notifd from "gi://AstalNotifd?version=0.1"
import { notifd, currentNotification, shouldAllowNotification, setCurrentNotification, clearCurrentNotification } from "../lib/notifications"
import { expanded, setExpanded } from "./Bar"

const TIMEOUT_LOW = 8000
const TIMEOUT_NORMAL = 12000

let hideTimer: number | null = null
const pendingQueue: Notifd.Notification[] = []

function clearTimer() {
  if (hideTimer !== null) {
    GLib.source_remove(hideTimer)
    hideTimer = null
  }
}

function hide() {
  clearTimer()
  clearCurrentNotification()
  if (pendingQueue.length > 0) {
    const next = pendingQueue.shift()!
    GLib.idle_add(GLib.PRIORITY_DEFAULT, () => {
      show(next)
      return GLib.SOURCE_REMOVE
    })
  }
}

function show(n: Notifd.Notification) {
  if (expanded.peek()) {
    pendingQueue.push(n)
    return
  }
  clearTimer()
  setCurrentNotification(n)

  if (n.appName === "system") {
    setExpanded(true)
    return
  }

  if (n.urgency !== Notifd.Urgency.CRITICAL) {
    const ms = n.urgency === Notifd.Urgency.LOW ? TIMEOUT_LOW : TIMEOUT_NORMAL
    hideTimer = GLib.timeout_add(GLib.PRIORITY_DEFAULT, ms, () => {
      if (expanded.peek()) return GLib.SOURCE_REMOVE
      hide()
      return GLib.SOURCE_REMOVE
    })
  }
}

export function dismissAll() {
  hide()
}

export function setupNotificationBridge() {
  // When user collapses, start a timeout to auto-hide
  expanded.subscribe(() => {
    if (!expanded.peek() && currentNotification.peek()) {
      clearTimer()
      hideTimer = GLib.timeout_add(GLib.PRIORITY_DEFAULT, TIMEOUT_NORMAL, () => {
        if (expanded.peek()) return GLib.SOURCE_REMOVE
        hide()
        return GLib.SOURCE_REMOVE
      })
    }
  })
  notifd.connect("notified", (_self: Notifd.Notifd, id: number) => {
    const n = notifd.get_notification(id)
    if (!n) return
    if (shouldAllowNotification(n)) show(n)
  })

  notifd.connect("resolved", (_self: Notifd.Notifd, id: number) => {
    if (expanded.peek()) return
    const current = currentNotification.peek()
    if (!current || current.id === id) hide()
  })
}
