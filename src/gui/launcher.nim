## Launcher GUI
import std/[os, logging, options, osproc, posix]
import pkg/owlkettle, pkg/owlkettle/[playground, adw]
import ./envparser, ../argparser
import ../container/selinux

const
  NimblePkgVersion {.strdefine.} = "???"
  License = staticRead("../../LICENSE")

type
  CantMakeSocketPair = object of OSError

  LauncherMagic {.pure, size: sizeof(uint8).} = enum
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

method view(app: LauncherState): Widget =
  result = gui:
    Window:
      defaultSize = (500, 400)
      title = app.title
      HeaderBar {.addTitlebar.}:
        style = [HeaderBarFlat]
        insert(app.toAutoFormMenu(sizeRequest = (600, 500))) {.addRight.}
          # for tweaking or whatever

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
                  discard app.open:
                    gui:
                      AboutWindow:
                        applicationName = "Equinox"
                        developerName = "The EquinoxHQ Team"
                        version = NimblePkgVersion
                        supportUrl = "https://discord.gg/Z5m3n9fjcU"
                        issueUrl = "https://github.com/equinoxhq/equinox/issues"
                        website = "https://github.com/equinoxhq/equinox/"
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
    var opcode: array[1, byte]
    if (let status = read(fd, opcode[0].addr, 1); status != 1):
      error "launcher/child: read() returned " & $status & ": " & $strerror(errno) &
        " (errno " & $errno & ')'
      error "launcher/child: i think the launcher has crashed or something idk"
      break

    var op = cast[LauncherMagic](cast[uint8](opcode[0]))
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
  var pair: array[2, cint]
  if (let status = socketpair(AF_UNIX, SOCK_STREAM, 0, pair); status != 0):
    raise newException(
      CantMakeSocketPair,
      "socketpair() returned " & $status & ": " & $strerror(errno) & " (errno " & $errno &
        ')',
    )

  let pid = fork()
  let env = getXdgEnv(input)

  # If we're the parent - we launch the GUI.
  # Else, we'll sit around waiting for commands to act upon.
  if pid != 0:
    adw.brew(gui(Launcher(sock = pair[0], env = env)))

    # Tell the child to die.
    var buff: array[1, uint8]
    buff[0] = (uint8) LauncherMagic.Die
    discard write(pair[0], buff[0].addr, 1)
  else:
    waitForCommands(env, pair[1])
