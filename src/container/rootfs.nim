import std/[os, logging]
import ../argparser
import ./utils/mount, ./[hal, configuration]

proc mountRootfs*(input: Input, imagesDir: string) =
  info "equinox: mounting rootfs"

  debug "container/run: mounting system image"
  mount(imagesDir / "system.img", config.rootfs, umount = true)

  debug "container/run: mounting vendor image"
  mount(imagesDir / "vendor.img", config.rootfs / "vendor")

  makeBaseProps(input)
  mountFile(config.work / "equinox.prop", config.rootfs / "vendor" / "waydroid.prop")
