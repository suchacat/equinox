## Onboarding GUI + Setup flow
import std/[browsers, logging, os, osproc, posix]
import pkg/owlkettle, pkg/owlkettle/[playground, adw]
import
  ../[argparser],
  ./envparser,
  ../container/[lxc, sugar, certification],
  ../container/utils/exec,
  ../bindings/libadwaita,
  ./clipboard

type
  CantMakeSocketPair = object of OSError

  OnboardMagic {.pure, size: sizeof(uint8).} = enum
    InitEquinox = 0 ## Call the Equinox initialization command
    InitSuccess = 1 ## Successful initialization has taken place
    InitFailure = 2 ## Failed initialization
    Die = 3         ## Kill yourself.

viewable OnboardingApp:
  description:
    string = "This is Equinox"
  iconName:
    string = "weather-clear-symbolic"
  title:
    string = "Equinox"
  active:
    bool = false
  subtitle:
    string = "uuuuuh"
  sensitive:
    bool = true
  tooltip:
    string = "man..."
  sizeRequest:
    tuple[x, y: int] = (-1, -1)

  consentedTOS:
    bool
  consentedPrivacy:
    bool
  consentFail:
    string = ""

  sock: cint
  showSpinner: bool = false

let env = getXdgEnv()

method view(app: OnboardingAppState): Widget =
  proc waitForInit(): bool =
    var readfds: TFdSet
    var timeout: Timeval

    FD_ZERO(readfds)
    FD_SET(app.sock, readfds)
    var ret = select(app.sock + 1.cint, readfds.addr, nil, nil, timeout.addr)
    if ret < 0 or not bool(FD_ISSET(app.sock, readfds)):
      return true

    var buff: array[1, uint8]
    discard read(app.sock, buff[0].addr, 1)
    
    case (OnboardMagic) buff[0]
    of OnboardMagic.InitEquinox, OnboardMagic.Die: discard
    of OnboardMagic.InitFailure:
      warn "gui/onboard: TODO: init failure screen"
    of OnboardMagic.InitSuccess:
      let gsfId =
        &readOutput(
          "pkexec", env.equinoxPath & " get-gsf-id --user:" & env.user
        )

      debug "gui/onboard: gsf id = " & gsfId

      openDefaultBrowser(
        "https://play.google.com/about/play-terms/index.html"
      )
      openDefaultBrowser("https://www.google.com/android/uncertified")
      copyText(gsfId)

      discard app.open:
        gui:
          Window:
            title = "Setup Flow"
            defaultSize = (300, 450)
            HeaderBar {.addTitlebar.}:
              style = [HeaderBarFlat]

            Clamp:
              maximumSize = 450
              margin = 12

              Box:
                orient = OrientY
                spacing = 12

                ActionRow:
                  title =
                    "You're about to interact with Google's Play Store, and as such, you will be subject to their terms of service."
                  subtitle =
                    "Make sure you've read the Google Play Terms of Service. It has just been opened in your browser."

                Label:
                  text =
                    "Equinox's GSF ID has been copied to your clipboard. Paste it in your browser and complete the Captcha to continue."
                  margin = 24

                Box {.hAlign: AlignCenter, vAlign: AlignCenter.}:
                  Button:
                    style = [ButtonPill, ButtonSuggested]
                    text = "Complete Setup"
                    tooltip =
                      "Click this button when you are done with the steps above."

                    proc clicked() =
                      app.closeWindow()

    return false

  result = gui:
    Window:
      defaultSize = (300, 400)
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
            title = "Onboarding"

            ActionRow:
              title = "I Consent"
              subtitle = "To the Equinox Terms of Service"
              Switch() {.addSuffix.}:
                proc changed(active: bool) =
                  app.consentedTOS = active
                  if app.consentedTOS:
                    debug "gui: user has consented to TOS"
                  else:
                    debug "gui: user no longer consents to TOS"

            ActionRow:
              title = "I Consent"
              subtitle = "To the Equinox Privacy Policy"
              Switch() {.addSuffix.}:
                proc changed(active: bool) =
                  app.consentedPrivacy = active
                  if app.consentedPrivacy:
                    debug "gui: user has consented to privacy policy"
                  else:
                    debug "gui: user no longer consents to privacy policy"

          Label:
            text =
              "Welcome to Equinox. Press the button below to start the setup.\nKeep in mind that this can take a minute."
            margin = 24
          
          if app.showSpinner:
            AdwSpinner()

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
                let consent = app.consentedPrivacy and app.consentedTOS
                if not consent:
                  app.consentFail =
                    "Please consent to our Terms of Service and Privacy Policy to continue."
                  return

                # Init command
                var buff: array[1, uint8]
                buff[0] = (uint8) OnboardMagic.InitEquinox
                discard write(app.sock, buff[0].addr, 1)
                
                app.showSpinner = true
                discard addGlobalIdleTask(waitForInit)

proc waitForCommands*(fd: cint) =
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
      runCmd(
        "pkexec",
        env.equinoxPath & " init --xdg-runtime-dir:" & env.runtimeDir &
        " --verbose --wayland-display:" & env.waylandDisplay & " --user:" & env.user &
        " --uid:" & $getuid() & " --gid:" & $getgid(),
      )
    of OnboardMagic.InitFailure, OnboardMagic.InitSuccess: discard
    of OnboardMagic.Die:
      running = false

proc runOnboardingApp*() =
  var pair: array[2, cint]
  if (let status = socketpair(AF_UNIX, SOCK_STREAM, 0, pair); status != 0):
    raise newException(
      CantMakeSocketPair,
      "socketpair() returned " & $status & ": " & $strerror(errno) & " (errno " & $errno &
        ')',
    )
  
  let pid = fork()

  if pid == 0:
    waitForCommands(pair[0])
  else:
    adw.brew(
      gui(OnboardingApp(sock = pair[1])),
      stylesheets = [
        newStylesheet(
          """
        .warning-label {
          color: #ff938b;
        }
      """
        )
      ],
    )
    var buff: array[1, uint8]
    buff[0] = (uint8) OnboardMagic.Die
    discard pair[1].write(buff[0].addr, 1)
