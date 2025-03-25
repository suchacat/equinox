## Launcher GUI
import std/[logging, options]
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
  offset:
    tuple[x, y: int] = (0, 0)
  subtitle:
    string = "uuuuuh"
  tooltip:
    string = "man..."
  sizeRequest:
    tuple[x, y: int] = (-1, -1)
  position:
    PopoverPosition = PopoverBottom

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
      defaultSize = (500, 400)
      title = app.title
      HeaderBar {.addTitlebar.}:
        style = [HeaderBarFlat]
        insert(app.toAutoFormMenu(sizeRequest = (600, 500))) {.addRight.} # for tweaking or whatever

        MenuButton {.addLeft.}:
          icon = "open-menu"
          style = [ButtonFlat]

          PopoverMenu:
            sensitive = app.sensitive
            sizeRequest = app.sizeRequest
            offset = app.offset
            position = app.position

            Box {.name: "main".}:
              orient = OrientY
              margin = 4
              spacing = 3

              ModelButton:
                text = "Tools"
                menuName = "tools"
                proc clicked() =
                  debug "gui: opened the tooling section"

              Separator()

              ModelButton:
                text = "Preferences"
                proc clicked() =
                  echo "WIP"

              ModelButton:
                text = "About Equinox"
                proc clicked() =
                  echo "WIP"

            Box {.name: "tools".}:
              orient = OrientY
              margin = 4
              spacing = 3

              ModelButton:
                text = "Uninstall Equinox"
                proc clicked() =
                  echo "Not a feature yet"

              ModelButton:
                text = "Open Config file"
                proc clicked() =
                  echo "Not a feature yet"

      Clamp:
        maximumSize = 500
        margin = 12

        Box:
          orient = OrientY
          spacing = 12

          PreferencesGroup {.expand: false.}:
            #title = app.title
            #description = "app.description"

            ActionRow:
              title = "Make sure to follow the README instructions"
              subtitle = "Note: This software is experimental and may break"

            Label:
              text = "Welcome to the Equinox launcher."
              margin = 24

          Box {.hAlign: AlignCenter, vAlign: AlignCenter.}:
            orient = OrientX
            spacing = 12

            Button:
              style = [ButtonPill, ButtonSuggested]
              text = "Launch Roblox"
              tooltip = "This will start Roblox trough Equinox"
              proc clicked() =
                echo "test: ", "pkexec ", "equinox run ", app.runtime,env.runtimeDir, " ", app.wayland,env.waylandDisplay, " ", app.user,env.user, " --uid:1000 --gid:1000"
                echo "is the command correct? if not well fix it duh"
                #execCmd todo

            Button:
              style = [ButtonPill]
              text = "Setup Equinox"
              tooltip = "This will also repair Equinox if it's currently broken."
              proc clicked() =
                echo "test: ", "pkexec ", "equinox init ", app.runtime,env.runtimeDir, " ", app.wayland,env.waylandDisplay, " ", app.user,env.user, " --uid:1000 --gid:1000"
                echo "is the command correct? if not well fix it duh"
                #execCmd todo

proc runLauncher*() =
  adw.brew(gui(Launcher()))
