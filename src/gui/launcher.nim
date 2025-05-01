## Launcher GUI
import std/[os, logging, options, osproc, posix]
import pkg/owlkettle, pkg/owlkettle/[playground, adw], pkg/[shakar]
import ../container/network, ../core/[forked_ipc], ./envparser, ../argparser

const
  NimblePkgVersion {.strdefine.} = "???"
  License = staticRead("../../LICENSE")

type LauncherMagic {.pure, size: sizeof(uint8).} = enum
  Launch = 0 ## Launch Equinox.
  Halt = 1 ## Halt Equinox.
  Die = 2 ## Kill yourself.

viewable Launcher:
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
  sizeRequest:
    tuple[x, y: int] = (-1, -1)
  position:
    PopoverPosition = PopoverBottom

  env:
    XdgEnv

  sock:
    cint

template settingsMenu(): Widget =
  Window()

proc networkCheck(app: LauncherState): bool =
  let
    device = getNetworkDevice()
    offline = !device or not isOnline(&device)

  result = offline

  if offline:
    discard app.open:
      gui:
        Window:
          defaultSize = (480, 320)
          title = "You are offline."

          Clamp:
            maximumSize = 500
            margin = 12

            Box:
              orient = OrientY
              spacing = 12

              Icon:
                name = "network-cellular-disabled-symbolic"
                pixelSize = 200

              Label:
                text =
                  "<span size=\"large\">Equinox could not find an active network connection. Without it, <b>Roblox won't run.</b></span>"
                useMarkup = true

method view(app: LauncherState): Widget =
  result = gui:
    Window:
      defaultSize = (500, 400)
      title = app.title
      HeaderBar {.addTitlebar.}:
        style = [HeaderBarFlat]

        MenuButton {.addRight.}:
          icon = "preferences-other-symbolic"
          style = [ButtonFlat]

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
                text = "About Equinox"
                proc clicked() =
                  discard app.open:
                    gui:
                      AboutWindow:
                        applicationName = "Equinox"
                        developerName = "The EquinoxHQ Team"
                        version = NimblePkgVersion
                        supportUrl = "https://discord.gg/Z5m3n9fjcU"
                        issueUrl = "https://github.com/equinoxhq/equinox/issues"
                        website = "https://equinoxhq.github.io"
                        copyright =
                          """
Copyright (C) 2025 xTrayambak and the EquinoxHQ Team
The Roblox logo and branding are registered trademarks of Roblox Corporation.
                        """
                        license = License
                        licenseType = LicenseMIT_X11
                        applicationIcon = "equinox"
                        developers = @["Trayambak (xTrayambak)"]
                        designers = @["Adrien (AshtakaOOf)"]
                        artists = @[]
                        documenters = @[]
                        credits = @{"APK Fetcher by": @["Kirby (k1yrix)"]}

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
              title = "Make sure to follow the README instructions."
              subtitle = "This software is experimental and may break."

            ActionRow:
              title =
                "Please make sure that you agree to the EquinoxHQ Terms of Service before you begin."
              subtitle = "The Equinox team is not responsible for any damages."

            Label:
              text = "Welcome to the Equinox launcher."
              margin = 24

          Box {.hAlign: AlignCenter, vAlign: AlignCenter.}:
            orient = OrientX
            spacing = 12

            Button:
              style = [ButtonPill, ButtonSuggested]
              text = "Launch Roblox"
              tooltip = "This will start Roblox through Equinox."
              proc clicked() =
                if networkCheck(app):
                  return

                var buff: array[1, uint8]
                buff[0] = (uint8) LauncherMagic.Launch
                discard write(app.sock, buff[0].addr, 1) == 0

            Button:
              style = [ButtonPill, ButtonDestructive]
              text = "Stop Equinox"
              tooltip = "Gracefully shut down the Equinox container."
              proc clicked() =
                var buff: array[1, uint8]
                buff[0] = (uint8) LauncherMagic.Halt
                discard write(app.sock, buff[0].addr, 1) == 0

proc waitForCommands*(env: XdgEnv, fd: cint) {.noReturn.} =
  debug "launcher/child: waiting for commands"

  var running = true
  while running:
    debug "launcher/child: waiting for opcode"
    let op = fd.receive(LauncherMagic)
    debug "launcher/child: opcode -> " & $op

    case op
    of LauncherMagic.Launch:
      let cmd =
        findExe("pkexec") & ' ' & env.equinoxPath & " run --xdg-runtime-dir:" &
        env.runtimeDir & " --wayland-display:" & env.waylandDisplay & " --user:" &
        env.user & " --uid:" & $getuid() & " --gid:" & $getgid()

      debug "launcher/child: cmd -> " & cmd
      let pid = fork()

      if pid == 0:
        debug "launcher/child: we're the forked child"
        discard execCmd(cmd)
        quit(0)
      else:
        debug "launcher/child: we're the parent"
    of LauncherMagic.Halt:
      let cmd = findExe("pkexec") & ' ' & env.equinoxPath & " halt --force"
      debug "launcher/child: cmd -> " & cmd

      discard execCmd(cmd)
    of LauncherMagic.Die:
      running = false

  debug "launcher/child: adios"
  discard close(fd)
  quit(0)

proc runLauncher*(input: Input) =
  let pair = initIpcFds()
  let pid = fork()
  let env = getXdgEnv(input)

  # If we're the parent - we launch the GUI.
  # Else, we'll sit around waiting for commands to act upon.
  if pid != 0:
    adw.brew(gui(Launcher(sock = pair.master, env = env)))

    # Tell the child to die.
    pair.master.send(LauncherMagic.Die)
  else:
    waitForCommands(env, pair.slave)
