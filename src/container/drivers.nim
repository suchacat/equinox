import std/[os, logging, strutils, posix, options]
import pkg/shakar
import ./utils/exec
import ./[paths, selinux]

const
  BINDER_DRIVERS = ["anbox-binder", "puddlejumper", "bonder", "binder"]
  VNDBINDER_DRIVERS = ["anbox-vndbinder", "vndpuddlejumper", "vndbonder", "vndbinder"]
  HWBINDER_DRIVERS = ["anbox-hwbinder", "hwpuddlejumper", "hwbonder", "hwbinder"]

proc devExists*(file: string): bool =
  var sb: Stat

  if stat(file, sb) == 0.cint:
    if S_ISCHR(sb.stMode):
      debug "drivers: character device found: " & file
      return true
    else:
      warn "drivers: path exists but is NOT a character device: " & file
  else:
    debug "drivers: device does not exist: " & file

  return false

type
  BinderDriver* = object
    binder*, hwbinder*, vndbinder*: Option[string]

  BinderNode {.packed.} = object
    name: array[0 .. 255, char]
    ctl0, ctl1: uint32

proc ioctl(
  fd: cint, request: uint, data: pointer
): cint {.importc, header: "<sys/ioctl.h>".}

proc isBinderfsLoaded*(): bool =
  for line in readFile("/proc/filesystems").splitLines():
    let words = line.split()
    if words.len >= 2 and words[1] == "binder":
      return true

  false

proc allocateBinderNode*(node: string) =
  debug "drivers: allocating binder node: " & node
  const
    NumBits = 8
    TypeBits = 8
    SizeBits = 14
    NumShift = 0
    TypeShift = NumShift + NumBits
    SizeShift = TypeShift + TypeBits
    DirShift = SizeShift + SizeBits
    Write = 0x1
    Read = 0x2

  func ioc(direction, typ, num, size: uint): uint {.inline.} =
    (direction shl DirShift) or (typ shl TypeShift) or (num shl NumShift) or
      (size shl SizeShift)

  func iowr(typ, num, size: uint): uint {.inline.} =
    ioc(Read or Write, typ, num, size)

  let binderCtlAdd = iowr(98, 1, 264)
  var binderCtlFd = open("/dev/binderfs/binder-control", O_RDONLY)
  if binderCtlFd < 0:
    error "drivers: cannot open /dev/binderfs/binder-control: " & $strerror(errno)
    error "drivers: hint: does your kernel not have binder support?"
    raise newException(Defect, "Cannot allocate binder nodes")

  var nodeStruct = BinderNode(ctl0: 0, ctl1: 0)
  for i, c in node:
    if i > 255:
      break

    nodeStruct.name[i] = c

  if ioctl(binderCtlFd, binderCtlAdd, nodeStruct.addr) < 0 and errno != EEXIST:
    error "drivers: an error occured while allocating binder node: " & node
    raise newException(
      Defect, "Cannot allocate binder node `" & node & "`: " & $strerror(errno)
    )

  discard close(binderCtlFd)

proc allocBinderNodes*(nodes: BinderDriver) =
  debug "drivers: allocating binder nodes"

  allocateBinderNode(&nodes.binder)
  allocateBinderNode(&nodes.hwbinder)
  allocateBinderNode(&nodes.vndbinder)

  debug "drivers: allocated binder nodes successfully"

proc probeBinderDriver*(): BinderDriver =
  debug "drivers: probing for binder driver(s)"
  var binderDevNodes = newSeqOfCap[string](3)
  var drivers: BinderDriver

  for binder in BINDER_DRIVERS:
    if devExists("/dev" / binder):
      drivers.binder = some(binder)
      break

  for hwbinder in HWBINDER_DRIVERS:
    if devExists("/dev" / hwbinder):
      drivers.hwbinder = some(hwbinder)
      break

  for vndbinder in VNDBINDER_DRIVERS:
    if devExists("/dev" / vndbinder):
      drivers.vndbinder = some(vndbinder)
      break

  if not (*drivers.binder and *drivers.hwbinder and *drivers.vndbinder) and isBinderfsLoaded():
    debug "drivers: creating /dev/binderfs"
    discard existsOrCreateDir("/dev/binderfs")

    debug "drivers: mounting binder at /dev/binderfs"
    discard runCmd("sudo", "mount -t binder binder /dev/binderfs")

    drivers.binder = some(BINDER_DRIVERS[0])
    drivers.hwbinder = some(HWBINDER_DRIVERS[0])
    drivers.vndbinder = some(VNDBINDER_DRIVERS[0])
    allocBinderNodes(drivers)

    for _, node in walkDir("/dev/binderfs"):
      let nam = node.split("/dev/binderfs/")[1]
      discard runCmd("sudo", "ln -s " & node & " /dev/" & nam)

  discard runCmd("sudo", "chmod 666 /dev/" & &drivers.binder)
  discard runCmd("sudo", "chmod 666 /dev/" & &drivers.hwbinder)
  discard runCmd("sudo", "chmod 666 /dev/" & &drivers.vndbinder)

  drivers
