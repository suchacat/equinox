## APK fetcher GUI
import std/[logging, options, osproc, posix]
import pkg/[shakar, owlkettle], pkg/owlkettle/adw
import ../bindings/[libadwaita], ../core/[forked_ipc], ../argparser, ./envparser

type FetcherMagic {.pure, size: sizeof(uint8).} = enum
  Fetch = 0 ## Fetch the APK
  Success = 1 ## Successful fetch
  Fail = 2 ## Failed fetch
  Die = 3 ## Kill yourself.

viewable APKFetcher:
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

  addedTask:
    bool

method view(app: APKFetcherState): Widget =
  if not app.addedTask:
    proc checkUpdaterStatus(): bool =
      let opcode = app.sock.receiveNonBlocking(FetcherMagic)
      if !opcode:
        return true

      let op = &opcode
      debug "install/parent: op -> " & $op

      case op
      of FetcherMagic.Success:
        info "install: Installed Roblox APK successfully"
        app.closeWindow()
        return false
      of FetcherMagic.Fail:
        error "install: Failed to install Roblox APK"
        discard app.open:
          gui:
            Window:
              title = "An error has occurred"
              defaultSize = (300, 450)

              HeaderBar {.addTitlebar.}:
                style = [HeaderBarFlat]

              Box:
                orient = OrientY
                Box {.hAlign: AlignCenter, vAlign: AlignStart.}:
                  Icon:
                    name = "zoom-out-symbolic"
                    pixelSize = 200

                Box {.hAlign: AlignCenter, vAlign: AlignCenter.}:
                  Label:
                    text = "Failed to install the Roblox APK."
                    margin = 24

        app.closeWindow()
        return false
      else:
        discard

      true

    discard addGlobalIdleTask(checkUpdaterStatus)
    app.addedTask = true

  result = gui:
    Window:
      defaultSize = (500, 400)
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
            Label:
              text = "Installing Roblox"
              style = [StyleClass("install-label")]
              margin = 24

            AdwSpinner()

proc waitForCommands*(env: XdgEnv, fd: cint) {.noReturn.} =
  debug "install/child: waiting for commands"

  var running = true
  while running:
    debug "install/child: waiting for opcode"
    let op = fd.receive(FetcherMagic)
    debug "install/child: opcode -> " & $op

    case op
    of FetcherMagic.Die:
      running = false
    of FetcherMagic.Fetch:
      let code = execCmd(
        "pkexec " & env.equinoxPath & " install --user:" & env.user & " --uid:" &
          $getuid() & " --gid:" & $getgid() & " --xdg-runtime-dir:" & env.runtimeDir &
          " --wayland-display:" & env.waylandDisplay & " --consented"
      )

      if code == 0:
        fd.send(FetcherMagic.Success)
      else:
        fd.send(FetcherMagic.Fail)
    else:
      discard

  debug "install/child: adios"
  discard close(fd)
  quit(0)

proc runApkFetcher*(input: Input) =
  let pair = initIpcFds()
  let pid = fork()
  let env = getXdgEnv(input)

  # If we're the parent - we launch the GUI.
  # Else, we'll sit around waiting for commands to act upon.
  if pid != 0:
    pair.master.send(FetcherMagic.Fetch)

    adw.brew(
      gui(APKFetcher(sock = pair.master, env = env)),
      stylesheets = [
        newStylesheet(
          """
.install-label {
  font-weight: bold;
  font-size: 32px;
}

.spinner {
  min-width: 300px;
  min-height: 300px;
}
          """
        )
      ],
    )

    # Tell the child to die.
    pair.master.send(FetcherMagic.Die)
  else:
    waitForCommands(env, pair.slave)
