import std/[os, logging]
import ../argparser
import ./utils/mount, ./[hal, paths]

proc mountRootfs*(input: Input, imagesDir: string) =
  info "equinox: mounting rootfs"

  debug "container/run: mounting system image"
  mount(imagesDir / "system.img", getRootfsPath(), umount = true)

  debug "container/run: mounting vendor image"
  mount(imagesDir / "vendor.img", getRootfsPath() / "vendor")

  makeBaseProps(input)
  mountFile(getWorkPath() / "equinox.prop", getRootfsPath() / "vendor" / "waydroid.prop")
