type
  Event* {.pure.} = enum
    GameJoin
    GameLeave

  EventPayload* = object
    case kind*: Event
    of Event.GameJoin:
      id*: string

  EventDispatcher* = object
    queue*: seq[EventPayload]
    running*: bool = false
