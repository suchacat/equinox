## GUI shell
import std/[logging, os, options, posix, json]
import pkg/[owlkettle, shakar], pkg/owlkettle/adw
import ../container/app_config

type SettingsState* {.pure.} = enum
  General
  Renderer

viewable SettingsMenu:
  collapsed: bool = true
  config: ptr ConfigData

  state: SettingsState

proc setState(app: SettingsMenuState, state: SettingsState) =
  if app.state == state:
    return
  
  debug "settings: state=" & $state
  app.collapsed = true
  app.state = state

method view(app: SettingsMenuState): Widget =
  result = gui:
    Window:
      title = "Equinox Settings"
      defaultSize = (600, 400)

      AdwHeaderBar {.addTitlebar.}:
        showTitle = true

        Button {.addLeft.}:
          icon = "open-menu-symbolic"

          proc clicked() =
            app.collapsed = not app.collapsed
            debug "settings: collapsed: " & $app.collapsed

      OverlaySplitView:
        collapsed = app.collapsed
        enableHideGesture = true
        enableShowGesture = true
        showSidebar = app.collapsed
        sensitive = true
        sizeRequest = (-1, -1)
        minSidebarWidth = 350f
        
        Box {.addSidebar.}:
          orient = OrientY
          spacing = 8
          margin = 8
          Button {.expand: false.}:
            text = "General Settings"

            proc clicked() =
              app.setState(SettingsState.General)
          
          Button {.expand: false.}:
            text = "Renderer Settings"

            proc clicked() =
              app.setState(SettingsState.Renderer)

        case app.state
        of SettingsState.General:
          Clamp:
            maximumSize = 500
            margin = 12
            Box:
              orient = OrientY
              spacing = 12

              PreferencesGroup {.expand: false.}:
                title = "General Settings"
                description = "These settings dictate Equinox's behaviour."

                ActionRow:
                  title = "Show Discord RPC"
                  subtitle = "When enabled, Equinox will display the current game you're playing on your Discord rich presence, if possible."

                  Switch() {.addSuffix.}:
                    state = app.config.discordRpc

                    proc changed(state: bool) =
                      app.config.discordRpc = state
        else: discard

proc runSettingsMenu*() =
  var config = loadAppConfig($getpwuid(getuid()).pwName)
  adw.brew(gui(SettingsMenu(
    config = config.addr
  )))

  info "equinox: saving configuration changes"
  config.save()
  info "equinox: done!"
