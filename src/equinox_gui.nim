## equinox gui integration
import std/[os, osproc, logging, posix]
import pkg/[colored_logger]
import ./gui/[onboard, icons, launcher, envparser, desktop_files]
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
  createDesktopEntries()
  createMimeHandlerEntry()

  case input.command
  of "onboarding":
    showOnboardingGui()
  of "launcher":
    showLauncher()
  of "mime-handler":
    let env = getXdgEnv()
    discard execCmd(
      "pkexec " & env.equinoxPath & " launch-game-uri " & input.arguments[0] &
      " --user:" & env.user & " --uid:" & $getuid() & " --gid:" & $getgid() & 
      " --wayland-display:" & env.waylandDisplay & " --xdg-runtime-dir:" & env.runtimeDir
    )
  of "auto":
    if not dirExists(getHomeDir() / ".local" / "share" / "equinox"):
      showOnboardingGui()
    else:
      showLauncher()
  else:
    error "equinox-gui: invalid command: " & input.command

when isMainModule:
  main()
