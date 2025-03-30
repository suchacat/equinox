type
  Event* {.pure.} = enum
    GameJoin

  EventPayload* = object
    case kind*: Event
    of Event.GameJoin:
      id*: string

  EventDispatcher* = object
    channel*: Channel[EventPayload] ## The main channel via which different threads feed the dispatcher. DESIGN NOTE: This is a one-way channel. DON'T SEND ANYTHING FROM HERE!
    queue*: seq[EventPayload]

    running*: bool = false
