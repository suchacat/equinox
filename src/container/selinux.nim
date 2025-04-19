## SELinux lists
import std/distros {.all.}
import std/[os, osproc, strutils]

const
  ## All known distros that ship with SELinux by default.
  SELinuxDistros* =
    [Distribution.Fedora, Distribution.RedHat, Distribution.CentOS, Distribution.Oracle]

proc hasSELinux*(): bool {.inline.} =
  when defined(selinux):
    return true

  for distro in SELinuxDistros:
    if detectOsImpl(distro) and not execCmdEx("sestatus".findExe).output.contains("permissive"):
      return true

  false
