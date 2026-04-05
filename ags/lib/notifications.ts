import { createState } from "ags"
import { readFile, writeFile } from "ags/file"
import Notifd from "gi://AstalNotifd?version=0.1"
import GLib from "gi://GLib"

const STATE_DIR = GLib.get_home_dir() + "/.config/arch-x"
GLib.mkdir_with_parents(STATE_DIR, 0o755)

const FOCUS_DISMISS_FILE = STATE_DIR + "/notification-focus-dismiss"
const FILTERS_FILE = STATE_DIR + "/notification-filters.json"

// ── Notifd singleton ──────────────────────────────

export const notifd = Notifd.get_default()

// ── Helpers ──────────────────────────────────────

function readFile_(path: string, fallback: string): string {
  try {
    const content = readFile(path).trim()
    return content || fallback
  } catch {
    return fallback
  }
}

// ── Click-outside-to-close ────────────────────────

const [focusDismiss, _setFocusDismiss] = createState(readFile_(FOCUS_DISMISS_FILE, "on") === "on")

export { focusDismiss }

export function setFocusDismiss(value: boolean) {
  _setFocusDismiss(value)
  writeFile(FOCUS_DISMISS_FILE, value ? "on" : "off")
}

export function toggleFocusDismiss() {
  setFocusDismiss(!focusDismiss.peek())
}

// ── Notification filters ─────────────────────────

export type FilterField = "app" | "summary" | "body" | "all"

export interface FilterRule {
  field: FilterField
  pattern: string
  action: "exclude" | "include"
}

function loadFilters(): FilterRule[] {
  try {
    const raw = readFile(FILTERS_FILE).trim()
    if (!raw) return []
    return JSON.parse(raw) as FilterRule[]
  } catch {
    return []
  }
}

function saveFilters(): void {
  writeFile(FILTERS_FILE, JSON.stringify(filters.peek(), null, 2))
}

const [filters, _setFilters] = createState<FilterRule[]>(loadFilters())

export { filters }

export function addFilter(field: FilterField, action: "exclude" | "include", pattern: string): void {
  new RegExp(pattern) // validate - throws if invalid
  const updated = [...filters.peek(), { field, pattern, action }]
  _setFilters(updated)
  saveFilters()
}

export function removeFilter(index: number): void {
  const current = filters.peek()
  if (index < 0 || index >= current.length) throw new Error("Index out of range")
  const updated = current.filter((_, i) => i !== index)
  _setFilters(updated)
  saveFilters()
}

export function testFilter(text: string): { action: "exclude" | "include"; matchedRule: number } {
  const rules = filters.peek()
  for (let i = 0; i < rules.length; i++) {
    try {
      if (new RegExp(rules[i].pattern, "i").test(text)) {
        return { action: rules[i].action, matchedRule: i }
      }
    } catch { /* skip invalid regex */ }
  }
  return { action: "include", matchedRule: -1 }
}

function getFilterTarget(rule: FilterRule, n: Notifd.Notification): string {
  switch (rule.field) {
    case "app": return n.appName || ""
    case "summary": return n.summary || ""
    case "body": return n.body || ""
    case "all": return `${n.appName || ""}: ${n.summary || ""} ${n.body || ""}`
  }
}

export function shouldAllowNotification(n: Notifd.Notification): boolean {
  const rules = filters.peek()
  for (let i = 0; i < rules.length; i++) {
    try {
      const text = getFilterTarget(rules[i], n)
      if (new RegExp(rules[i].pattern, "i").test(text)) {
        return rules[i].action === "include"
      }
    } catch { /* skip invalid regex */ }
  }
  return true
}

// ── Current notification state (reactive) ────────

export interface CurrentNotification {
  id: number
  summary: string
  body: string
  urgency: "normal" | "critical" | "low"
  appName: string
}

const [currentNotification, _setCurrentNotification] = createState<CurrentNotification | null>(null)

export { currentNotification }

export function setCurrentNotification(n: Notifd.Notification): void {
  _setCurrentNotification({
    id: n.id,
    summary: n.summary || "",
    body: (n.body || "").replace(/<[^>]*>/g, "").replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"").replace(/&#39;/g, "'"),
    urgency: n.urgency === Notifd.Urgency.CRITICAL ? "critical" : n.urgency === Notifd.Urgency.LOW ? "low" : "normal",
    appName: n.appName || "",
  })
}

export function clearCurrentNotification(): void {
  _setCurrentNotification(null)
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

export function recordNotification(n: Notifd.Notification): boolean {
  if (!shouldAllowNotification(n)) return false

  const actions: { id: string; label: string }[] = []
  const nActions = n.get_actions()
  if (nActions) {
    for (const action of nActions) {
      if (action.label) {
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

  const filtered = history.peek().filter(e => e.id !== n.id)
  const updated = [entry, ...filtered]
  setHistory(updated.length > 200 ? updated.slice(0, 200) : updated)
  return true
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
