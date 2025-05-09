import std/[os, logging, terminal, random, rdstdin, strutils]
import pkg/[colored_logger, noise], pkg/nimsimd/runtimecheck
import ./argparser
import
  container/[
    certification, lxc, configuration, init, sugar, properties, app_manager, platform,
    network, cpu,
  ],
  container/utils/mount,
  core/[apk_fetcher, run, meta]

proc showMeta() =
  stdout.write """
Equinox $1 ($5)
Copyright (C) 2025 The EquinoxHQ Team
This software is licensed under the MIT license.

* Compiled with Nim $2
* Compiled on $3
* Roblox target: $4

* Detected CPU Architecture: $6
* Supports SSE3: $7
* Supports SSE4.2: $8
* Supports AVX2: $9
""" %
  [
    Version,
    NimVersion,
    CompileTime,
    SelectedVersion,
    CommitHash,
    getArchStr().maybeRemap(),
    $checkInstructionSets({SSE3}),
    $checkInstructionSets({SSE42}),
    $checkInstructionSets({AVX2}),
  ]

proc showHelp(code: int = 0) {.noReturn.} =
  echo """
Usage: equinox [mode] [arguments] ...

equinox is a runtime for Roblox on Linux that uses LXC containers.
All commands need root access. Do not use this command if you do not know what you're doing!
Use the GUI (equinox_gui) instead.

Modes:
  init                 Initialize Equinox. Download the Android runtime images.
  run                  Start the Equinox container and launch Roblox.
  halt                 Stop the Equinox container.

  net
    start              Start the networking bridge. This is already called by `run` upon starting up.
    stop               Stop the networking bridge. This is already called by `run` upon exiting.
  
  meta                 Get build metadata
  shell                Run a shell command in the Android container
  sh                   Run a shell REPL in the Android container
  install              Automatically fetch and install Roblox
  install-apk          Install Roblox from an APK/APKM file supplied by the user
  get-property         Fetch propert(y/ies) from the Android container
  get-gsf-id           Get the Google Services Framework Android ID from the container
  remove-app           Remove an application
  launch-app           Launch an application
  launch-game          Launch a Roblox game/experience with its ID.
  launch-game-uri      Launch a Roblox game/experience with its URI.
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
  of "unmount":
    loadConfig(input)
    umountAll(config.rootfs)
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

    initNetworkService()
    startAndroidRuntime(input, launchRoblox = false)

    info "equinox: fetching Roblox " & SelectedVersion & " links from EquinoxHQ endpoint"
    let packages = fetchRobloxApk()

    info "equinox: downloading packages"
    downloadApks(packages, input)
    stopLxcContainer(force = true)
  of "remove-app":
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
    startAndroidRuntime(input, not input.enabled("warmup", "W"))
  of "shell":
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
  of "halt":
    stopLxcContainer(
      force = input.enabled("force", "F") or input.enabled("my-time-has-value")
    )
  of "sh":
    if not isAdmin():
      error "equinox: this command requires root privileges"
      quit(1)

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
    echo getGSFAndroidID()
  of "launch-app":
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
  of "launch-game":
    if input.arguments.len < 1:
      error "equinox: `launch-game` expects a game ID"
      quit(1)

    let id = input.arguments[0]
    launchRobloxGame(input, id)
  of "launch-game-uri":
    if input.arguments.len < 1:
      error "equinox: `launch-game-uri` expects a game URI (format: `roblox://placeId=<Place ID>`)"
      quit(1)

    let uri = cast[PlaceURI](input.arguments[0])
    launchRobloxGame(input, uri)
  of "meta":
    showMeta()
  else:
    error "equinox: invalid command: " & input.command
    quit(1)

when isMainModule:
  main()
