## Fastflag manager
import std/[os, tables, logging, json]
import ./paths, ../argparser
import pkg/[pretty, jsony, shakar]

type FFlagList* = Table[string, JsonNode]

proc setFflags*(input: Input, list: FFlagList) =
  debug "equinox: setting fflags (num: " & $list.len & ')'
  print list

  let serialized = toJson(list)

  debug "equinox: fflag json:\n" & serialized
  
  let storageDir = getAppDataPath(&input.flag("user"), "com.roblox.client")
  if not dirExists(storageDir / "files"):
    warn "equinox: TODO: first-boot fflag patching support"
    return

  let clientSettings = storageDir / "files" / "exe" / "ClientSettings"
  debug "equinox: client settings path: " & clientSettings

  try:
    discard existsOrCreateDir(clientSettings)
    writeFile(clientSettings / "ClientAppSettings.json", serialized)
  except OSError as exc:
    warn "equinox: " & exc.msg # TODO: fix this stupid stuff
