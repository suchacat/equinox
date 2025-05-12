## Container filesystem utilities
import std/[os]
import ./[paths]

proc containerHasFile*(name: string): bool =
  fileExists(getRootfsPath() / name)

proc containerHasDir*(name: string): bool =
  dirExists(getRootfsPath() / name)

proc containerRemoveFile*(name: string) =
  removeFile(getRootfsPath() / name)

proc containerRemoveDir*(name: string) =
  removeDir(getRootfsPath() / name)
