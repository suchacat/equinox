## Forked (master-slave) IPC implementation
## Copyright (C) 2025 EquinoxHQ
import std/[posix, logging]

type
  IPCError* = object of OSError
  CantMakeSocketPair = object of IPCError

  IPCFds* = object
    master*, slave*: cint

proc initIpcFds*(): IPCFds =
  debug "ipc: initializing ipc file descriptors"
  var pair: array[2, cint]
  if (let status = socketpair(AF_UNIX, SOCK_STREAM, 0, pair); status != 0):
    raise newException(
      CantMakeSocketPair,
      "socketpair() returned " & $status & ": " & $strerror(errno) & " (errno " & $errno &
        ')',
    )

  debug "ipc: master = " & $pair[0] & "; slave = " & $pair[1]
  IPCFds(master: pair[0], slave: pair[1])

proc send*[X: enum](fd: cint, op: X): bool {.discardable.} =
  ## Send an enum of type `X` to the other side.
  write(fd, op.addr, 1) == 1

proc close*(fds: var IPCFds) =
  ## Close both the IPC file descriptors.
  ## **WARNING**: This must only be called by the master! If you call it from the slave, there might be unexpected behaviour.
  debug "ipc: closing file descriptors"

  assert(
    fds.master.close() == 0,
    "BUG: Failed to close master fd: " & $strerror(errno) & " (errno " & $errno & ')',
  )
  assert(
    fds.slave.close() == 0,
    "BUG: Failed to close master fd: " & $strerror(errno) & " (errno " & $errno & ')',
  )

  debug "ipc: closed file descriptors"
