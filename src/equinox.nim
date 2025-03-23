import std/[os, logging, terminal, random, rdstdin, strutils]
import pkg/[colored_logger, pretty, noise]
import ./argparser
import
  container/[
    certification, lxc, image_downloader, configuration, init, run, sugar, properties,
    app_manager, platform, network, apk_fetcher,
  ]

const Splashes = [
  "\"pc game support when\" bro im not even done installing my rootkits on your pc -tray",
  "all hail the NT flying horse",
  "\"im in a perpetual state of shitting myself\" - hippoz, 2025",
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

Modes:
  init                 Initialize Equinox. Download the Android runtime images and Roblox.
  run                  Start the Equinox container with Roblox.
  halt                 Stop the Equinox container.

  net
    start              Start the networking bridge. This is already called by `run` upon starting up.
    stop               Stop the networking bridge. This is already called by `run` upon exiting.

Developer Modes (ONLY AVAILABLE IN INTERNAL BUILDS):
  fetch-image-pair     Fetch a suitable image pair (system+vendor) from the Waydroid OTA
  shell                Run a shell command in the Android container
  sh                   Run a shell REPL in the Android container
  get-property         Fetch propert(y/ies) from the Android container
  get-gsf-id           Get the Google Services Framework Android ID from the container
  remove-app           Remove an application
  launch-app           Launch an application
"""
  quit(code)

proc main() {.inline.} =
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
  of "install":
    if not input.enabled("consented", "C"):
      echo """
Notice: You are about to use the Google Play API to download Roblox's Android package.
You must read the Google Play Terms of Service to continue (https://play.google.com/about/play-terms/index.html).
EquinoxHQ is not responsible for any of your actions.
      """
      let consent = readLineFromStdin("Do you consent? [y/N]: ").toLowerAscii()
      if consent != "y":
        error "equinox: aborted."
        quit(1)

    info "equinox: fetching Roblox " & SelectedVersion & " links from EquinoxHQ endpoint"
    let packages = fetchRobloxApk()

    info "equinox: downloading packages"
    downloadApks(packages, input)
  of "remove-app":
    developerOnly:
      if input.arguments.len < 1:
        error "equinox: expected 1 argument, got none."
        error "equinox: Run equinox --help for more information."
        quit(1)

      var platform = getIPlatformService()
      platform.removeApp(input.arguments[0])
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
      error "equinox: `net` expects a subcommand (`start`, `stop`)"
      quit(1)

    case input.arguments[0]
    of "start":
      initNetworkService()
    of "stop":
      stopNetworkService()
    else:
      error "equinox: invalid subcommand for `net`: " & input.arguments[0]
      quit(1)
  else:
    error "equinox: invalid command: " & input.command
    quit(1)

when isMainModule:
  main()
