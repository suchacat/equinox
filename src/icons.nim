import std/[os, logging]

const
  LucemIcon = staticRead("../assets/lucem.svg")

proc installIcons* =
  debug "icons: installing lucem icon"
  let icons = getHomeDir() / ".local" / "share" / "icons"
  discard existsOrCreateDir(icons)
  
  let customDir = icons / "equinoxhq"
  discard existsOrCreateDir(customDir)
  
  debug "icons: overwriting roblox icon as lucem's icon"
  writeFile(customDir / "waydroid.com.roblox.client.svg", LucemIcon)
