import std/[os, options, logging, tables]
import pkg/[jsony]
import ./[fflags, sugar]
import ../[argparser]

type
  ConfigData* = object
    free_robucks*: bool = false
    fflags*: FFlagList

const
  DefaultConfig* = """
{
	"free_robucks": true,
	"fflags": {
		"DFFlagDisableDPIScale": true,
		"DFIntTaskSchedulerTargetFps": 145,
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

  discard existsOrCreateDir("/home" / &input.flag("user") / ".config" / "equinox")

  let path =
    if not *input.flag("config"):
      "/home" / &input.flag("user") / ".config" / "equinox" / "config.json"
    else:
      &input.flag("config")

  debug "equinox: loading config from: " & path
  
  if not fileExists(path):
    debug "equinox: config does not exist, overriding with default config"
    writeFile(path, DefaultConfig)

  let conf = readFile(path)
    .fromJson(ConfigData)

  configCache = some(conf)
  conf
