## Patch some read-only system properties right before Roblox starts.
import std/[logging]
import ../container/platform

proc patchProperties*() =
  debug "equinox: patching properties"
  var platform = getIPlatformService()

  proc pt(key, val: string) =
    platform.setProperty(key, val)

  pt "ro.product.model", "Chromebook x86_64"
  pt "ro.product.brand", "Google"
  #[ props &= (key: "ro.product.platform", value: "chromebook")
  props &= (key: "ro.build.product", value: "chromebook_x86_64")
  props &= (key: "ro.lineage.device", value: "chromebook_x86_64")
  props &= (key: "ro.product.device", value: "chromebook_x86_64")
  props &= (key: "ro.product.name", value: "chromeos_chromebook_x86_64")
  props &= (key: "ro.product.odm.brand", value: "google")
  props &= (key: "ro.product.odm.device", value: "chromebook_x86_64")
  props &= (key: "ro.product.product.brand", value: "google")
  props &= (key: "ro.product.product.device", value: "chromebook_x86_64")
  props &= (key: "ro.product.product.name", value: "chromeos_chromebook_x86_64")
  props &= (key: "ro.product.system.brand", value: "google")
  props &= (key: "ro.product.system.device", value: "waydroid_x86_64")
  props &= (key: "ro.product.system.name", value: "chromeos_chromebook_x86_64")
  props &= (key: "ro.product.system_ext.brand", value: "google")
  props &= (key: "ro.product.system_ext.device", value: "chromebook_x86_64")
  props &= (key: "ro.product.system_ext.name", value: "chromeos_chromebook_x86_64")
  props &= (key: "ro.product.vendor.brand", value: "google")
  props &= (key: "ro.product.vendor.device", value: "chromebook_x86_64")
  props &= (key: "ro.product.vendor.name", value: "chromeos_chromebook_x86_64")
  props &= (key: "ro.build.characteristics", value: "pc,keyboard") ]#
