## Onboarding GUI + Setup flow
import std/[browsers, logging, os, osproc, options, posix, json]
import pkg/[jsony, owlkettle, shakar], pkg/owlkettle/[playground, adw]
import
  ../[argparser],
  ./envparser,
  ../container/[lxc, gpu, certification, configuration],
  ../container/utils/exec,
  ../bindings/libadwaita,
  ../core/[forked_ipc, processes],
  ./clipboard

type OnboardMagic {.pure, size: sizeof(uint8).} = enum
  InitEquinox = 0 ## Call the Equinox initialization command
  InitSuccess = 1 ## Successful initialization has taken place
  InitFailure = 2 ## Failed initialization
  Die = 4 ## Kill yourself.
  StartContainer = 5 ## Start the container so that it populates the data directory
  StopContainer = 6 ## Stop the container.
  StartedContainer = 7 ## Sent when the container has started

viewable OnboardingApp:
  consentFail:
    string = ""

  sock:
    cint

  env:
    XdgEnv

  showSpinner:
    bool = false

  showProgressBar:
    bool = false
  progress:
    float = 0.0
  progressText:
    string = "Preparing (Hope that it won't blow up)"

proc gpuCheck(app: OnboardingAppState): bool =
  let node = getDriNode()
  if node.isSome:
    return true

  app.showSpinner = false
  discard app.redraw()
  discard app.open:
    gui:
      Window:
        title = "No GPU detected"
        defaultSize = (200, 300)

        HeaderBar {.addTitlebar.}:
          style = [HeaderBarFlat]

        Box:
          orient = OrientY
          Box {.hAlign: AlignCenter, vAlign: AlignStart.}:
            Icon:
              name = "emblem-important"
              pixelSize = 200

          Box {.hAlign: AlignCenter, vAlign: AlignCenter.}:
            Label:
              text =
                "Equinox could not detect a compatible GPU. Nvidia GPUs are not supported yet.\nIf you believe that this is not true, file a bug report."
              margin = 24

  false

method view(app: OnboardingAppState): Widget =
  let hasToDownloadImages =
    not (
      fileExists("/var" / "lib" / "equinox" / "images" / "system.img") and
      fileExists("/var" / "lib" / "equinox" / "images" / "vendor.img")
    )

  debug "onboarding: hasToDownloadImages: " & $hasToDownloadImages

  proc waitForInit(): bool =
    if hasToDownloadImages:
      try:
        let content = readFile("/tmp/equinox-progress.json").parseJson()
        let
          speedKbps = content["speedKbps"].getFloat()
          totalBytes = content["totalBytes"].getFloat()
          downloadedBytes = content["downloadedBytes"].getFloat()

        app.showProgressBar = true

        if totalBytes != 0f:
          app.progress = (downloadedBytes / totalBytes)
          app.progressText = $speedKbps & " KB/s"
        else:
          app.progress = 0.0f
          app.progressText = "Preparing to download images"

        discard app.redraw()
      except JsonParsingError, IOError:
        discard

    let op = app.sock.receiveNonBlocking(OnboardMagic)
    if !op:
      return true

    case &op
    of OnboardMagic.InitEquinox, OnboardMagic.Die, OnboardMagic.StartContainer,
        OnboardMagic.StopContainer, OnboardMagic.StartedContainer:
      discard
    of OnboardMagic.InitFailure:
      app.showSpinner = false
      discard app.redraw()
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
                  text =
                    "Equinox has failed to initialize the container. Please run this launcher from your terminal and send the logs to the Lucem Discord server."
                  margin = 24
    of OnboardMagic.InitSuccess:
      app.sock.send(OnboardMagic.StartContainer)

    return false

  result = gui:
    Window:
      defaultSize = (300, 400)
      title = "Equinox"
      HeaderBar {.addTitlebar.}:
        style = [HeaderBarFlat]

      Clamp:
        maximumSize = 500
        margin = 12

        Box:
          orient = OrientY
          spacing = 12

          Label:
            text =
              "Welcome to Equinox. Press the button below to start the setup.\nKeep in mind that this can take a minute."
            margin = 24

          PreferencesGroup {.expand: false.}:
            ActionRow:
              title = "Thank you for installing Equinox."
              subtitle =
                "Please keep in mind that Equinox is experimental software and is prone to bugs, errors and certain limitations. We intend to fix these eventually."

            ActionRow:
              title = "Your account could be moderated for using Equinox."
              subtitle =
                "Whilst very unlikely, it is not out of the question that Roblox accidentally temporarily bans your account for using Equinox due to how it works and how it can possibly trigger the anticheat in ways we are unaware of."

            ActionRow:
              title = "Privacy Policy"
              subtitle =
                "Equinox is libre software and does NOT collect any data about you, excluding crash dumps. The different services it interacts with might, though."

          if app.showSpinner:
            AdwSpinner()

          if app.showProgressBar:
            ProgressBar:
              fraction = app.progress
              showText = true
              text = app.progressText

          Label:
            text = app.consentFail
            margin = 12
            style = [StyleClass("warning-label")]

          Box {.hAlign: AlignCenter, vAlign: AlignCenter.}:
            orient = OrientX
            spacing = 12

            Button:
              style = [ButtonPill, ButtonSuggested]
              text = "Start Setup"
              proc clicked() =
                app.consentFail = ""

                if not gpuCheck(app):
                  return

                # Init command
                var buff: array[1, uint8]
                buff[0] = (uint8) OnboardMagic.InitEquinox
                discard write(app.sock, buff[0].addr, 1)

                app.showSpinner = hasToDownloadImages
                app.showProgressBar = hasToDownloadImages
                discard addGlobalTimeout(100, waitForInit)

proc waitForCommands*(env: XdgEnv, fd: cint) =
  var running = true
  while running:
    debug "launcher/child: waiting for opcode"
    var opcode: array[1, byte]
    if (let status = read(fd, opcode[0].addr, 1); status != 1):
      error "launcher/child: read() returned " & $status & ": " & $strerror(errno) &
        " (errno " & $errno & ')'
      error "launcher/child: i think the launcher has crashed or something idk"
      break

    var op = cast[OnboardMagic](cast[uint8](opcode[0]))
    debug "launcher/child: opcode -> " & $op

    case op
    of OnboardMagic.InitEquinox:
      var buff: array[1, uint8]
      if runCmd(
        "pkexec",
        env.equinoxPath & " init --xdg-runtime-dir:" & env.runtimeDir &
          " --wayland-display:" & env.waylandDisplay & " --user:" & env.user & " --uid:" &
          $getuid() & " --gid:" & $getgid(),
      ):
        buff[0] = (uint8) OnboardMagic.InitSuccess
      else:
        buff[0] = (uint8) OnboardMagic.InitFailure

      discard write(fd, buff[0].addr, 1)
    of OnboardMagic.InitFailure, OnboardMagic.InitSuccess, OnboardMagic.StartedContainer:
      discard
    of OnboardMagic.Die:
      running = false
    of OnboardMagic.StartContainer:
      discard runCmd(
        "pkexec",
        env.equinoxPath & " run --warmup --user:" & env.user & " --uid:" & $getuid() &
          " --gid:" & $getgid() & " --wayland-display:" & env.waylandDisplay &
          " --xdg-runtime-dir:" & getEnv("XDG_RUNTIME_DIR"),
      )
    of OnboardMagic.StopContainer:
      discard runCmd("pkexec", env.equinoxPath & " halt --force")

proc runOnboardingApp*(input: Input) =
  let pair = initIpcFds()
  let pid = fork()
  let env = getXdgEnv(input)

  if pid == 0:
    waitForCommands(env, pair.slave)
  else:
    adw.brew(
      gui(OnboardingApp(sock = pair.master, env = env)),
      stylesheets = [
        newStylesheet(
          """
.warning-label {
  color: #ff938b;
}

.spinner {
  min-width: 300px;
  min-height: 300px;
}
      """
        )
      ],
    )
    pair.master.send(OnboardMagic.Die)
