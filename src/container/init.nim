import std/[os, logging]
import
  ./[
    lxc, configuration, cpu, drivers, image_downloader, hal, rootfs, configuration,
    network,
  ]
import ./utils/exec
import ../argparser

proc setupConfig*(input: Input): bool =
  loadConfig(input)
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

  if not setupConfig(input):
    return

  if status != "STOPPED" and not input.enabled("ignore-container-state", "I"):
    error "init: TODO: stopping container"
    return

  discard existsOrCreateDir(config.work)
  
  assert(config.equinoxData.len > 0)
  discard existsOrCreateDir(config.equinoxData)
  discard runCmd("sudo", "chmod 666 -R " & config.equinoxData)
  discard existsOrCreateDir(config.hostPerms)
  discard existsOrCreateDir(config.rootfs)
  discard existsOrCreateDir(config.overlay)
  discard existsOrCreateDir(config.overlay / "vendor")
  discard existsOrCreateDir(config.overlayRw)
  discard existsOrCreateDir(config.overlayRw / "system")
  discard existsOrCreateDir(config.overlayRw / "vendor")
  discard existsOrCreateDir(config.work / "images")
  discard existsOrCreateDir(config.lxc)
  discard existsOrCreateDir(config.lxc / "equinox")
  
  let imagesExist =
    fileExists(config.imagesPath / "system.img") and
    fileExists(config.imagesPath / "vendor.img")
  if not imagesExist:
    downloadImages()

  initNetworkService()
  mountRootfs(input, config.imagesPath)
  generateSessionLxcConfig()
  setLxcConfig()
  startLxcContainer(input)

  waitForContainerBoot()
  makeBaseProps(input)
  stopLxcContainer() # stop it afterwards
  stopNetworkService()
  info "Initialized Equinox successfully."
