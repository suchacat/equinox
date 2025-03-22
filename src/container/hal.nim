## Hardware abstraction layer utilities
import std/[os, logging, strutils]
import ../argparser
import ./[configuration, properties, filesystem, sugar, gpu, lxc]

proc findHal*(hardware: string): Option[string] =
  debug "lxc: finding hardware abstraction layer for hardware: " & hardware
  let props = [
    "ro.hardware." & hardware, "ro.hardware", "ro.product.board", "ro.arch",
    "ro.board.platform",
  ]

  for p in props:
    let prop = getProp(p)
    if not *prop:
      continue

    for lib in [
      "/odm/lib", "/odm/lib64", "/vendor/lib", "/vendor/lib64", "/system/lib",
      "/system/lib64",
    ]:
      let halFile = lib / "hw" / hardware & '.' & &prop & ".so"
      if containerHasFile(halFile):
        return prop

proc makeBaseProps*(input: Input) =
  var props: seq[tuple[key, value: string]]

  if not fileExists("/dev/ashmem"):
    debug "hal: ashmem not found, container will be forced to use memfd."
    props &= (key: "sys.use_memfd", value: "true")

  debug "hal: finding EGL and gralloc HAL"
  let node = getDriNode()

  let
    gralloc = "gbm"
    egl = "mesa"

  #[if not *gralloc:
    gralloc = some("android")
  else:
    if *node:
      debug "hal: we have a suitable GPU to use. Rendering will be hardware accelerated. Yippee. :D"
      gralloc = some("gbm")
      egl = some("mesa")
    else:
      warn "hal: we DO NOT have a suitable GPU to use! Rendering will NOT be hardware accelerated."
      warn "hal: this can happen if you have a Nvidia GPU. If you have an AMD/Intel GPU, please open a bug report."
      gralloc = some("default")
      egl = some("swiftshader") ]#

  props &= (key: "ro.hardware.gralloc", value: gralloc)
  props &= (key: "debug.stagefright.ccodec", value: "0")

  debug "hal: gralloc gbm device: " & (&node).dev
  props &= (key: "gralloc.gbm.device", value: (&node).dev)

  info "hal: using gralloc implementation: " & gralloc
  info "hal: you have EGL support."
  props &= (key: "ro.hardware.egl", value: egl)

  debug "hal: finding Vulkan HAL"
  var vulkan = findHal "vulkan"
  if not *vulkan and *node:
    debug "hal: cannot find suitable HAL for Vulkan, using system Vulkan drivers"
    vulkan = some(getVulkanDriver((&node).dev.splitPath().tail))

  if *vulkan:
    info "hal: you have Vulkan support."
    props &= (key: "ro.hardware.vulkan", value: &vulkan)
  else:
    warn "hal: your GPU does not support Vulkan!"

  # TODO: camera support

  var opengles = getProp("ro.opengles.version")
  if not *opengles:
    debug "hal: ro.opengles.version not set, setting it."
    opengles = some("196609")

  props &= (key: "ro.opengles.version", value: &opengles)
  props &= (key: "ro.vndk.lite", value: "false")

  for product in ["brand", "device", "manufacturer", "model", "name"]:
    let propProduct = getProp("ro.product.vendor." & product)

    if *propProduct:
      props &= (key: "ro.product.waydroid." & product, value: &propProduct)
    else:
      if containerHasFile("/proc" / "device-tree" / product):
        let content = readFile("/proc" / "device-tree" / product).strip().strip(
            chars = {'\x00'}, leading = false, trailing = true
          )

        if content.len > 0:
          props &= (key: "ro.product.waydroid." & product, value: content)

  let propFp = getProp("ro.vendor.build.fingerprint")
  if *propFp:
    debug "hal: build fingerprint: " & &propFp
    props &= (key: "ro.build.fingerprint", value: &propFp)

  for arg in ["wayland-display", "xdg-runtime-dir", "gid", "uid", "user"]:
    if not *input.flag(arg):
      error "equinox: did not get required argument: " & arg
      stopLxcContainer()
      quit(1)

  props &= (key: "waydroid.wayland_display", value: &input.flag("wayland-display"))
  props &= (key: "waydroid.open_windows", value: "1")
  props &= (key: "waydroid.xdg_runtime_dir", value: &input.flag("xdg-runtime-dir"))
  props &= (key: "waydroid.background_start", value: (if input.enabled("show-boot", "B"): "false" else: "true"))
  props &= (key: "waydroid.host.gid", value: &input.flag("gid"))
  props &= (key: "waydroid.host.uid", value: &input.flag("uid"))
  props &= (key: "waydroid.host.user", value: &input.flag("user"))
  props &= (key: "waydroid.keyboard_layout", value: "english")
  props &= (key: "waydroid.stub_sensors_hal", value: "1") # we don't need any sensors
  props &= (key: "ro.sf.lcd_density", value: "1") # TODO: fractional scaling support

  var builder: string
  for prop in props:
    builder &= prop.key & '=' & prop.value & '\n'

  writeFile(config.work / "equinox.prop", builder)
