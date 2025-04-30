## Forked (master-slave) IPC implementation
## Copyright (C) 2025 EquinoxHQ
import std/[posix, logging, options]

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
  debug "ipc: sending op: " & $op
  write(fd, op.addr, 1) == 1

proc receive*[X: enum](fd: cint): Option[X] =
  var op: X
  assert(
    read(fd, op.addr, 1) == 1,
    "BUG: read() failed: " & $strerror(errno) & " (errno " & $errno & ')',
  )

  some(ensureMove(op))

proc receiveNonBlocking*[X: enum](fd: cint): Option[X] =
  ## Receive an `Option[X]` which will be full only
  ## if the file descriptor has incoming data.
  var readfds: TFdSet
  var timeout: Timeval

  FD_ZERO(readfds)
  FD_SET(fd, readfds)
  var ret = select(fd + 1.cint, readfds.addr, nil, nil, timeout.addr)
  if ret < 0 or not bool(FD_ISSET(fd, readfds)):
    return # We have no incoming data. If we call read, we'll probs end up blocking.

  some(receive(fd))

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
