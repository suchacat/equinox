import std/[logging]
import ./[types]

var masterED*: ptr EventDispatcher ## Global event dispatcher

proc initEventDispatcher*(): EventDispatcher =
  info "lifecycle: event dispatcher is being initialized"
  assert(masterED == nil, "initEventDispatcher() called even though another event dispatcher instance is already running")
  var dispatcher = cast[ptr EventDispatcher](alloc(sizeof(EventDispatcher)))
  zeroMem(dispatcher, sizeof(EventDispatcher))
  dispatcher.channel.open()

  info "lifecycle: declaring ourselves the master event dispatcher"
  masterED = dispatcher
  
  dispatcher[]

proc feed*(dispatcher: var EventDispatcher, payload: EventPayload) =
  dispatcher.channel.send(payload)

proc checkChannel*(dispatcher: var EventDispatcher) =
  let attempt = dispatcher.channel.tryRecv()
  assert attempt.dataAvailable
  if attempt.dataAvailable:
    dispatcher.queue.add(attempt.msg)

proc poll*(dispatcher: var EventDispatcher, repoll: bool = true): tuple[payload: EventPayload, exhausted: bool] =
  ## Get an event.
  ## **NOTE**: If `exhausted` is returned as `true`, `payload` will be a zero'd out struct and will have all its properties set to their default ones.
  ##
  ## **NOTE**: This operates on a FIFO basis.
  
  if dispatcher.queue.len < 1:
    debug "dispatcher: queue is empty"
    if not repoll:
      debug "dispatcher: repoll is disabled"
      return (payload: default(EventPayload), exhausted: true)
    else:
      debug "dispatcher: repoll is enabled"
      dispatcher.checkChannel()
      return dispatcher.poll(repoll = false)

  let oldest = dispatcher.queue.pop()

  return (oldest, false)
