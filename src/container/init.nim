import std/[os, logging]
import ./[lxc, configuration, cpu, drivers, image_downloader, hal]
import ../argparser

proc setupConfig*(): bool =
  loadConfig()
  config.arch = getHost().maybeRemap()

  let driverList = setupBinderNodes()

  debug "init: binder = " & driverList.binder
  debug "init: vndbinder = " & driverList.vndbinder
  debug "init: hwbinder = " & driverList.hwbinder
  config.binder = driverList.binder
  config.vndbinder = driverList.vndbinder
  config.hwbinder = driverList.hwbinder

  return true

proc initialize*(input: Input) =
  var status = "STOPPED"

  if not setupConfig():
    return

  if dirExists(config.lxc / "equinox"):
    status = getLxcStatus()

  if status != "STOPPED" and not input.enabled("ignore-container-state", "I"):
    error "init: TODO: stopping container"
    return

  discard existsOrCreateDir(config.work)
  discard existsOrCreateDir(config.rootfs)
  discard existsOrCreateDir(config.overlay)
  discard existsOrCreateDir(config.overlay / "vendor")
  discard existsOrCreateDir(config.overlayRw)
  discard existsOrCreateDir(config.overlayRw / "system")
  discard existsOrCreateDir(config.overlayRw / "vendor")
  discard existsOrCreateDir(config.work / "images")

  if not input.enabled("no-img-download", "Z"):
    let pair = getImages()
    pair.downloadImages()

  setLxcConfig()
  startLxcContainer(input)
  waitForContainerBoot()
  makeBaseProps()
  info "Initialized Equinox successfully."
