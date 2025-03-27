## equinox gui integration
import std/[os, logging]
import pkg/[colored_logger]
import ./gui/[onboard, icons, launcher]
import ./[argparser]

proc isFirstRun*(input: Input): bool =
  not dirExists(getHomeDir() / ".local" / "share" / "equinox") or
    input.enabled("force-first-run", "F")

proc showOnboardingGui() =
  debug "gui: showing onboarding gui"
  runOnboardingApp()

proc showLauncher() =
  debug "gui: launcher gui spawned"
  runLauncher()

proc main() {.inline.} =
  addHandler(newColoredLogger())
  setLogFilter(lvlInfo)
  let input = parseInput()
  if input.enabled("verbose", "v"):
    setLogFilter(lvlAll)

  installIcons()

  case input.command
  of "onboarding":
    showOnboardingGui()
  of "launcher":
    showLauncher()
  else:
    error "equinox-gui: invalid command: " & input.command

when isMainModule:
  main()
