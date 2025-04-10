## SELinux lists
import std/distros {.all.}

const
  ## All known distros that ship with SELinux by default.
  SELinuxDistros* =
    [Distribution.Fedora, Distribution.RedHat, Distribution.CentOS, Distribution.Oracle]

proc hasSELinux*(): bool {.inline.} =
  when defined(selinux):
    return true

  for distro in SELinuxDistros:
    if detectOsImpl(distro):
      return true

  false
