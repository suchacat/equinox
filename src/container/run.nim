import std/[os, logging, strutils, sequtils, posix, tables, json]
import
  ./[
    lxc, configuration, cpu, drivers, hal, platform, network, sugar, hardware_service,
    rootfs, app_config, fflags, properties, roblox_logs,
  ]
import ../argparser
import ./utils/[exec, mount]

proc showUI*(launch: bool = true) =
  var platform = getIPlatformService()
  if launch:
    platform.launchApp("com.roblox.client")

  platform.setProperty("waydroid.active_apps", "com.roblox.client")

proc startRobloxClient*(platform: var IPlatform) =
  while isEmptyOrWhitespace(&readOutput("pidof", "com.roblox.client")):
    # FIXME: please don't do this
    platform.launchApp("com.roblox.client")
    sleep(100)

  startLogWatcher()

proc startAndroidRuntime*(input: Input, launchRoblox: bool = true) =
  info "equinox: starting android runtime"
  debug "equinox: starting prep for android runtime"

  destroyAllLogs()
  mountRootfs(input, config.imagesPath)

  var settings = loadAppConfig(input)

  debug "equinox: applying config"

  if *settings.maxFps:
    settings.fflags["DFIntTaskSchedulerTargetFps"] = newJInt(int(&settings.maxFps))

  settings.fflags["FFlagUserFyosDetectionHorseFly"] = newJBool(true)

  setFflags(settings.fflags)
  generateSessionLxcConfig()

  if getLxcStatus() == "RUNNING":
    debug "equinox: container is already running"
    showUI()
  else:
    startLxcContainer(input)

    var platform = getIPlatformService()
    platform.setProperty("waydroid.active_apps", "com.roblox.client")

    if launchRoblox:
      startRobloxClient(platform)

      let pid = parseUint(&readOutput("pidof", "com.roblox.client"))
      debug "equinox: waiting for roblox to exit: pid=" & $pid
      while kill(Pid(pid), 0) == 0 or errno != ESRCH:
        sleep(100)

      stopLogWatcher()
      stopNetworkService()
      stopLxcContainer()
    # deinitHardwareService(hwsvc)

type PlaceURI* = distinct string

proc launchRobloxGame*(input: Input, id: PlaceURI | string) =
  info "equinox: sending VIEW intent to roblox client"

  if getLxcStatus() != "RUNNING":
    startAndroidRuntime(input, launchRoblox = false)
  else:
    showUI(launch = false)

  var platform = getIPlatformService()

  while isEmptyOrWhitespace(&readOutput("pidof", "com.roblox.client")):
    # FIXME: please don't do this
    when id is string:
      platform.launchIntent("android.intent.action.VIEW", "roblox://placeId=" & id)
    else:
      platform.launchIntent("android.intent.action.VIEW", cast[string](id))

  platform.setProperty("waydroid.active_apps", "com.roblox.client")
