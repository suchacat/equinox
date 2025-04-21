## Fetch Roblox's APK from Kirbix's Github endpoint
import std/[os, tables, logging]
import pkg/[jsony]
import ./utils/[exec, http]
import ./[configuration, properties, lxc, platform]
import ../argparser

const
  APKEndpoint* = "https://equinoxhq.github.io/equinox-json/equinox.json"
  SelectedVersion* {.strdefine: "RobloxVersionTarget".} = "2.669.664"

type
  APKNotFound* = object of ValueError

  APKVersion* = object
    expired*: bool
    base*, split*: string

  APKEndpointResponse* = object
    version*: Table[string, APKVersion]

proc fetchRobloxApk*(): APKVersion =
  debug "apk: fetching data from endpoint: " & APKEndpoint
  let resp = httpGet(APKEndpoint).body.fromJson(APKEndpointResponse)

  if SelectedVersion notin resp.version:
    error "apk: endpoint did not provide requested version: " & SelectedVersion
    raise newException(APKNotFound, "No such version: " & SelectedVersion)

  return resp.version[SelectedVersion]

proc downloadApks*(pkg: APKVersion, input: Input, ver: string = SelectedVersion) =
  debug "apk: downloading packages"
  assert(
    not pkg.expired,
    "Cannot download expired APK! It'll probably just cause Roblox to not work.",
  )

  var useCache = false

  if not input.enabled("force-no-cache", "J") and dirExists(config.work / "apk" / ver):
    debug "apk: using cached version"
    useCache = true

  let
    baseApk =
      if not useCache:
        httpGet(pkg.base).body
      else:
        readFile(config.work / "apk" / ver / "base.apk")

    splitApk =
      if not useCache:
        httpGet(pkg.split).body
      else:
        readFile(config.work / "apk" / ver / "split.apk")

  debug "apk: caching results"
  discard existsOrCreateDir(config.work / "apk")
  discard existsOrCreateDir(config.work / "apk" / ver)

  writeFile(config.work / "apk" / ver / "base.apk", baseApk)
  writeFile(config.work / "apk" / ver / "split.apk", splitApk)

  installSplitApp(
    config.work / "apk" / ver / "base.apk", config.work / "apk" / ver / "split.apk"
  )
