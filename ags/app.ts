import app from "ags/gtk4/app"
import style from "./style.css"
import NotificationBar, { dismissAll } from "./widget/NotificationBar"
import NotificationSidebar, { toggleSidebar } from "./widget/NotificationSidebar"
import InfoPanel, { showInfo, hideInfo } from "./widget/InfoPanel"
import { readFile } from "ags/file"
import GLib from "gi://GLib"
import { setMode, setDnd, toggleDnd, dnd, history, clearHistory, focusDismiss, setFocusDismiss, toggleFocusDismiss } from "./lib/notifications"

app.start({
  css: style,
  requestHandler(args: string[], res: (response: string) => void) {
    const cmd = args[0]

    // mode commands
    if (cmd?.startsWith("mode:")) {
      setMode(cmd.slice(5))
      res(`mode set to ${cmd.slice(5)}`)
      return
    }

    switch (cmd) {
      case "dismiss-all":
        dismissAll()
        res("dismissed")
        break

      case "info": {
        const infoTitle = args[1] || ""
        const infoFile = GLib.get_home_dir() + "/.config/ags/info-content"
        let infoContent = ""
        try {
          infoContent = readFile(infoFile).trim()
        } catch {}
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

      case "dnd": {
        const sub = args[1]
        if (sub === "on") setDnd(true)
        else if (sub === "off") setDnd(false)
        else if (sub === "toggle") toggleDnd()
        else { res("usage: dnd on|off|toggle"); break }
        res(`dnd ${dnd.peek() ? "on" : "off"}`)
        break
      }

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
          dnd: dnd.peek(),
          focusDismiss: focusDismiss.peek(),
          count: history.peek().length,
        }))
        break

      default:
        res("unknown request")
    }
  },
  main() {
    const monitors = app.get_monitors()
    monitors.map(NotificationBar)
    if (monitors.length > 0) {
      NotificationSidebar(monitors[0])
      InfoPanel(monitors[0])
    }
  },
})
