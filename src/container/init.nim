import std/[os, logging]
import pkg/shakar
import
  ./[
    lxc, cpu, drivers, image_downloader, hal, rootfs, paths,
    network,
  ]
import ./utils/exec
import ../argparser

proc initialize*(input: Input) =
  var status = "STOPPED"

  if status != "STOPPED" and not input.enabled("ignore-container-state", "I"):
    error "init: TODO: stopping container"
    return

  discard existsOrCreateDir(getWorkPath())
  discard existsOrCreateDir(getEquinoxDataPath(&input.flag("user")))
  discard existsOrCreateDir(getHostPermsPath())
  discard existsOrCreateDir(getRootfsPath())
  discard existsOrCreateDir(getOverlayPath())
  discard existsOrCreateDir(getOverlayPath() / "vendor")
  discard existsOrCreateDir(getOverlayRwPath())
  discard existsOrCreateDir(getOverlayRwPath() / "system")
  discard existsOrCreateDir(getOverlayRwPath() / "vendor")
  discard existsOrCreateDir(getImagesPath())
  discard existsOrCreateDir(getLxcPath())
  discard existsOrCreateDir(getEquinoxLxcConfigPath())

  let imagesExist =
    fileExists(getImagesPath() / "system.img") and
    fileExists(getImagesPath() / "vendor.img")
  if not imagesExist:
    downloadImages()

  initNetworkService()
  mountRootfs(input, getImagesPath())
  generateSessionLxcConfig(input)
  setLxcConfig(input)
  startLxcContainer(input)

  waitForContainerBoot()
  makeBaseProps(input)
  stopLxcContainer(false)
    # stop it afterwards, but give it time to do whatever it fancies.
  stopNetworkService()
  info "Initialized Equinox successfully."
