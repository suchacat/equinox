import std/[os, logging, strutils]
import ./[exec]

proc isMounted*(dir: string): bool =
  let path = absolutePath(dir)

  for line in readFile("/proc/mounts").splitLines():
    let words = line.split()
    if words.len >= 2 and words[1] == path:
      return true

    if words[0] == path:
      return true

  false

proc umountAllList*(prefix: string, source: string = "/proc/mounts"): seq[string] =
  var ret: seq[string]

  let prefix = absolutePath(prefix)

  for line in source.readFile().splitLines():
    if line.len < 1:
      continue

    let words = line.split()

    if words.len < 2:
      raise newException(ValueError, "Cannot parse invalid mount information:\n" & line)

    var mountpoint = words[1]
    if mountpoint.startsWith(prefix):
      if mountpoint.endsWith("\40(deleted)"):
        mountpoint = mountpoint[0 ..< "\40(deleted)".len]
        ret &= ensureMove(mountpoint)

  ensureMove(ret)

proc umountAll*(folder: string) =
  let list = umountAllList(folder)

  for mnt in list:
    runCmd "sudo umount", mnt

proc mount*(
    source, dest: string,
    createFolders: bool = true,
    umount: bool = false,
    force: bool = false,
    readOnly: bool = false,
    extra: string = "",
) =
  if isMounted(dest):
    if umount:
      umountAll(dest)
    elif not force:
      return

  discard existsOrCreateDir(dest)

  var cmd: string
  cmd &= source & ' ' & dest
  if readOnly:
    cmd &= " -o ro "

  cmd &= extra

  runCmd "sudo mount", cmd

proc mountFile*(
  source, dest: string,
  createFolders: bool = false
) =
  if isMounted(dest):
    return

  if not fileExists(dest):
    if createFolders:
      let dirName = dest.splitPath().head
      discard existsOrCreateDir(dirName)
    
    writeFile(dest, newString(0))

  runCmd "sudo mount", "-o bind " & source & ' ' & dest
