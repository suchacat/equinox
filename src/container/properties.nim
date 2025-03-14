import std/[os, options, logging]
import ./[lxc, sugar]

proc getProp*(prop: string): Option[string] =
  let property = &runCmdInContainer("/bin/getprop \"" & prop.quoteShellPosix() & '"') # found this command injection before release - nice try diddy
  if property.len < 1:
    error "container/properties: no such property: " & prop
    return

  return some(property)
