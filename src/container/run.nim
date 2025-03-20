import std/[os, logging]
import ./[lxc, configuration, cpu, drivers, hal, trayperion, platform]
import ../argparser
import ./utils/mount

proc mountRootfs*(input: Input, imagesDir: string) =
  info "equinox: mounting rootfs"

  debug "container/run: mounting system image"
  mount(imagesDir / "system.img", config.rootfs, umount = true)

  debug "container/run: mounting vendor image"
  mount(imagesDir / "vendor.img", config.rootfs / "vendor")

  makeBaseProps(input)
  mountFile(config.work / "equinox.prop", config.rootfs / "vendor" / "waydroid.prop")

proc showUI*() =
  var platform = getIPlatformService()
  platform.launchApp("com.roblox.client")
  platform.setProperty("waydroid.active_apps", "com.roblox.client")

proc startAndroidRuntime*(input: Input) =
  info "equinox: starting android runtime"
  debug "equinox: starting prep for android runtime"

  mountRootfs(input, config.imagesPath)
  setLenUninit()
  generateSessionLxcConfig()

  if getLxcStatus() == "RUNNING":
    debug "equinox: container is already running"
    showUI()
  else:
    startLxcContainer(input)
