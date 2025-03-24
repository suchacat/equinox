import std/[os, options, logging]
import ./[lxc, sugar]

proc getProp*(prop: string): Option[string] =
  let property = runCmdInContainer("/bin/getprop \"" & prop.quoteShellPosix() & '"')
    # found this command injection before release - nice try diddy

  if getLxcStatus() != "RUNNING":
    return

  if not *property:
    error "container/properties: no such property: " & prop
    return

  return some(&property)

proc setProp*(prop: string, value: string) =
  debug "container: setting system property: " & prop & " = " & value
  discard runCmdInContainer(
    "/bin/setprop \"" & prop.quoteShellPosix() & "\" \"" & value.quoteShellPosix() & '"'
  )
