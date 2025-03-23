import std/[os, logging, strutils, posix]
import
  ./[
    lxc, configuration, cpu, drivers, hal, platform, network, sugar, hardware_service,
    rootfs, app_config, fflags,
  ]
import ../argparser
import ./utils/[exec, mount]

proc showUI*() =
  var platform = getIPlatformService()
  platform.launchApp("com.roblox.client")
  # platform.setProperty("waydroid.active_apps", "com.roblox.client")

proc startAndroidRuntime*(input: Input) =
  info "equinox: starting android runtime"
  debug "equinox: starting prep for android runtime"

  mountRootfs(input, config.imagesPath)

  debug "equinox: applying config"

  if input.enabled("apply-config", "C"):
    let config = loadAppConfig(input)
    setFflags(config.fflags)

  generateSessionLxcConfig()

  if getLxcStatus() == "RUNNING":
    debug "equinox: container is already running"
    showUI()
  else:
    startLxcContainer(input)

    var platform = getIPlatformService()
    platform.launchApp("com.roblox.client")

    let pid = (&readOutput("pidof", "init")).strip().split(' ')[0].parseUint()
      # FIXME: please fix this PEAK code to be less PEAK (it probably shits itself on non systemd distros)

    platform.setProperty("waydroid.active_apps", "com.roblox.client")

    # var hwsvc = startHardwareService()

    debug "equinox: waiting for init to exit: pid=" & $pid
    var status: cint
    while kill(Pid(pid), 0) == 0 or errno != ESRCH:
      sleep(100)

    if WIFEXITED(status):
      info "equinox: runtime has been stopped."
    else:
      warn "equinox: runtime stopped abnormally."

    stopNetworkService()
    # deinitHardwareService(hwsvc)
