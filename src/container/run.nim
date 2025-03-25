import std/[os, logging, strutils, sequtils, posix, tables, json]
import
  ./[
    lxc, configuration, cpu, drivers, hal, platform, network, sugar, hardware_service,
    rootfs, app_config, fflags, properties,
  ]
import ../argparser
import ./utils/[exec, mount]

proc showUI*() =
  var platform = getIPlatformService()
  platform.launchApp("com.roblox.client")
  platform.setProperty("waydroid.active_apps", "com.roblox.client")

proc startAndroidRuntime*(input: Input) =
  info "equinox: starting android runtime"
  debug "equinox: starting prep for android runtime"

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

    while isEmptyOrWhitespace(&readOutput("pidof", "com.roblox.client")):
      # FIXME: please don't do this
      platform.launchApp("com.roblox.client")

    let pid = parseUint(&readOutput("pidof", "com.roblox.client"))

    debug "equinox: waiting for roblox to exit: pid=" & $pid
    var status: cint
    while kill(Pid(pid), 0) == 0 or errno != ESRCH:
      sleep(100)

    if WIFEXITED(status):
      info "equinox: runtime has been stopped."
    else:
      warn "equinox: runtime stopped abnormally."

    stopNetworkService()
    stopLxcContainer()
    # deinitHardwareService(hwsvc)
