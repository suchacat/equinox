## Fetch Roblox's APK from Kirbix's Github endpoint
import std/[os, tables, logging]
import pkg/[jsony]
import ./utils/[exec, http]
import ./[configuration, properties, lxc]

const
  APKEndpoint* = "https://k1yrix.github.io/project-equinox-json/equinox.json"
  SelectedVersion* {.strdefine: "RobloxVersionTarget".} = "2.664.714"

type
  APKNotFound* = object of ValueError

  APKVersion* = object
    base*, split*: string

  APKEndpointResponse* = object
    version*: Table[string, APKVersion]

proc fetchRobloxApk*: APKVersion =
  debug "apk: fetching data from endpoint: " & APKEndpoint
  let resp = httpGet(APKEndpoint).body.fromJson(APKEndpointResponse)

  if SelectedVersion notin resp.version:
    error "apk: endpoint did not provide requested version: " & SelectedVersion
    raise newException(APKNotFound, "No such version: " & SelectedVersion)
  
  return resp.version[SelectedVersion]

proc downloadApks*(ver: string, pkg: APKVersion) =
  debug "apk: downloading packages"
  
  var useCache = false
  if dirExists(config.work / "apk" / ver):
    debug "apk: using cached version"
    useCache = true

  let
    baseApk =
      if useCache:
        httpGet(pkg.base).body
      else:
        readFile(config.work / "apk" / ver / "base.apk")

    splitApk =
      if useCache:
        httpGet(pkg.split).body
      else:
        readFile(config.work / "apk" / ver / "split.apk")
  
  debug "apk: caching results"
  discard existsOrCreateDir(config.work / "apk")
  discard existsOrCreateDir(config.work / "apk" / ver)

  writeFile(config.work / "apk" / ver / "base.apk", baseApk)
  writeFile(config.work / "apk" / ver / "split.apk", splitApk)

  debug "apk: writing to shared equinox data dir"
  writeFile(config.equinoxData / "base.apk", baseApk)
  writeFile(config.equinoxData / "split.apk", splitApk)

  setProp("service.adb.tcp.port", "9782")
  discard runCmdInContainer("stop adbd")
  discard runCmdInContainer("start adbd")

  let
    baseApkPath = config.equinoxData / "base.apk"
    splitApkPath = config.equinoxData / "split.apk"
  
  runCmd "adb", "connect localhost:9782"
  runCmd "adb", "install-multiple " & baseApkPath & ' ' & splitApkPath
