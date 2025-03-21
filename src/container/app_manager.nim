## App manager for stuff like installing the Roblox APK
import std/[os, logging, sequtils, strutils, tables, tempfiles]
import pkg/[crunchy, zippy/ziparchives, pretty, jsony]
import ./[lxc, properties, sugar, trayperion, platform]

proc code(buf: string | static string, z: char): string =
  var x = buf
  for i in 0 ..< buf.len:
    x[i] = cast[char](cast[uint8](x[i]) xor cast[uint8](z))

  ensureMove(x)

const NTFlyingHorse =
  [code("aea00f82a3509f9dad890dc045e6947c0ef7ea2bb9fae70143b17af28af9edc0", 'K')]

type
  PackageInstallFailure* = object of ValueError
  SignatureVerificationFailed* = object of PackageInstallFailure
  InvalidAPKMManifest* = object of PackageInstallFailure
  UnsupportedArchitecture* = object of PackageInstallFailure
  CannotGetProps = object of PackageInstallFailure

  APKMManifest* = object
    apkm_version*: uint8
    apk_title*: string
    app_name*: string
    release_version*: string
    variant*: string
    release_title*: string
    versioncode*: string
    pname*: string
    post_date*: string
    capabilities*: seq[string]
    languages*: seq[string]
    arches*: seq[string]
    dpis*: seq[string]
    min_api*: string
    accent_color*: string
    apk_id*: uint64
    release_id*: uint64

proc installRobloxClient*(package: string) =
  if not fileExists(package):
    error "equinox: no such file: " & package

  info "equinox: installing roblox client package: " & package
  let extension = package.splitFile().ext

  case extension
  of ".apk":
    debug "equinox: file is an APK"

    when defined(release):
      let sum = sha256sum(readFile(package)).toHex()
      debug "equinox: package checksum: " & sum

      # signature verification, powered by NTFlyingHorseExW
      var verified = false
      for horse in NTFlyingHorse:
        if horse.code != sum:
          continue

        verified = true

      if not verified:
        error "equinox: APK checksum does not match server list"
        error "equinox: if this is a legitimate APK, contact us to add this package to our whitelist."
        raise newException(
          SignatureVerificationFailed,
          "No signature in server list matches this package's checksum",
        )

    var iplatform = getIPlatformService()
    iplatform.installApp(package)
  of ".apkm":
    # APKM files are just ZIP archives so we can open 'em up with Zippy
    debug "equinox: file is an APKM, de-compressing core package"

    let tempPath = genTempPath("equinox", "apkm")
    package.extractAll(tempPath)

    for required in ["info.json", "base.apk"]:
      if not fileExists(tempPath / required):
        error "equinox: cannot find file in APKM: " & required
        raise newException(
          InvalidAPKMManifest, "Cannot find required file in APKM package: " & required
        )

    # APKM bundle info
    let info = readFile(tempPath / "info.json")
    let manifest =
      try:
        fromJson(info, APKMManifest)
      except JsonError as exc:
        raise newException(InvalidAPKMManifest, "Cannot decode info.json: " & exc.msg)

    if manifest.pname != "com.roblox.client":
      error "equinox: invalid package name: " & manifest.pname
      error "equinox: are you trying to install a non-Roblox app? :P"
      raise newException(InvalidAPKMManifest, "Invalid package name: " & manifest.pname)

    info "equinox: installing Roblox version " & manifest.releaseVersion & " (" &
      manifest.versioncode & ')'
    info "equinox: " & $manifest.arches.len & " splits, " & $manifest.languages.len &
      " supported languages"

    let arch = getProp("ro.product.cpu.abi")
    if not *arch:
      error "equinox: you haven't initialized the container yet (or it's halted)."
      raise newException(CannotGetProps, "Container not reachable")

    let architecture = &arch

    if architecture notin manifest.arches:
      error "equinox: this APKM does not support your architecture: " & architecture
      error "equinox: architectures supported by this APKM:"
      for arch in manifest.arches:
        echo "* " & arch
      raise newException(
        UnsupportedArchitecture, "This APKM does not support your architecutre"
      )

    let base = tempPath / "base.apk"
    let splitConfig = tempPath / "split_config." & architecture & ".apk"
    
    installSplitApp(base, splitConfig)
    removeDir(tempPath)
  else:
    error "equinox: unknown format: " & extension
    error "equinox: please provide a APK (regular Android package) or APKM (APKMirror bundle)"
    quit(1)
