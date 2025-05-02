## Fastflag manager
import std/[os, tables, logging, json]
import ./[configuration]
import pkg/[pretty, jsony]

type FFlagList* = Table[string, JsonNode]

proc getRobloxStorageDir*(): string =
  let robloxDir = config.equinoxData / "data" / "com.roblox.client"

  robloxDir

proc setFflags*(list: FFlagList) =
  debug "equinox: setting fflags (num: " & $list.len & ')'
  print list

  let serialized = toJson(list)

  debug "equinox: fflag json:\n" & serialized

  if not dirExists(getRobloxStorageDir() / "files"):
    warn "equinox: TODO: first-boot fflag patching support"
    return

  let clientSettings = getRobloxStorageDir() / "files" / "exe" / "ClientSettings"
  debug "equinox: client settings path: " & clientSettings
  
  try:
    discard existsOrCreateDir(clientSettings)
    writeFile(clientSettings / "ClientAppSettings.json", serialized)
  except OSError as exc:
    warn "equinox: " & exc.msg # TODO: fix this stupid stuff
