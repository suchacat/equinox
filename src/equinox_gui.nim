## equinox gui integration
import std/[os, osproc, logging, posix]
import pkg/[colored_logger]
import ./gui/[onboard, icons, launcher, envparser, desktop_files, apk_install]
import ./container/[apk_fetcher]
import ./[argparser]

proc isFirstRun*(input: Input): bool =
  not dirExists(getHomeDir() / ".local" / "share" / "equinox") or
    input.enabled("force-first-run", "F")

proc needsApkUpdate*(): bool =
  not dirExists("/var" / "lib" / "equinox" / "apk" / SelectedVersion)

proc showOnboardingGui() =
  debug "gui: showing onboarding gui"
  runOnboardingApp()

proc showLauncher() =
  debug "gui: launcher gui spawned"
  runLauncher()

proc showApkUpdater() =
  debug "gui: apk updater spawned"
  runApkFetcher()

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
    if needsApkUpdate() and not input.enabled("skip-apk-updates", "X"):
      showApkUpdater()
      quit(0)
        # TODO: make the launcher show afterwards without a restart of the app. Right now it just.... closes immediately after the updater is done
        # probably has something to do with how owlkettle handles the closing of a window?

    showLauncher()
  of "mime-handler":
    let env = getXdgEnv()
    discard execCmd(
      "pkexec " & env.equinoxPath & " launch-game-uri " & input.arguments[0] & " --user:" &
        env.user & " --uid:" & $getuid() & " --gid:" & $getgid() & " --wayland-display:" &
        env.waylandDisplay & " --xdg-runtime-dir:" & env.runtimeDir
    )
  of "auto":
    if not dirExists(getHomeDir() / ".local" / "share" / "equinox"):
      showOnboardingGui()
    else:
      if needsApkUpdate() and not input.enabled("skip-apk-updates", "X"):
        showApkUpdater()
      else:
        showLauncher()
  of "updater":
    showApkUpdater()
  else:
    error "equinox-gui: invalid command: " & input.command

when isMainModule:
  main()
