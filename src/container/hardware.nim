import std/[os, logging, locks]
import ./[configuration]
import ../bindings/[gbinder]

const
  Interface = "lineageos.waydroid.IHardware"
  ServiceName = "waydroidhardware"

type
  HardwareSvcAttachFail* = object of Defect

  HardwareTransaction* {.pure, size: sizeof(uint32).} = enum
    EnableNFC = 1
    EnableBluetooth = 2
    Suspend = 3
    Reboot = 4
    Upgrade = 5
    Upgrade2 = 6

  HWService* = object
    sm*: ptr GBinderServiceManager
    code*: uint32

    thread*: Thread[ptr HWService]
    stopping*: bool = false
    stateLock*: Lock

    binder*: string

proc addHardwareService*(hwService: var HWService) {.gcsafe.} =
  proc responseHandler(
    obj: ptr GBinderLocalObject,
    req: ptr GBinderRemoteRequest,
    code, flags: uint32,
    status: ptr int32,
    user_data: pointer,
  ): ptr GBinderLocalReply {.cdecl.} =
    debug "hardware: received transaction: code=" & $code & ", flags=" & $flags
    warn "hardware: this is stubbed! fixme plox"

    status[] = 0

    return nil
  
  var serviceManager = gbinder_servicemanager_new2(cstring("/dev" / "binder"), "aidl3".cstring, "aidl3".cstring)

  debug "hardware: binding to interface: " & Interface
  var resp = gbinder_servicemanager_new_local_object(
    serviceManager,
    Interface.cstring,
    responseHandler,
    nil
  )

  proc binderPresence(sm: ptr GBinderServiceManager, data: pointer) {.cdecl.} =
    if not gbinder_servicemanager_is_present(sm):
      warn "hardware: failed to attach hardware service"
      return

    debug "hardware: adding service: " & ServiceName
    let status = gbinder_servicemanager_add_service_sync(
      sm,
      ServiceName.cstring,
      cast[ptr GBinderLocalObject](data)
    )

    debug "hardware: add service sync: " & $status
  
  binderPresence(serviceManager, nil)

  debug "hardware: adding presence handler"
  hwService.code = gbinder_servicemanager_add_presence_handler(serviceManager, binderPresence, cast[pointer](resp))

  hwService.sm = serviceManager
  gbinder_servicemanager_ref(hwService.sm)

proc stopHardwareService*(svc: var HWService) =
  debug "hardware: stopping service"
  gbinder_servicemanager_remove_handler(svc.sm, svc.code)
  gbinder_servicemanager_unref(svc.sm)
