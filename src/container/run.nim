import std/[os, logging]
import ./[lxc, configuration, cpu, drivers]
import ./utils/mount

proc mountRootfs*(imagesDir: string) =
  debug "container/run: mounting system image"
  mount(imagesDir / "system.img", config.rootfs, umount = true)

  debug "container/run: mounting vendor image"
  mount(imagesDir / "vendor.img", config.rootfs / "vendor")

proc startAndroidRuntime*() =
  debug "equinox: starting prep for android runtime"

  mountRootfs(config.imagesPath)
  generateSessionLxcConfig()
