import app from "ags/gtk3/app"
import style from "./style.scss"
import Bar from "./widget/Bar"
import ControlCenter from "./widget/ControlCenter"

app.start({
  css: style,
  main() {
    app.get_monitors().map(Bar)
    ControlCenter()
  },
  requestHandler(args, response) {
    const cmd = args.join(" ")
    if (cmd.includes("control-center")) {
      const win = app.get_window("control-center")
      if (win) {
        win.visible = !win.visible
        response(win.visible ? "opened" : "closed")
        return
      }
      response("window-not-found")
      return
    }
    response("ok")
  },
})
