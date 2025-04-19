## Container filesystem utilities
import std/[os, logging]
import ./[configuration]

proc containerHasFile*(name: string): bool =
  fileExists(config.rootfs / name)

proc containerHasDir*(name: string): bool =
  dirExists(config.rootfs / name)

proc containerRemoveFile*(name: string) =
  removeFile(config.rootfs / name)

proc containerRemoveDir*(name: string) =
  removeDir(config.rootfs / name)
