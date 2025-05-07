import std/[os, options, logging, strutils, sequtils, posix, tables, json]
import
  ../container/
    [
      lxc, configuration, drivers, platform, network, rootfs, app_config, fflags,
      settings,
    ]
import pkg/[discord_rpc, shakar]
import ../argparser
import ../container/utils/[exec, mount]
import ./event_manager/[types, dispatcher]
import ./[discord_rpc, fflag_patches, roblox_logs, processes]

proc showUI*(launch: bool = true) =
  var platform = getIPlatformService()
  if launch:
    platform.launchApp("com.roblox.client")

  platform.setProperty("waydroid.active_apps", "com.roblox.client")

proc startRobloxClient*(platform: var IPlatform) =
  while isEmptyOrWhitespace(&readOutput("pidof", "com.roblox.client")):
    # FIXME: please don't do this
    platform.launchApp("com.roblox.client")
    sleep(100)

  startLogWatcher()

proc processEvents*(dispatcher: var EventDispatcher, rpc: DiscordRPC) =
  let pid = pidof("com.roblox.client")
  if !pid:
    info "equinox: com.roblox.client has exited, setting dispatcher flag to false"
    dispatcher.running = false
    return

  let (event, exhausted) = dispatcher.poll()
  if exhausted:
    return

  case event.kind
  of Event.GameJoin:
    info "equinox: user joined game; id=" & event.id
    handleGameRPC(rpc, event.id)
  of Event.GameLeave:
    info "equinox: user left game."
    handleIdleRPC(rpc)
  of Event.BloxstrapRPC:
    info "equinox: received BloxstrapRPC payload"
    handleBloxstrapRPC(rpc, event.payload)
  of Event.RobloxClose:
    info "equinox: roblox has exited; flagging dispatcher state as exited"
    dispatcher.running = false

proc startAndroidRuntime*(input: Input, launchRoblox: bool = true) =
  info "equinox: starting android runtime"
  debug "equinox: starting prep for android runtime"

  destroyAllLogs()
  mountRootfs(input, config.imagesPath)
  probeBinderDriver()

  var settings = loadAppConfig(input)

  debug "equinox: applying config"

  if *settings.maxFps:
    settings.fflags["DFIntTaskSchedulerTargetFps"] = newJInt(int(&settings.maxFps))

  settings.fflags["FFlagUserFyosDetectionHorseFly"] = newJBool(true) # for shy :3

  applyFflagPatches(settings.fflags)
  setFflags(settings.fflags)
  generateSessionLxcConfig()

  var dispatcher = initEventDispatcher()
  dispatcher.running = true

  if getLxcStatus() == "RUNNING":
    stopLxcContainer()

  startLxcContainer(input)
  waitForContainerBoot()

  var platform = getIPlatformService()
  platform.setProperty("waydroid.active_apps", "com.roblox.client")

  settingsPut("system", "dim_screen", false) # Don't dim the screen.
  settingsPut("system", "screen_brightness", 100)
  settingsPut("system", "screen_brightness_float", 1)
  settingsPut("system", "volume_notification", 0)
  settingsPut("system", "volume_ring", 0)
  settingsPut("system", "volume_system", 0)
  settingsPut("system", "volume_alarm", 0)
  settingsPut("system", "ringtone_set", false)
  settingsPut("system", "notification_sound_set", false)
  settingsPut("system", "notification_light_pulse", false)
  settingsPut("system", "hide_rotation_lock_toggle_for_accessibility", true)
  settingsPut("system", "hearing_aid", false)
    # UD method (set it to true for the funnies)
  settingsPut("system", "theater_mode_on", true) # Make sure no Android garbage shows up
  settingsPut("secure", "screensaver_enabled", false)
  settingsPut("secure", "volume_hush_gesture", false)
  settingsPut("secure", "sysui_nav_bar", false)
  settingsPut("global", "policy_control", "immersive.status=*")

  if launchRoblox:
    startRobloxClient(platform)

    putEnv("XDG_RUNTIME_DIR", &input.flag("xdg-runtime-dir"))
      # Fixes a crash with Discord RPC as we don't have XDG_RUNTIME_DIR in the environment 
      # since we're running as root.
    var rpc = newDiscordRpc(RPCApplicationId)

    if settings.discordRpc:
      debug "equinox: RPC is enabled"
      try:
        let res = rpc.connect()
        debug "equinox: connected to Discord RPC."
        debug "equinox: CDN host = " & res.config.cdnHost & ", API endpoint = " &
          res.config.apiEndpoint & ", env = " & res.config.environment
        debug "equinox: logged in as " & res.user.username & " (" & $res.user.id & ")"
      except CatchableError as exc:
        debug "equinox: cannot connect to Discord RPC: " & exc.msg
        rpc = nil
    else:
      debug "equinox: RPC is disabled"
      rpc = nil

    rpc.handleIdleRPC()

    while dispatcher.running:
      sleep(100)
      processEvents(dispatcher, rpc)

    info "equinox: app deinit started"
    stopLogWatcher()
    stopNetworkService()
    stopLxcContainer()
    umountAll(config.rootfs)
    info "equinox: app cleanup completed gracefully"

type PlaceURI* = string

proc launchRobloxGame*(input: Input, id: PlaceURI | string) =
  info "equinox: sending VIEW intent to roblox client"

  if getLxcStatus() != "RUNNING":
    startAndroidRuntime(input, launchRoblox = false)
  else:
    showUI(launch = false)

  var platform = getIPlatformService()
  platform.launchIntent("android.intent.action.VIEW", "roblox://placeId=" & $id)
  platform.setProperty("waydroid.active_apps", "com.roblox.client")
