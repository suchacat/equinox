import std/[os, options, logging, strutils, json, tables]
import pkg/[jsony, shakar]
import ./[fflags]
import ../[argparser]

type
  RenderingBackend* {.pure.} = enum
    OpenGL
    Vulkan

  ConfigData* = object
    free_robucks*: bool = false
    allocator*: string = "minigbm_gbm_mesa"
    renderer*: string = "vulkan"
    max_fps*: Option[uint16] = none(uint16)
    discord_rpc*: bool = true
    fflags*: FFlagList

func toRenderingBackend*(
    str: string
): RenderingBackend {.raises: [ValueError], inline.} =
  case str.toLowerAscii()
  of "opengl", "ogl", "gl":
    RenderingBackend.OpenGL
  of "vulkan", "vk":
    RenderingBackend.Vulkan
  else:
    raise newException(ValueError, "Invalid rendering backend: " & str)

const DefaultConfig* =
  """
{
        "allocator": "minigbm_gbm_mesa",
        "renderer": "vulkan",
        "discord_rpc": true,
	"fflags": {
	  "DFFlagDisableDPIScale": true,
	  "DFIntTaskSchedulerTargetFps": 60,
	  "FFlagAdServiceEnabled": false,
	  "FFlagDebugDisableTelemetryEphemeralCounter": true,
	  "FFlagDebugDisableTelemetryEphemeralStat": true,
	  "FFlagDebugDisableTelemetryEventIngest": true,
	  "FFlagDebugDisableTelemetryPoint": true,
	  "FFlagDebugDisableTelemetryV2Counter": true,
	  "FFlagDebugDisableTelemetryV2Event": true,
	  "FFlagDebugDisableTelemetryV2Stat": true,
	  "FFlagFutureIsBrightPhase3Vulkan": true,
	  "FFlagGameBasicSettingsFramerateCap5": true,
	  "FFlagSendMeshTTMQTelemetry": false,
	  "FFlagTextureDeduplicationByHash4": false,
	  "FFlagUserHandleChatHotKeyWithContextActionService": true,
	  "FLogFMOD": 0
	}
}
  """

var configCache: Option[ConfigData]

proc save*(data: ConfigData) =
  assert(not isAdmin(), "GUARD: Do NOT call ConfigData::save() from a root-level process! It'll make the user pull their hair out!")
  let dir = getHomeDir() / ".config" / "equinox"
  discard existsOrCreateDir(dir)

  writeFile(
    dir / "config.json",
    pretty(%* data)
  )

proc loadAppConfig*(user: string): ConfigData =
  if *configCache:
    debug "equinox: using cached config"
    return &configCache

  let path = "/home" / user / ".config" / "equinox" / "config.json"

  debug "equinox: loading config from: " & path

  let conf =
    if not fileExists(path):
      debug "equinox: config does not exist, overriding with default config"
      DefaultConfig.fromJson(ConfigData)
    else:
      readFile(path).fromJson(ConfigData)

  configCache = some(conf)
  conf

proc loadAppConfig*(input: Input): ConfigData =
  loadAppConfig(&input.flag("user"))
