## Fastflag manager
import std/[os, tables, logging, json]
import ./[configuration]
import pkg/[pretty, jsony]

type
  FFlagList* = Table[string, JsonNode]

proc getRobloxStorageDir*: string =
  let robloxDir = config.equinoxData / "data" / "com.roblox.client"

  robloxDir

proc setFflags*(list: FFlagList) =
  debug "equinox: setting fflags (num: " & $list.len & ')'
  print list

  let serialized = toJson(list)

  debug "equinox: fflag json:\n" & serialized

  let clientSettings = getRobloxStorageDir() / "files" / "exe" / "ClientSettings"
  debug "equinox: client settings path: " & clientSettings

  discard existsOrCreateDir(clientSettings)
  writeFile(clientSettings / "ClientAppSettings.json", serialized)
