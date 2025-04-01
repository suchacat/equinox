import std/[logging]
import ./[types]

var chan* {.global.}: Channel[EventPayload]

proc initEventDispatcher*(): EventDispatcher =
  info "lifecycle: event dispatcher is being initialized"
  var dispatcher: EventDispatcher
  chan.open()

  dispatcher

proc checkChannel*(dispatcher: var EventDispatcher) =
  let attempt = chan.tryRecv()
  if attempt.dataAvailable:
    dispatcher.queue.add(attempt.msg)

proc poll*(
    dispatcher: var EventDispatcher, repoll: bool = true
): tuple[payload: EventPayload, exhausted: bool] =
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
