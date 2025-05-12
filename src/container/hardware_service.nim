import std/[logging, locks]
import pkg/[colored_logger]
import ./[hardware, paths]
import ./utils/objects

proc startHardwareService*(): ptr HWService =
  debug "hardware_service: starting"
  var svc = make(HWService)
  svc.binder = config.binder

  proc serviceThread(svc: ptr HWService) {.gcsafe.} =
    setLogFilter(lvlAll)
    addHandler(newColoredLogger())

    #while not svc.stopping:
    addHardwareService(svc[])

  debug "hardware_service: starting service thread"
  createThread(svc.thread, serviceThread, (svc))
  debug "hardware_service: started service thread"

  svc

proc deinitHardwareService*(svc: ptr HWService) =
  info "hardware_service: deinitializing service"
  svc.stopping = true

  # joinThread(svc.thread)
  stopHardwareService(svc[])
  dealloc(svc)
