import app from "ags/gtk4/app"
import style from "./style.css"
import NotificationBar from "./widget/NotificationBar"

app.start({
  css: style,
  main() {
    app.get_monitors().map(NotificationBar)
  },
})
