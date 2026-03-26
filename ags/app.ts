import app from "ags/gtk4/app"
import style from "./style.css"
import NotificationBar, { dismissAll } from "./widget/NotificationBar"
import NotificationSidebar, { toggleSidebar } from "./widget/NotificationSidebar"
import { setMode, setDnd, toggleDnd, dnd, history, clearHistory, clickClose, setClickClose, toggleClickClose } from "./lib/notifications"

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

      case "click-close": {
        const sub = args[1]
        if (sub === "on") setClickClose(true)
        else if (sub === "off") setClickClose(false)
        else if (sub === "toggle") toggleClickClose()
        else { res("usage: click-close on|off|toggle"); break }
        res(`click-close ${clickClose.peek() ? "on" : "off"}`)
        break
      }

      case "status":
        res(JSON.stringify({
          dnd: dnd.peek(),
          clickClose: clickClose.peek(),
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
    if (monitors.length > 0) NotificationSidebar(monitors[0])
  },
})
