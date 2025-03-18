import std/[algorithm, logging, math, os, strutils, sequtils]
import pkg/[curly, jsony, zip/zipfiles, pretty]
import utils/http
import ./[configuration, properties, sugar]

type
  ImageFetchFailure* = object of Defect

  Image* = object
    datetime*: uint64
    filename*: string
    id*: string
    romtypes*: string
    size*: uint64
    url*: string
    version*: string

  VendorImage* = object
    datetime*: uint64
    filename*: string
    id*: string
    romtype*: string
    size*: uint64
    url*: string
    version*: string

  ImageResponse = object
    response*: seq[Image]

  VendorImageResponse = object
    response*: seq[VendorImage]

  ImagePair* = object
    system*: Image
    vendor*: VendorImage

  ImageDownloadFailed* = object of CatchableError

proc getVendorType*(): string =
  #[ let vndkStr = getProp("ro.vndk.version")

  if *vndkStr:
    let vndk = parseUint(&vndkStr)
    let haliumVer =
      if vndk > 19 and vndk < 31:
        vndk - 19
      elif vndk > 31:
        vndk - 20
      else:
        0

    if haliumVer == 0:
      error "container: unsupported NDK version: " & &vndkStr
      raise newException(
        Defect,
        "Unsupported NDK version found! If you believe this is a mistake, file a bug report.",
      )

    if vndk == 32:
      return "HALIUM_" & $haliumVer & 'L'
    else:
      return "HALIUM_" & $haliumVer ]#

  return "MAINLINE"

proc getImages*(): ImagePair =
  var pair: ImagePair

  let systemReq = httpGet(
    config.systemOta & '/' & config.romType & "/waydroid_" & config.arch & '/' &
      config.systemType & ".json"
  )

  if systemReq.code != 200:
    raise newException(
      ImageFetchFailure,
      "Failed to get system OTA channel: " & systemReq.url & " (" & $systemReq.code & ')',
    )

  let systemImages =
    fromJson(systemReq.body, ImageResponse).response.sortedByIt(it.datetime).reversed()

  let latestSystem = systemImages[0]

  info "Latest system image: LineageOS " & latestSystem.version & " (" & latestSystem.url &
    ')'
  pair.system = latestSystem

  # let deviceCodename = &getProp("ro.product.device")

  for vendor in [getVendorType()]:
    let vendorReq =
      httpGet(config.vendorOta & "/waydroid_" & config.arch & '/' & vendor & ".json")
    if vendorReq.code == 200:
      info "container/image: found vendor image list for vendor: " & vendor

      let vendorImages = fromJson(vendorReq.body, VendorImageResponse).response
        .sortedByIt(it.datetime)
        .reversed()

      let latestVendor = vendorImages[0]

      info "Latest vendor image: " & latestVendor.romtype & ' ' & latestVendor.version &
        " (" & latestVendor.url & ')'
      pair.vendor = latestVendor
    else:
      warn "container/image: cannot find vendor image list for vendor: " & vendor

  assert(
    pair.vendor.version == pair.system.version,
    "Vendor image and system image are desynchronized! (vendor=" & pair.vendor.version &
      ", system=" & pair.system.version & ')',
  )

  ensureMove(pair)

proc downloadImages*(pair: ImagePair) =
  info "container/image: downloading image pair"
  assert(
    pair.vendor.version == pair.system.version,
    "Vendor image and system image are desynchronized! (vendor=" & pair.vendor.version &
      ", system=" & pair.system.version & ')',
  )

  info "container/image: downloading system image: " & pair.system.url
  let systemReq = httpGet(pair.system.url)

  if systemReq.code != 200:
    error "container/image: failed to fetch system image: got non-200 response: " &
      $systemReq.code
    raise newException(
      ImageDownloadFailed,
      "System image request got non-200 response: " & $systemReq.code,
    )

  info "container/image: downloaded system image: " &
    $(systemReq.body.len.float / (2'f32.pow(30))) & " GB (compressed)"

  info "container/image: downloading vendor image: " & pair.vendor.url
  let vendorReq = httpGet(pair.vendor.url)

  if vendorReq.code != 200:
    error "container/image: failed to fetch vendor image: got non-200 response: " &
      $systemReq.code
    raise newException(
      ImageDownloadFailed,
      "Vendor image request got non-200 response: " & $vendorReq.code,
    )

  info "container/image: downloaded system image: " &
    $(vendorReq.body.len.float / (1024'f32.pow(3))) & " GB (compressed)"

  info "container/image: writing system image"
  writeFile(config.imagesPath / "system.img.proto", systemReq.body)
  var readerSys: ZipArchive
  assert(
    readerSys.open(config.imagesPath / "system.img.proto"),
    "Failed to open compressed system image",
  )
  readerSys.extractFile("system.img", config.imagesPath / "system.img")
  removeFile(config.imagesPath / "system.img.proto")

  info "container/image: writing vendor image"
  writeFile(config.imagesPath / "vendor.img.proto", vendorReq.body)
  var readerVendor: ZipArchive
  assert(
    readerVendor.open(config.imagesPath / "vendor.img.proto"),
    "Failed to open compressed vendor image",
  )
  readerVendor.extractFile("vendor.img", config.imagesPath / "vendor.img")
  removeFile(config.imagesPath / "vendor.img.proto")

  info "container/image: downloaded Android container images successfully!"
