import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createState } from "ags"
import GLib from "gi://GLib"

const [visible, setVisible] = createState(false)
const [title, setTitle] = createState("")
const [content, setContent] = createState("")

let hideTimer: number | null = null

function clearTimer() {
  if (hideTimer !== null) {
    GLib.source_remove(hideTimer)
    hideTimer = null
  }
}

export function showInfo(infoTitle: string, infoContent: string, timeout: number = 10000) {
  clearTimer()
  setTitle(infoTitle)
  setContent(infoContent)
  setVisible(true)

  if (timeout > 0) {
    hideTimer = GLib.timeout_add(GLib.PRIORITY_DEFAULT, timeout, () => {
      setVisible(false)
      hideTimer = null
      return GLib.SOURCE_REMOVE
    })
  }
}

export function hideInfo() {
  clearTimer()
  setVisible(false)
}

export function toggleInfo() {
  if (visible.peek()) {
    hideInfo()
  }
}

export default function InfoPanel(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT, BOTTOM } = Astal.WindowAnchor

  // transparent scrim — click outside to close panel
  const scrim = (
    <window
      visible={visible}
      name="info-scrim"
      cssClasses={["info-scrim"]}
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.NORMAL}
      anchor={TOP | LEFT | RIGHT | BOTTOM}
      layer={Astal.Layer.TOP}
      application={app}
      keymode={Astal.Keymode.NONE}
    >
      <button
        hexpand
        vexpand
        cssClasses={["scrim-button"]}
        onClicked={() => hideInfo()}
      >
        <box />
      </button>
    </window>
  )

  const panel = (
    <window
      visible={visible}
      name="info-panel"
      cssClasses={["info-panel"]}
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.NORMAL}
      anchor={TOP | RIGHT}
      layer={Astal.Layer.TOP}
      application={app}
      keymode={Astal.Keymode.NONE}
      marginTop={42}
      marginRight={8}
    >
      <button
        onClicked={() => hideInfo()}
        cssClasses={["info-panel-button"]}
      >
        <box orientation={Gtk.Orientation.VERTICAL} cssClasses={["info-panel-container"]}>
          <label
            label={title}
            cssClasses={["info-panel-title"]}
            xalign={0}
          />
          <label
            label={content}
            cssClasses={["info-panel-content"]}
            xalign={0}
            wrap
            useMarkup
            maxWidthChars={55}
          />
        </box>
      </button>
    </window>
  )

  return [scrim, panel]
}
