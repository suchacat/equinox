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

const
  SystemImageURL = "https://media.githubusercontent.com/media/equinoxhq/mirror/refs/heads/main/system.img"
  VendorImageURL = "https://media.githubusercontent.com/media/equinoxhq/mirror/refs/heads/main/vendor.img"

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

proc downloadImages*() =
  info "container/image: downloading image pair"

  info "container/image: downloading system image: " & SystemImageURL
  let systemReq = download(SystemImageURL)

  info "container/image: downloaded system image: " &
    $(systemReq.len.float / (2'f32.pow(30))) & " GB (compressed)"

  info "container/image: downloading vendor image: " & VendorImageURL
  let vendorReq = download(VendorImageURL)

  info "container/image: downloaded system image: " &
    $(vendorReq.len.float / (1024'f32.pow(3))) & " GB (compressed)"

  info "container/image: writing system image"
  writeFile(config.imagesPath / "system.img", systemReq)
  writeFile(config.imagesPath / "vendor.img", vendorReq)
  #[ var readerSys: ZipArchive
  assert(
    readerSys.open(config.imagesPath / "system.img.proto"),
    "Failed to open compressed system image",
  )
  readerSys.extractFile("system.img", config.imagesPath / "system.img")
  removeFile(config.imagesPath / "system.img.proto")

  info "container/image: writing vendor image"
  var readerVendor: ZipArchive
  assert(
    readerVendor.open(config.imagesPath / "vendor.img.proto"),
    "Failed to open compressed vendor image",
  )
  readerVendor.extractFile("vendor.img", config.imagesPath / "vendor.img")
  removeFile(config.imagesPath / "vendor.img.proto")]#

  info "container/image: downloaded Android container images successfully!"
