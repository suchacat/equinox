## Mandatory Access Control detection
## Copyright (C) 2025 EquinoxHQ
import std/os

type MACKind* {.pure, size: sizeof(uint8).} = enum
  None = 0 ## This system does not have a MAC system in place
  SELinux = 1 ## This system has SELinux enabled
  AppArmor = 2 ## This system has AppArmor enabled

proc detectMACKind*(): MACKind =
  ## Detect what kind of MAC this system is running.

  if dirExists("/etc/selinux"):
    return MACKind.SELinux

  if dirExists("/sys/module/apparmor"):
    return MACKind.AppArmor

  MACKind.None

proc getLXCConfigForMAC*(kind: MACKind = MACKind.None): string =
  case kind
  of MACKind.None, MACKind.SELinux:
    return newString(0)
  of MACKind.AppArmor:
    return "lxc.apparmor.profile = unconfined"
