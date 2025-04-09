## SELinux lists
import std/distros

const
  ## All known distros that ship with SELinux by default.
  SELinuxDistros*: set[Distribution] = {
    Distribution.Fedora, Distribution.RedHat,
    Distribution.CentOS, Distribution.Oracle
  }

proc hasSELinux*(): bool {.inline.} =
  defined(selinux) or detectOs() in SELinuxDistros
