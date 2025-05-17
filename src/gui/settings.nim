## GUI shell
import std/[logging, os, options, posix, json, strutils]
import pkg/[owlkettle, shakar], pkg/owlkettle/adw
import ../container/app_config,
       ./common

type SettingsState* {.pure.} = enum
  General
  Renderer

viewable SettingsMenu:
  collapsed:
    bool = true
  config:
    ptr ConfigData

  state:
    SettingsState

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

        MenuButton {.addRight.}:
          icon = "list-drag-handle-symbolic"
          style = [ButtonFlat]

          PopoverMenu:
            sensitive = true
            sizeRequest = (-1, -1)
            position = PopoverBottom

            Box {.name: "main".}:
              orient = OrientY
              margin = 4
              spacing = 3

              ModelButton:
                text = "About Equinox"
                proc clicked() =
                  openAboutMenu(app)
      
      OverlaySplitView:
        collapsed = not app.collapsed
        enableHideGesture = true
        enableShowGesture = true
        showSidebar = not app.collapsed
        sensitive = true
        sizeRequest = (-1, -1)
        minSidebarWidth = 350f

        Box {.addSidebar.}:
          orient = OrientY
          spacing = 8
          margin = 8
          Button {.expand: false.}:
            ButtonContent:
              label = "General Settings"
              iconName = "image-loading-symbolic"
              useUnderline = false

            proc clicked() =
              app.setState(SettingsState.General)

          Button {.expand: false.}:
            ButtonContent:
              label = "Renderer Settings"
              iconName = "video-display-symbolic"
              useUnderline = false

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
                  subtitle =
                    "When enabled, Equinox will display the current game you're playing on your Discord rich presence, if possible."

                  Switch() {.addSuffix.}:
                    state = app.config.discordRpc

                    proc changed(state: bool) =
                      app.config.discordRpc = state

        of SettingsState.Renderer:
          Clamp:
            maximumSize = 500
            margin = 12
            Box:
              orient = OrientY
              spacing = 12

              PreferencesGroup {.expand: false.}:
                title = "Renderer Settings"
                description =
                  "These settings control how rendering is handled by Equinox."

                ActionRow:
                  title = "Rendering Backend"
                  subtitle =
                    "This option decides whether Vulkan or OpenGL is used. If you have an old GPU, you might want to force Equinox to use OpenGL. This can affect your performance."

                  Dropdown {.addSuffix.}:
                    items = @["Vulkan", "OpenGL"]
                    selected = 0

                    proc select(index: int) =
                      case index
                      of 0:
                        app.config.renderer = "vulkan"
                      of 1:
                        app.config.renderer = "opengl"
                      else:
                        unreachable

                ActionRow:
                  title = "GPU Memory Allocator"
                  subtitle =
                    "This decides which VRAM allocator the Android runtime will use. This can affect your performance. Do not change this unless you know what you're doing."

                  EditableLabel {.addSuffix.}:
                    text = app.config.allocator

                    proc changed(text: string) =
                      app.config.allocator = text

                ActionRow:
                  title = "Maximum FPS"
                  subtitle = "This can be used to change Roblox's FPS limit. If you have VSync enabled, this will be ignored."

                  EditableLabel {.addSuffix.}:
                    text = (
                      if *app.config.maxFps:
                        $(&app.config.maxFps)
                      else:
                        "60"
                    )
                    
                    proc changed(text: string) =
                      try:
                        app.config.maxFps = some(parseUint(text).uint16)
                      except ValueError: discard
        else:
          discard

proc runSettingsMenu*() =
  var config = loadAppConfig($getpwuid(getuid()).pwName)
  adw.brew(gui(SettingsMenu(config = config.addr, collapsed = true)))

  info "equinox: saving configuration changes"
  config.save()
  info "equinox: done!"
