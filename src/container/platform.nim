import std/[os, logging, strutils, times]
import ./[configuration, drivers]
import ../bindings/[gbinder]

const
  InterfaceName = "lineageos.waydroid.IPlatform"
  ServiceName = "waydroidplatform"

type
  Transaction* {.pure, size: sizeof(uint32).} = enum
    GetProp = 1
    SetProp = 2
    GetAppsInfo = 3
    GetAppInfo = 4
    InstallApp = 5
    RemoveApp = 6
    LaunchApp = 7
    GetAppName = 8
    SettingsPutString = 9
    SettingsGetString = 10
    SettingsPutInt = 11
    SettingsGetInt = 12
    LaunchIntent = 13

  IPlatform* = object
    client*: pointer

proc installApp*(iface: var IPlatform, path: string) =
  debug "platform: installing APK from: " & path

  debug "platform: copying APK to " & config.equinoxData / "install.apk"
  copyFile(path, config.equinoxData / "install.apk")

  var request = gbinder_client_new_request(cast[ptr GBinderClient](iface.client))
  discard gbinder_local_request_append_string16(request, cstring(config.equinoxData / "install.apk"))
  
  var status: ptr int32
  let reply = gbinder_client_transact_sync_reply(cast[ptr GBinderClient](iface.client), uint32(Transaction.InstallApp), request, status)
  
  if status != nil:
    error "platform: sending reply failed"
  else:
    discard

proc waitForManager*(mgr: ptr GBinderServiceManager): bool =
  for _ in 0 .. 4096:
    if gbinder_servicemanager_is_present(mgr):
      debug "platform: service manager is present!"
      return true

    sleep(10)

  false

proc getIPlatformService*: IPlatform =
  let driverList = setupBinderNodes()

  debug "init: binder = " & driverList.binder
  debug "init: vndbinder = " & driverList.vndbinder
  debug "init: hwbinder = " & driverList.hwbinder
  config.binder = driverList.binder
  config.vndbinder = driverList.vndbinder
  config.hwbinder = driverList.hwbinder

  var serviceMgr = gbinder_servicemanager_new2(cstring("/dev" / config.binder), "aidl3".cstring, "aidl3".cstring)

  if not gbinder_servicemanager_is_present(serviceMgr):
    info "platform: waiting for binder service manager"
    
    if not serviceMgr.waitForManager:
      error "platform: binder service manager never initialized itself"
  
  var status: int32
  var remote = gbinder_servicemanager_get_service_sync(
    serviceMgr, 
    ServiceName.cstring, status.addr)
  
  var tries = 1000
  while remote == nil:
    if tries < 0:
      warn "platform: failed to get service: " & ServiceName & " in 1000 tries"
      raise newException(Defect, "Cannot get service: " & ServiceName)
    else:
      warn "platform: failed to get service: " & ServiceName & "; retrying"
      sleep(1)
      remote = gbinder_servicemanager_get_service_sync(serviceMgr, ServiceName.cstring, status.addr)
    dec tries

  IPlatform(
    client: cast[pointer](gbinder_client_new(remote, InterfaceName))
  )
