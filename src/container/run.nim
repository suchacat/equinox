import std/[os, logging]
import ./[lxc, configuration, cpu, drivers, hal]
import ../argparser
import ./utils/mount

proc mountRootfs*(input: Input, imagesDir: string) =
  debug "container/run: mounting system image"
  mount(imagesDir / "system.img", config.rootfs, umount = true)

  debug "container/run: mounting vendor image"
  mount(imagesDir / "vendor.img", config.rootfs / "vendor")
  
  makeBaseProps(input)
  mountFile(config.work / "equinox.prop", config.rootfs / "vendor" / "waydroid.prop")

proc startAndroidRuntime*(input: Input) =
  debug "equinox: starting prep for android runtime"

  mountRootfs(input, config.imagesPath)
  generateSessionLxcConfig()
