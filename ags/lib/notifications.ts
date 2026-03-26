import { createState } from "ags"
import { readFile, writeFile } from "ags/file"
import Notifd from "gi://AstalNotifd?version=0.1"
import GLib from "gi://GLib"

const MODE_FILE = GLib.get_home_dir() + "/.config/ags/notification-mode"
const DND_FILE = GLib.get_home_dir() + "/.config/ags/notification-dnd"
const CLICK_CLOSE_FILE = GLib.get_home_dir() + "/.config/ags/notification-click-close"

// ── Notifd singleton ──────────────────────────────

export const notifd = Notifd.get_default()

// ── Notification mode ─────────────────────────────

function readFile_(path: string, fallback: string): string {
  try {
    const content = readFile(path).trim()
    return content || fallback
  } catch {
    return fallback
  }
}

const [mode, _setMode] = createState(readFile_(MODE_FILE, "dynamic"))

export { mode }

export function setMode(m: string) {
  if (["reserved", "dynamic", "overlay"].includes(m)) {
    _setMode(m)
  }
}

// ── Do Not Disturb ────────────────────────────────

const [dnd, _setDnd] = createState(readFile_(DND_FILE, "off") === "on")

export { dnd }

export function setDnd(value: boolean) {
  _setDnd(value)
  writeFile(DND_FILE, value ? "on" : "off")
  notifd.dontDisturb = value
}

export function toggleDnd() {
  setDnd(!dnd.peek())
}

// ── Click-outside-to-close ────────────────────────

const [clickClose, _setClickClose] = createState(readFile_(CLICK_CLOSE_FILE, "off") === "on")

export { clickClose }

export function setClickClose(value: boolean) {
  _setClickClose(value)
  writeFile(CLICK_CLOSE_FILE, value ? "on" : "off")
}

export function toggleClickClose() {
  setClickClose(!clickClose.peek())
}

// ── Notification history ──────────────────────────

export interface HistoryEntry {
  id: number
  appName: string
  summary: string
  body: string
  urgency: number
  time: number
  actions: { id: string; label: string }[]
}

const [history, setHistory] = createState<HistoryEntry[]>([])

export { history }

export function recordNotification(n: Notifd.Notification): void {
  const actions: { id: string; label: string }[] = []
  const nActions = n.get_actions()
  if (nActions) {
    for (const action of nActions) {
      if (action.label && action.id !== "default") {
        actions.push({ id: action.id, label: action.label })
      }
    }
  }

  const entry: HistoryEntry = {
    id: n.id,
    appName: n.appName || "Unknown",
    summary: n.summary || "",
    body: n.body || "",
    urgency: n.urgency,
    time: n.time,
    actions,
  }

  setHistory([entry, ...history.peek()])
}

export function dismissNotification(id: number): void {
  setHistory(history.peek().filter((e) => e.id !== id))
  const n = notifd.get_notification(id)
  if (n) n.dismiss()
}

export function clearHistory(): void {
  setHistory([])
}

// ── Relative time helper ──────────────────────────

export function relativeTime(timestamp: number): string {
  const now = Math.floor(GLib.get_real_time() / 1_000_000)
  const diff = now - timestamp
  if (diff < 60) return "now"
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`
  return `${Math.floor(diff / 86400)}d ago`
}
