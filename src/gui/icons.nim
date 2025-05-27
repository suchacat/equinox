import std/[os, logging]
import ./envparser

const EquinoxIcon = staticRead("../../assets/equinox.svg")

proc installIcons*() =
  if equinoxBin.len > 0:
    return

  debug "icons: installing equinox icon"
  let icons = getHomeDir() / ".local" / "share" / "icons"
  discard existsOrCreateDir(icons)

  let hicolorDir = icons / "hicolor"
  discard existsOrCreateDir(hicolorDir)

  let scalableDir = hicolorDir / "scalable"
  discard existsOrCreateDir(scalableDir)

  let appsDir = scalableDir / "apps"
  discard existsOrCreateDir(appsDir)

  writeFile(appsDir / "waydroid.com.roblox.client.svg", EquinoxIcon)
  writeFile(appsDir / "equinox.svg", EquinoxIcon)
