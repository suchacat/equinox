## Container filesystem utilities
import std/[os, logging]
import ./[configuration]

proc containerHasFile*(name: string): bool =
  fileExists(config.rootfs / name)

proc containerHasDir*(name: string): bool =
  dirExists(config.rootfs / name)

proc containRemoveFile*(name: string) =
  removeFile(name)

proc containRemoveDir*(name: string) =
  removeDir(name)
