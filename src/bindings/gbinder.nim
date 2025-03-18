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

  GBinderFds* = object
    version* {.align: 4.}: uint32
    num_fds* {.align: 4.}: uint32
    num_ints* {.align: 4.}: uint32

{.pop.}

type
  GBinderHidlHandleData {.union.} = object
    value*: uint64
    fds*: ptr UncheckedArray[GBinderFds]

  GBinderHidlMemoryData {.union.} = object
    value*: uint64
    fds*: ptr UncheckedArray[GBinderFds]

  GBinderHidlStringData {.union.} = object
    value*: uint64
    str*: cstring

{.push importc.}

type
  GBinderHidlString* = object
    data*: GBinderHidlStringData
    len*: uint32
    owns_buffer*: uint8
    pad*: array[3, uint8]

  GBinderHidlHandle* = object
    data*: GBinderHidlHandleData
    owns_handle*: uint8
    pad*: array[7, uint8]

  GBinderHidlMemory* = object
    data*: GBinderHidlMemoryData
    owns_buffer*: uint8
    pad*: array[7, uint8]
    size*: uint64
    name*: GBinderHidlString

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

  GBinderLocalTransactFunc* = proc(
    obj: ptr GBinderLocalObject,
    req: ptr GBinderRemoteRequest,
    code, flags: uint,
    status: ptr int32,
    user_data: pointer,
  ): ptr GBinderLocalReply

  GBinderServiceManagerListFunc* = proc(
    sm: ptr GBinderServiceManager,
    services: ptr UncheckedArray[cstring],
    user_data: pointer,
  ): bool

  GBinderServiceManagerGetServiceFunc* = proc(
    sm: ptr GBinderServiceManager,
    obj: ptr GBinderRemoteObject,
    status: int32,
    user_data: pointer,
  )

  GBinderServiceManagerAddServiceFunc* =
    proc(sm: ptr GBinderServiceManager, status: int32, user_data: pointer)

  GBinderServiceManagerRegistrationFunc* =
    proc(sm: ptr GBinderServiceManager, name: cstring, user_data: pointer)

  GBinderServiceManagerFunc* = proc(sm: ptr GBinderServiceManager, userData: pointer)

{.push importc.}

var
  GBINDER_FIRST_CALL_TRANSACTION*: cint
  GBINDER_DEFAULT_BINDER*: cstring
  GBINDER_DEFAULT_HWBINDER*: cstring

proc gbinder_servicemanager_new*(dev: cstring): ptr GBinderServiceManager
proc gbinder_servicemanager_new2*(
  dev: cstring, sm_protocol: cstring, rpc_protocol: cstring
): ptr GBinderServiceManager

proc gbinder_defaultservicemanager_new*(dev: cstring): ptr GBinderServiceManager
proc gbinder_hwservicemanager_new*(dev: cstring): ptr GBinderServiceManager
proc gbinder_servicemanager_wait*(
  sm: ptr GBinderServiceManager, maxWaitMs: float32
): bool

proc gbinder_servicemanager_get_service_sync*(
  sm: ptr GBinderServiceManager, name: cstring, status: ptr int32
): ptr GBinderRemoteObject

proc gbinder_servicemanager_is_present*(sm: ptr GBinderServiceManager): bool
proc gbinder_servicemanager_list*(
  sm: ptr GBinderServiceManager, fn: GBinderServiceManagerListFunc, userData: pointer
): uint32

proc gbinder_servicemanager_list_sync*(
  sm: ptr GBinderServiceManager
): ptr UncheckedArray[cstring]

proc gbinder_servicemanager_get_service*(
  sm: ptr GBinderServiceManager,
  name: cstring,
  fn: GBinderServiceManagerGetServiceFunc,
  userData: pointer,
): uint32

proc gbinder_servicemanager_add_service*(
  sm: ptr GBinderServiceManager,
  name: cstring,
  obj: ptr GBinderLocalObject,
  fn: GBinderServiceManagerAddServiceFunc,
  user_data: pointer,
): uint32

proc gbinder_add_servicemanager_add_service_sync*(
  sm: ptr GBinderServiceManager, name: cstring, obj: ptr GBinderLocalObject
): int32

proc gbinder_servicemanager_cancel*(sm: ptr GBinderServiceManager, id: uint32)
proc gbinder_servicemanager_add_presence_handler*(
  sm: ptr GBinderServiceManager, fn: GBinderServiceManagerFunc, userData: pointer
): uint32

proc gbinder_servicemanager_add_registration_handler*(
  sm: ptr GBinderServiceManager,
  name: cstring,
  fn: GBinderServiceManagerRegistrationFunc,
  userData: pointer,
): uint32

proc gbinder_servicemanager_remove_handler*(sm: ptr GBinderServiceManager, id: uint32)
proc gbinder_servicemanager_remove_handlers*(
  sm: ptr GBinderServiceManager, ids: ptr UncheckedArray[uint32], count: uint
)

proc gbinder_client_new*(
  obj: ptr GBinderRemoteObject, iface: cstring
): ptr GBinderClient

proc gbinder_client_new_request*(client: ptr GBinderClient): ptr GBinderLocalRequest
proc gbinder_client_new_request2*(
  client: ptr GBinderClient, code: uint32
): ptr GBinderLocalRequest

proc gbinder_local_request_append_string16*(
  request: ptr GBinderLocalRequest, utf8: cstring
): ptr GBinderLocalRequest

proc gbinder_local_request_append_string8*(
  request: ptr GBinderLocalRequest, str: cstring
)

proc gbinder_local_request_append_bool*(
  request: ptr GBinderLocalRequest, value: bool
): ptr GBinderLocalRequest

proc gbinder_client_transact_sync_reply*(
  client: ptr GBinderClient,
  code: uint32,
  req: ptr GBinderLocalRequest,
  status: ptr int32,
): ptr GBinderRemoteReply

proc gbinder_client_cancel*(client: ptr GBinderClient, id: uint32)
proc gbinder_client_rpc_header*(client: ptr GBinderClient, code: uint32): cstring
proc gbinder_client_interface*(client: ptr GBinderClient): cstring
proc gbinder_client_interface2*(client: ptr GBinderClient, code: uint32): cstring
proc gbinder_client_ref*(client: ptr GBinderClient): ptr GBinderClient
proc gbinder_client_unref*(client: ptr GBinderClient)
proc gbinder_reader_at_end*(reader: ptr GBinderReader): bool
proc gbinder_reader_read_byte*(reader: ptr GBinderReader, value: ptr uint8): bool
proc gbinder_reader_read_int8*(reader: ptr GBinderReader, value: ptr int8): bool
proc gbinder_reader_read_uint8*(reader: ptr GBinderReader, value: ptr uint8): bool
proc gbinder_reader_read_int16*(reader: ptr GBinderReader, value: ptr int16): bool
proc gbinder_reader_read_uint16*(reader: ptr GBinderReader, value: ptr uint16): bool
proc gbinder_reader_read_int32*(reader: ptr GBinderReader, value: ptr int32): bool
proc gbinder_reader_read_uint32*(reader: ptr GBinderReader, value: ptr uint32): bool
proc gbinder_reader_read_int64*(reader: ptr GBinderReader, value: ptr int64): bool
proc gbinder_reader_read_uint64*(reader: ptr GBinderReader, value: ptr uint64): bool
proc gbinder_reader_read_float*(reader: ptr GBinderReader, value: ptr float32): bool
proc gbinder_reader_read_double*(reader: ptr GBinderReader, value: ptr float): bool
proc gbinder_reader_read_fd*(reader: ptr GBinderReader): int32
proc gbinder_reader_read_dup_fd*(reader: ptr GBinderReader): int32
proc gbinder_reader_read_nullable_object*(
  reader: ptr GBinderReader, obj: ptr ptr GBinderRemoteObject
): bool

proc gbinder_reader_read_object*(reader: ptr GBinderReader): ptr GBinderRemoteObject
proc gbinder_reader_read_buffer*(reader: ptr GBinderReader): ptr GBinderBuffer
proc gbinder_reader_read_parcelable*(
  reader: ptr GBinderReader, size: ptr uint64
): pointer

proc gbinder_reader_skip_buffer*(reader: ptr GBinderReader): bool
proc gbinder_reader_read_string8*(reader: ptr GBinderReader): cstring
proc gbinder_reader_read_string16*(reader: ptr GBinderReader): cstring
proc gbinder_reader_read_nullable_string*(
  reader: ptr GBinderReader, output: ptr cstring, outLen: ptr uint64
): bool

proc gbinder_remote_reply_unref*(reply: ptr GBinderRemoteReply)
proc gbinder_remote_reply_init_reader*(
  reply: ptr GBinderRemoteReply, reader: ptr GBinderReader
)

proc gbinder_remote_reply_copy_to_local*(
  reply: ptr GbinderRemoteReply
): ptr GBinderRemoteReply

proc gbinder_remote_object_unref*(obj: ptr GBinderRemoteObject)
proc gbinder_remote_object_ipc*(obj: ptr GBinderRemoteObject): ptr GBinderIpc
proc gbinder_remote_object_is_dead*(obj: ptr GBinderRemoteObject): bool
proc gbinder_bridge_new*(
  name: cstring,
  ifaces: ptr UncheckedArray[cstring],
  src, dest: ptr GBinderServiceManager,
): ptr GBinderBridge

proc gbinder_bridge_new2*(
  src_name, dest_name: cstring,
  ifaces: ptr UncheckedArray[cstring],
  src, dest: ptr GBinderServiceManager,
): ptr GBinderBridge

proc gbinder_bridge_free*(bridge: ptr GBinderBridge)
proc gbinder_local_object_new*(
  ipc: ptr GBinderIpc,
  ifaces: ptr UncheckedArray[cstring],
  handler: GBinderLocalTransactFunc,
  userData: pointer,
): ptr GBinderLocalObject

proc gbinder_local_object_ref*(obj: ptr GBinderLocalObject): ptr GBinderLocalObject
proc gbinder_local_object_unref*(obj: ptr GBinderLocalObject)
proc gbinder_local_object_drop*(obj: ptr GBinderLocalObject)
proc gbinder_local_object_new_reply*(obj: ptr GBinderLocalObject): ptr GBinderLocalReply
proc gbinder_local_object_set_stability*(
  self: ptr GBinderLocalObject, stability: GBinderStabilityLevel
)

{.pop.}

{.pop.}

func GBINDER_FOURCC*(c1, c2, c3, c4: uint64): uint64 =
  (c1 shl 24) or (c2 shl 16) or (c3 shl 8) or c4
