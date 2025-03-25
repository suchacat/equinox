import std/[os, options, logging, strutils, tables]
import pkg/[jsony]
import ./[fflags, sugar]
import ../[argparser]

type
  RenderingBackend* {.pure.} = enum
    OpenGL
    Vulkan
    CPU

  ConfigData* = object
    free_robucks*: bool = false
    allocator*: string = "minigbm_gbm_mesa"
    renderer*: string = "vulkan"
    max_fps*: Option[uint16] = none(uint16)
    fflags*: FFlagList

func toRenderingBackend*(str: string): RenderingBackend {.raises: [ValueError], inline.} =
  case str.toLowerAscii()
  of "opengl", "ogl", "gl": RenderingBackend.OpenGL
  of "vulkan", "vk": RenderingBackend.Vulkan
  of "cpu", "nthorsefly": RenderingBackend.CPU
  else:
    raise newException(ValueError, "Invalid rendering backend: " & str)

const DefaultConfig* =
  """
{
        "allocator": "minigbm_gbm_mesa",
        "renderer": "vulkan",
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

proc loadAppConfig*(input: Input): ConfigData =
  if *configCache:
    debug "equinox: using cached config"
    return &configCache

  # discard existsOrCreateDir("/home" / &input.flag("user") / ".config" / "equinox")

  let path =
    if not *input.flag("config"):
      "/home" / &input.flag("user") / ".config" / "equinox" / "config.json"
    else:
      &input.flag("config")

  debug "equinox: loading config from: " & path

  let conf =
    if not fileExists(path):
      debug "equinox: config does not exist, overriding with default config"
      DefaultConfig.fromJson(ConfigData)
    else:
      readFile(path).fromJson(ConfigData)

  configCache = some(conf)
  conf
