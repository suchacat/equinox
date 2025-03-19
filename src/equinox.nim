import std/[os, logging, terminal, random]
import pkg/[colored_logger, pretty, noise]
import ./argparser
import
  container/[
    trayperion, certification, lxc, image_downloader, configuration, init, run, sugar,
    properties, app_manager, platform, network
  ]

const Splashes = [
  "\"pc game support when\" bro im not even done installing my rootkits on your pc -tray",
  "all hail the NT flying horse",
  "\"the only valid usecase for nixos is bombing children\" - hippoz, 2025",
  "\"im in a perpetual state of shitting myself\" - hippoz, 2025",
  "(un)protected by trayperion", "you thought it was ROLover? hahaha",
  "i added this splash for the sole purpose that when someone runs `strings equinox`, they see this. hi there, curious person (or skid) :^)",
  "compiled with the full clanger soyboy toolchain, complete with mimalloc",
]

template developerOnly(body: untyped) =
  ## Professional anti-skidding tool.
  ## Wrap code blocks in this when you don't want potential skids to access something that can cause them to modify Roblox or do stupid shit in general.
  ## Beware that it lets them know that the codepath actually exists. Albeit that isn't very useful given the compiler will elide that unreachable code path at preprocessing
  ## time anyway.
  ##
  ## Example:
  ## .. code-block::Nim
  ##   developerOnly:
  ##     disableAPKSignatureVerification()
  when not defined(release):
    body
  else:
    error "This feature is only available in developer builds."
    quit(1)

proc showHelp(code: int = 0) {.noReturn.} =
  echo """
Usage: equinox [mode] [arguments] ...

equinox is a runtime for Roblox on Linux that uses LXC containers.
All commands need root access.

Legal Disclaimer: The Equinox developers do not make ANY monetary profit from this tool. It does not facilitate any forbidden modifications to the Roblox software. Equinox comes with zero warranty and does not have official support. The EquinoxHQ team has no affiliation with Roblox Corporation, or any of its associated entities. "Roblox" is a registered trademark of the Roblox Corporation.

Modes:
  init                 Initialize Equinox. Download the Android runtime images and Roblox.
  run                  Start the Equinox container with Roblox.
  halt                 Stop the Equinox container.

Developer Modes (ONLY AVAILABLE IN INTERNAL BUILDS):
  fetch-image-pair     Fetch a suitable image pair (system+vendor) from the Waydroid OTA
  shell                Run a shell command in the Android container
  sh                   Run a shell REPL in the Android container
  get-property         Fetch propert(y/ies) from the Android container
  get-gsf-id           Get the Google Services Framework Android ID from the container
  launch-app           Launch an application
"""
  quit(code)

proc main() {.inline.} =
  setLenUninit()
  addHandler(newColoredLogger())
  setLogFilter(lvlInfo)

  var input = parseInput()
  if input.enabled("verbose", "v"):
    setLogFilter(lvlAll)

  loadConfig(input)

  let lxcVersion = getLxcVersion()
  debug "lxc version: " & lxcVersion

  #[ if not isAdmin():
    error "Please run Equinox with root privileges."
    quit(1) ]#

  # var pair = getImages()
  case input.command
  of "init":
    initialize(input)
  of "install-apk":
    if input.arguments.len < 1:
      error "equinox: expected 1 argument, got none."
      error "equinox: Run equinox --help for more information."
      quit(1)

    installRobloxClient(input.arguments[0])
  of "run":
    randomize()
    echo "Splash: " & sample(Splashes)
    
    initNetworkService()
    startAndroidRuntime(input)
  of "shell":
    developerOnly:
      if input.arguments.len < 1:
        error "Usage: `equinox shell \"your command goes here\"`"
        quit(1)

      let output = runCmdInContainer(input.arguments[0])
      if *output:
        echo &output
      else:
        info "Command returned no output."
  of "help":
    showHelp()
  of "get-property":
    developerOnly:
      if input.arguments.len < 1:
        error "Usage: `equinox get-property your.property.name`"
        quit(1)

      if input.arguments.len == 1:
        let prop = getProp(input.arguments[0])
        if *prop:
          echo &prop
        else:
          error "No such property: " & input.arguments[0]
      else:
        for property in input.arguments:
          let value = getProp(property)
          if not *value:
            error "No such property: " & property
            quit(1)

          styledWriteLine(
            stdout,
            fgCyan,
            property,
            resetStyle,
            styleBright,
            ": ",
            resetStyle,
            fgGreen,
            &value,
            resetStyle,
          )
  of "fetch-image-pair":
    developerOnly:
      print getImages()
  of "halt":
    stopLxcContainer(
      force = input.enabled("force", "F") or input.enabled("my-time-has-value")
    )
  of "sh":
    developerOnly:
      var noise = Noise.init()
      let prompt = Styler.init(fgGreen, "sh", resetStyle, "> ")
      noise.setPrompt(prompt)

      while true:
        let ok = noise.readLine()
        if not ok:
          break

        let line = noise.getLine()
        if line == ".quit":
          break
        else:
          let output = runCmdInContainer(line)
          if *output:
            echo &output
  of "get-gsf-id":
    developerOnly:
      echo getGSFAndroidID()
  of "launch-app":
    developerOnly:
      var platform = getIPlatformService()
      platform.launchApp(input.arguments[0])
  of "net":
    if input.arguments.len < 1:
      error "equinox: `net` expects a subcommand (`start`)"
      quit(1)

    case input.arguments[0]
    of "start":
      initNetworkService()
    else:
      error "equinox: invalid subcommand for `net`: " & input.arguments[0]
      quit(1)
  else:
    error "equinox: invalid command: " & input.command
    quit(1)

when isMainModule:
  main()
