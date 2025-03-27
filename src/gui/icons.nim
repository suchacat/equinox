import std/[os, logging]

const LucemIcon = staticRead("../../assets/lucem.svg")

proc installIcons*() =
  debug "icons: installing lucem icon"
  let icons = getHomeDir() / ".local" / "share" / "icons"
  discard existsOrCreateDir(icons)

  let hicolorDir = icons / "hicolor"
  discard existsOrCreateDir(hicolorDir)

  let scalableDir = hicolorDir / "scalable"
  discard existsOrCreateDir(scalableDir)

  let appsDir = scalableDir / "apps"
  discard existsOrCreateDir(appsDir)

  writeFile(appsDir / "waydroid.com.roblox.client.svg", LucemIcon)
  writeFile(appsDir / "equinox.svg", LucemIcon)
