import std/[os, logging, locks]
import ./[configuration]
import ./utils/[objects]
import ../bindings/[gbinder, glib2]

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
  
  BinderPresenceData = object
    loop*: ptr GMainLoop
    obj*: ptr GBinderLocalObject

  HWService* = object
    sm*: ptr GBinderServiceManager
    code*: uint32

    thread*: Thread[ptr HWService]
    stopping*: bool = false

    binder*: string
    loop*: ptr GMainLoop

proc addHardwareService*(hwService: var HWService) {.gcsafe.} =
  proc responseHandler(
    obj: ptr GBinderLocalObject,
    req: ptr GBinderRemoteRequest,
    code, flags: uint32,
    status: ptr int32,
    user_data: pointer,
  ): ptr GBinderLocalReply {.cdecl.} =
    debug "hardware: received transaction: code=" & $code & ", flags=" & $flags

    status[] = 0

    case HardwareTransaction(code)
    of HardwareTransaction.EnableNFC:
      debug "hardware: set NFC state"
    else:
      error "hardware: unhandled IHardware transaction: " & $HardwareTransaction(code)

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
    debug "hardware: binder presence callback has been run"
    let data = cast[ptr BinderPresenceData](data)
    let obj = data.obj
    let loop = data.loop
    if gbinder_servicemanager_is_present(sm):
      debug "hardware: adding service: " & ServiceName
      let status = gbinder_servicemanager_add_service_sync(
        sm,
        ServiceName.cstring,
        obj
      )

      debug "hardware: add service sync: " & $status
      g_main_loop_quit(loop)
    else:
      debug "hardware: service manager is not present, cannot add service"
  
  # binderPresence(serviceManager, nil)

  debug "hardware: adding presence handler"
  var ctx = g_main_context_new()
  g_main_context_push_thread_default(ctx)
  assert ctx != nil
  assert g_main_context_is_owner(ctx), "BUG: main context is not owned by this thread"

  hwService.loop = g_main_loop_new(ctx, true)
  var data = make(BinderPresenceData)
  data.loop = hwService.loop
  data.obj = resp

  binderPresence(serviceManager, cast[pointer](data))
  hwService.code = gbinder_servicemanager_add_presence_handler(serviceManager, binderPresence, cast[pointer](data))
  
  g_main_loop_run(hwService.loop)
  debug "hardware: binder presence has run successfully; destroying service manager and removing handler"
  gbinder_servicemanager_remove_handler(serviceManager, hwService.code)
  gbinder_servicemanager_ref(serviceManager)
  hwService.sm = serviceManager

proc stopHardwareService*(svc: var HWService) =
  debug "hardware: stopping service"
  gbinder_servicemanager_remove_handler(svc.sm, svc.code)
  gbinder_servicemanager_unref(svc.sm)
