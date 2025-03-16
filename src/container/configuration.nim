import std/[os, sequtils]
import pkg/[glob]

type Config* = object
  arch*: string
  work*: string
  vendorType*: string
  systemDatetime*: uint64
  vendorDatetime*: uint64
  preinstalledImagePaths*: seq[string]
  suspendAction*: string
  mount_overlays*: string
  autoAdb*: string
  containerXdgRuntimeDir*: string
  containerWaylandDisplay*: string

  imagesPath*: string
  rootfs*: string
  overlay*: string
  overlayRw*: string
  overlayWork*: string
  data*: string
  lxc*: string
  hostPerms*: string

  containerPulseRuntimePath*: string
  equinoxData*: string

  systemOta*: string
  vendorOta*: string

  romType*: string
  systemType*: string

  binder*, vndbinder*, hwbinder*: string

var config*: Config

proc loadConfig*() {.sideEffect.} =
  config = Config(
    arch: "x86_64",
    work: "/var" / "lib" / "equinox",
    vendorType: "MAINLINE",
    preinstalledImagePaths: @["/var" / "lib" / "equinox" / "images"],
    suspendAction: "freeze",
    mountOverlays: "true",
    containerXdgRuntimeDir: "/run/user/1000",
    containerWaylandDisplay: getEnv("WAYLAND_DISPLAY", "wayland-0")
  )
  config.imagesPath = config.work / "images"
  config.rootfs = config.work / "rootfs"
  config.overlay = config.work / "overlay"
  config.overlayRw = config.work / "overlay_rw"
  config.overlayWork = config.work / "overlay_work"
  config.data = config.work / "data"
  config.lxc = config.work / "lxc"
  config.hostPerms = config.work / "host-permissions"
  config.containerPulseRuntimePath = config.containerXdgRuntimeDir / "pulse"

  let defEquinoxData = block:
    var x: string
    for k, f in walkDir("/home"):
      if k != pcDir:
        continue
      x = f
      break

    x / ".local" / "share" / "equinox"

  config.equinoxData = getEnv("XDG_DATA_HOME", defEquinoxData)

  discard existsOrCreateDir(config.equinoxData)

  config.vendorOta = "https://ota.waydro.id/vendor"
  config.romType = "lineage"
  config.systemType = "GAPPS"
  config.systemOta = "https://ota.waydro.id/system"
