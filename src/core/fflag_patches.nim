## fflag based patches that are automatically applied
import std/[json, tables, logging]
import ../container/[fflags]

func `[]=`[T: not JsonNode](list: var FFlagList, k: string, v: T) {.inline.} =
  list[k] = %*v

proc applyFFlagPatches*(list: var FFlagList) =
  debug "equinox: applying recommended fflag patches"

  # Misc
  list["DFFlagAndroidDebugHeapTelemetry"] = false
  list["DFFlagAndroidOomScoreTelemetry"] = false
  list["DFFlagHttpReportWhenAppSuspended"] = false
  list["DFFlagNumOpenFilesAndroid"] = false
  list["DFFlagPerformanceControlAddMemoryPercentageTelemetry"] = false
  list["DFFlagReportAppSuspended"] = false
  list["DFFlagReportDeviceNameInCrashes"] = false
    # We don't want Waydroid to show up in crash logs
  list["EnableAppsFlyerFacebookTracking"] = false
  list["FFlagLuaEnableLandingPageTTIMeasurements"] = false
  list["FFlagLuaIdentityGetPhoneNumber"] = false
  list["FFlagSendLowMemoryTelemetry"] = false
  list["FFlagEnableFlickerFixIOS"] = false
  list["FFlagSendMobileAdvertisingIdEnabled"] = false
  list["FFlagSendMobileAdvertisingIdEnabled2"] = false
  list["FFlagSendMobileAdvertisingIdEnabledAndroid2"] = false

  # On-screen Keyboard (try to disable it)
  list["AndroidAnimateSoftwareKeyboardOpenClose"] = false
  list["AndroidShiftViewportDownOnKeyboardClose"] = false
  list["FFlagEnableKeyboardVisibilityCheckOnPasswordFocus"] = false

  # Disable ads
  list["DFFlagEnableRewardedAdsLog"] = false
  list["DFFlagEnableRewardedAdsSessionTrackingFields"] = false
