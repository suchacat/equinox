## kawaii sugoi desu desu gbinder bindings ^w^
import std/[strutils]

{.passC: gorge("pkg-config --cflags libgbinder").strip().}
{.passL: gorge("pkg-config --libs libgbinder").strip().}

{.push header: "<gbinder/gbinder.h>".}
{.push importc.}
type
  GBinderServiceManager* = object
  GBinderBridge* = object
  GBinderBuffer* = object
  GBinderClient* = object
  GBinderFmq* = object
  GBinderIpc* = object
  GBinderLocalObject* = object
  GBinderLocalReply* = object
  GBinderLocalRequest* = object
  GBinderReader* = object
  GBinderRemoteObject* = object
  GBinderRemoteReply* = object
  GBinderRemoteRequest* = object
  GBinderServiceName* = object
  GBinderWriter* = object
  GBinderParent* = object
{.pop.}

type
  GBinderStatus* {.pure, importc: "GBINDER_STATUS".} = enum
    Ok = 0
    Failed
    DeadObject

  GBinderStabilityLevel* {.pure, importc: "GBINDER_STABILITY_LEVEL".} = enum
    Undeclared = 0
    Vendor = 0x03
    System = 0x0c
    Vintf = 0x3f

{.push importc.}

var 
  GBINDER_FIRST_CALL_TRANSACTION*: cint
  GBINDER_DEFAULT_BINDER*: cstring
  GBINDER_DEFAULT_HWBINDER*: cstring

proc gbinder_servicemanager_new*(dev: cstring): ptr GBinderServiceManager
proc gbinder_servicemanager_new2*(dev: cstring, sm_protocol: cstring, rpc_protocol: cstring): ptr GBinderServiceManager
proc gbinder_defaultservice_new*(
  dev: cstring
): ptr GBinderServiceManager
proc gbinder_hwservicemanager_new*(
  dev: cstring
): ptr GBinderServiceManager
proc gbinder_servicemanager_wait*(
  sm: ptr GBinderServiceManager,
  maxWaitMs: float32
): bool
proc gbinder_client_new*(obj: ptr GBinderRemoteObject, iface: cstring): ptr GBinderClient
proc gbinder_client_new_request*(client: ptr GBinderClient): ptr GBinderLocalRequest
proc gbinder_client_new_request2*(client: ptr GBinderClient, code: uint32): ptr GBinderLocalRequest
proc gbinder_local_request_append_string16*(request: ptr GBinderLocalRequest, utf8: cstring): ptr GBinderLocalRequest
proc gbinder_local_request_append_string8*(request: ptr GBinderLocalRequest, str: cstring)
proc gbinder_local_request_append_bool*(request: ptr GBinderLocalRequest, value: bool): ptr GBinderLocalRequest
proc gbinder_client_transact_sync_reply*(
  client: ptr GBinderClient,
  code: uint32,
  req: ptr GBinderLocalRequest,
  status: ptr int32
): ptr GBinderRemoteReply

proc gbinder_servicemanager_get_service_sync*(sm: ptr GBinderServiceManager, name: cstring, status: ptr int32): ptr GBinderRemoteObject

proc gbinder_servicemanager_is_present*(sm: ptr GBinderServiceManager): bool

{.pop.}

{.pop.}

func GBINDER_FOURCC*(c1, c2, c3, c4: uint64): uint64 =
  (c1 shl 24) or (c2 shl 16) or (c3 shl 8) or c4
