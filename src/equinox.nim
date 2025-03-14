import std/[os, logging, terminal]
import pkg/[colored_logger, pretty]
import ./argparser
import container/[lxc, image_downloader, configuration, init, run, sugar, properties]

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

proc main() {.inline.} =
  addHandler(newColoredLogger())
  setLogFilter(lvlInfo)

  info "Equinox starting up."
  loadConfig()

  var input = parseInput()
  if input.enabled("verbose", "v"):
    setLogFilter(lvlAll)

  let lxcVersion = getLxcVersion()

  debug "lxc version: " & lxcVersion

  if not isAdmin():
    error "Please run Equinox with root privileges."
    quit(1)

  # var pair = getImages()
  case input.command
  of "init":
    initialize(input)
  of "run":
    startAndroidRuntime()
    startLxcContainer()
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
  else:
    error "equinox: invalid command: " & input.command
    quit(1)

when isMainModule:
  main()
