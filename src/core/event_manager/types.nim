import std/json

type
  Event* {.pure.} = enum
    GameJoin
    GameLeave
    BloxstrapRPC

  EventPayload* = object
    case kind*: Event
    of Event.GameJoin:
      id*: string
    of Event.BloxstrapRPC:
      payload*: JsonNode
    of Event.GameLeave: discard

  EventDispatcher* = object
    queue*: seq[EventPayload]
    running*: bool = false
