import app from "ags/gtk4/app"
import style from "./style.css"
import Bar, { toggleExpand, setRecording } from "./widget/Bar"
import { setupNotificationBridge, dismissAll } from "./widget/NotificationBar"
import NotificationSidebar, { toggleSidebar } from "./widget/NotificationSidebar"
import InfoPanel, { showInfo, hideInfo } from "./widget/InfoPanel"
import { notifd, history, clearHistory, focusDismiss, setFocusDismiss, toggleFocusDismiss, filters, addFilter, removeFilter, testFilter, recordNotification, type FilterField } from "./lib/notifications"

app.start({
  css: style,
  requestHandler(args: string[], res: (response: string) => void) {
    const cmd = args[0]

    switch (cmd) {
      case "dismiss-all":
        dismissAll()
        res("dismissed")
        break

      case "info": {
        const infoTitle = args[1] || ""
        const infoContent = args.slice(2).join(" ")
        showInfo(infoTitle, infoContent, 15000)
        res("ok")
        break
      }

      case "hide-info":
        hideInfo()
        res("ok")
        break

      case "toggle-sidebar":
        toggleSidebar()
        res("toggled")
        break

      case "toggle-expand":
        toggleExpand()
        res("toggled")
        break

      case "recording":
        setRecording(args[1] === "on")
        res(args[1] === "on" ? "recording" : "stopped")
        break

      case "clear":
        clearHistory()
        res("cleared")
        break

      case "focus-dismiss": {
        const sub = args[1]
        if (sub === "on") setFocusDismiss(true)
        else if (sub === "off") setFocusDismiss(false)
        else if (sub === "toggle") toggleFocusDismiss()
        else { res("usage: focus-dismiss on|off|toggle"); break }
        res(`focus-dismiss ${focusDismiss.peek() ? "on" : "off"}`)
        break
      }

      case "status":
        res(JSON.stringify({
          focusDismiss: focusDismiss.peek(),
          count: history.peek().length,
        }))
        break

      case "filter": {
        const sub = args[1]
        const validFields = ["app", "summary", "body", "all"]

        if (sub === "list") {
          const rules = filters.peek()
          if (rules.length === 0) {
            res("No filter rules configured")
          } else {
            const lines = rules.map((r, i) => `${i}: [${r.action}] --${r.field} ${r.pattern}`)
            res(lines.join("\n"))
          }
          break
        }

        if (sub === "add") {
          const field = args[2]
          const action = args[3]
          const pattern = args.slice(4).join(" ")
          if (!validFields.includes(field) || (action !== "exclude" && action !== "include") || !pattern) {
            res("usage: filter add <app|summary|body|all> <exclude|include> <regex>")
            break
          }
          try {
            addFilter(field as FilterField, action, pattern)
            res(`Added ${action} rule: --${field} ${pattern}`)
          } catch (e: any) {
            res(`Error: ${e.message}`)
          }
          break
        }

        if (sub === "rm") {
          const idx = parseInt(args[2], 10)
          if (isNaN(idx)) { res("usage: filter rm <index>"); break }
          try {
            removeFilter(idx)
            res(`Removed rule ${idx}`)
          } catch (e: any) {
            res(`Error: ${e.message}`)
          }
          break
        }

        if (sub === "test") {
          const text = args.slice(2).join(" ")
          if (!text) { res("usage: filter test <text>"); break }
          const result = testFilter(text)
          if (result.matchedRule === -1) {
            res("ALLOW (no rule matched)")
          } else {
            res(`${result.action.toUpperCase()} (rule ${result.matchedRule})`)
          }
          break
        }

        res("usage: filter list|add|rm|test")
        break
      }

      default:
        res("unknown request")
    }
  },
  main() {
    // Record notifications once globally (not per-monitor)
    notifd.connect("notified", (_self: any, id: number) => {
      const n = notifd.get_notification(id)
      if (n) recordNotification(n)
    })

    setupNotificationBridge()

    const monitors = app.get_monitors()
    monitors.map(Bar)
    if (monitors.length > 0) {
      NotificationSidebar(monitors[0])
      InfoPanel(monitors[0])
    }
  },
})
