## APK fetcher GUI
import std/[os, logging, options, osproc, posix]
import pkg/owlkettle, pkg/owlkettle/[playground, adw]
import ../bindings/[libadwaita]
import ./envparser

type
  CantMakeSocketPair = object of OSError

  FetcherMagic {.pure, size: sizeof(uint8).} = enum
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

  sock:
    cint
  addedTask:
    bool

let env = getXdgEnv()

method view(app: APKFetcherState): Widget =
  if not app.addedTask:
    proc checkUpdaterStatus(): bool =
      var readfds: TFdSet
      var timeout: Timeval

      FD_ZERO(readfds)
      FD_SET(app.sock, readfds)

      var ret = select(app.sock + 1.cint, readfds.addr, nil, nil, timeout.addr)
      if ret > 0 and bool(FD_ISSET(app.sock, readfds)):
        # We have an incoming opcode
        var opcode: array[1, byte]
        if (let status = read(app.sock, opcode[0].addr, 1); status != 1):
          error "install/parent: read() returned " & $status & ": " & $strerror(errno) &
            " (errno " & $errno & ')'
          error "install/parent: i think the launcher has crashed or something idk"
          return false

        let op = (FetcherMagic) opcode[0]
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
                      name = "abrt-symbolic"
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
            ActionRow:
              title =
                "By installing Roblox, you agree to the Google Play Terms of Service."
              subtitle = "The Equinox team is not responsible for any damages."

            Label:
              text = "Installing Roblox"
              style = [StyleClass("install-label")]
              margin = 24

            AdwSpinner()

proc waitForCommands*(fd: cint) {.noReturn.} =
  debug "install/child: waiting for commands"

  var running = true
  while running:
    debug "install/child: waiting for opcode"
    var opcode: array[1, uint8]
    if (let status = read(fd, opcode[0].addr, 1); status != 1):
      error "install/child: read() returned " & $status & ": " & $strerror(errno) &
        " (errno " & $errno & ')'
      error "install/child: i think the launcher has crashed or something idk"
      break

    var op = cast[FetcherMagic](opcode[0])
    debug "install/child: opcode -> " & $op

    case op
    of FetcherMagic.Die:
      running = false
    of FetcherMagic.Fetch:
      if fork() == 0:
        discard execCmd(
          "pkexec " & env.equinoxPath & " run --user:" & env.user & " --uid:" & $getuid() &
            " --gid:" & $getgid() & " --xdg-runtime-dir:" & env.runtimeDir &
            " --wayland-display:" & env.waylandDisplay
        )
        quit(0)

      while execCmd("pidof equinox") != 0:
        sleep(100) # FIXME: use a better signalling mechanism.

      let code = execCmd(
        "pkexec " & env.equinoxPath & " install --user:" & env.user & " --uid:" &
          $getuid() & " --gid:" & $getgid() & " --xdg-runtime-dir:" & env.runtimeDir &
          " --wayland-display:" & env.waylandDisplay & " --consented"
      )

      var buff: array[1, uint8]
      buff[0] = (uint8)(
        if code == 0:
          FetcherMagic.Success
        else:
          debug "install/child: updater exited with non-zero exit code: " & $code
          FetcherMagic.Fail
      )
      discard write(fd, buff[0].addr, 1)
      discard execCmd("pkexec " & env.equinoxPath & " halt --force")
    else:
      discard

  debug "install/child: adios"
  discard close(fd)
  quit(0)

proc runApkFetcher*() =
  var pair: array[2, cint]
  if (let status = socketpair(AF_UNIX, SOCK_STREAM, 0, pair); status != 0):
    raise newException(
      CantMakeSocketPair,
      "socketpair() returned " & $status & ": " & $strerror(errno) & " (errno " & $errno &
        ')',
    )

  let pid = fork()

  # If we're the parent - we launch the GUI.
  # Else, we'll sit around waiting for commands to act upon.
  if pid != 0:
    var buff: array[1, uint8]
    buff[0] = (uint8) FetcherMagic.Fetch
    discard write(pair[0], buff[0].addr, 1)

    adw.brew(
      gui(APKFetcher(sock = pair[0])),
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
    buff[0] = (uint8) FetcherMagic.Die
    discard write(pair[0], buff[0].addr, 1)
  else:
    waitForCommands(pair[1])
