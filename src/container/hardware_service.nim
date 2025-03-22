import std/[logging, locks]
import ./[hardware, configuration]

proc startHardwareService*: ptr HWService =
  debug "hardware_service: starting"
  var svc = cast[ptr HWService](alloc(sizeof(HWService)))
  svc.binder = config.binder
  initLock(svc.stateLock)

  proc serviceThread(svc: ptr HWService) {.gcsafe.} =
    echo "the service thread has fallen, billions must die"
    assert(svc != nil)
    while not svc.stopping:
      addHardwareService(svc[])
  
  debug "hardware_service: starting service thread"
  createThread(svc.thread, serviceThread, (svc))
  svc.stateLock.release() # release the lock so the thread isn't dependent on the main thread (which will be hung up)

  svc

proc deinitHardwareService*(svc: ptr HWService) =
  info "hardware_service: deinitializing service"
  svc.stopping = true

  joinThread(svc.thread)
  stopHardwareService(svc[])
  deinitLock(svc.stateLock)
