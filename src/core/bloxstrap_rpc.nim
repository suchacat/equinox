## BloxstrapRPC implementation
import std/[json]

type
  BloxstrapRPCCommand* = enum
    SetRichPresence = 0x0
    SetLaunchData

  BloxstrapRPCPayload* = object
    command*: BloxstrapRPCCommand
    data*: JsonNode
