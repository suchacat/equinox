## Launcher GUI
import std/[logging]
import pkg/owlkettle, pkg/owlkettle/[playground, adw]

import ../envparser

viewable Launcher:
  description:
    string = "This is Equinox"
  iconName:
    string = "weather-clear-symbolic"
  title:
    string = "Equinox"
  active:
    bool = false
  sensitive:
    bool = true
  toggle:
    bool
  subtitle:
    string = "uuuuuh"
  tooltip:
    string = "man..."
  sizeRequest:
    tuple[x, y: int] = (-1, -1)

  #my code sucks
  erm_guh:
    string = "equinox init --xdg-runtime-dir:A --wayland-display:B --user:C --uid:D --gid:E"
  runtime:
    string = "--xdg-runtime-dir:"
  wayland:
    string = "--wayland-display:"
  user:
    string = "--user:"

let env = getXdgEnv()

method view(app: LauncherState): Widget =
  result = gui:
    Window:
      defaultSize = (600, 400)
      title = app.title
      HeaderBar {.addTitlebar.}:
        style = [HeaderBarFlat]

      Clamp:
        maximumSize = 500
        margin = 12

        Box:
          orient = OrientY
          spacing = 12

          PreferencesGroup {.expand: false.}:
            #title = app.title
            #description = "Losing it"

            ActionRow:
              title = "Make sure to follow the README instructions"
              subtitle = "Note: This software is experimental and may break"
              #[Switch() {.addSuffix.}:
                proc changed(active: bool) =
                  app.consentedTOS = active
                  if app.consentedTOS:
                    debug "gui: user has consented to TOS"
                  else:
                    debug "gui: user no longer consents to TOS"]#

          Box {.hAlign: AlignCenter, vAlign: AlignCenter.}:
            orient = OrientX
            spacing = 12

            Button:
              style = [ButtonPill, ButtonSuggested]
              text = "Launch Roblox"
              proc clicked() =
                echo "launch command not implemented yet"
                #execCmd

            Button:
              style = [ButtonPill]
              text = "Setup Equinox"
              #icon = "applications-system-symbolic"
              #tooltip = "config"
              proc clicked() =
                echo "test: ", "pkexec", "equinox init ", app.runtime,env.runtimeDir, " ", app.wayland,env.waylandDisplay, " ", app.user,env.user, " --uid:1000 --gid:1000"
                echo "is the command correct? if not fix it dumb*ss"

proc runLauncher*() =
  adw.brew(gui(Launcher()))
