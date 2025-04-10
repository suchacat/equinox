import std/[algorithm, os, logging, options, strutils, sequtils, tables]
import pkg/[glob]

const UnsupportedGPUDrivers* = [
  "nvidia" # TODO: novideo support........
]

type
  InvalidRenderDevice* = object of ValueError
  NoVulkanSupport* = object of ValueError

  DRINode* = object
    dev*: string
    gpu*: string

proc getKernelDriver*(device: string): string =
  readFile("/sys/class/drm/" & device & "/device/uevent").split("DRIVER=")[1].split(
    '\n'
  )[0]

proc getCardFromRenderNode*(device: string): string =
  debug "container/gpu: getCardFromRenderNode(" & device & ')'
  var matches: seq[string]

  for kind, node in walkDir("/sys/class/drm" / device / "device/drm"):
    if kind != pcDir:
      continue

    if node.contains("card"):
      matches &= node

  if matches.len < 1:
    error "container/gpu: invalid/unregistered rendering node: " & device
    raise newException(
      InvalidRenderDevice,
      "found 0 matches for the card that owns this node! (" & device & ')',
    )

  if matches.len > 1:
    warn "container/gpu: multiple DRM devices seem to own a single render node: " &
      device
    warn "container/gpu: this is weird; will it lead to a crash? :P"

  "/dev" / "dri" / matches[0].splitPath().tail

proc getDriNode*(): Option[DRINode] =
  when defined(equinoxTrayExperimentDedicatedNodes):
    let nodes = glob("/dev/dri/renderD*").walkGlob.toSeq.sortedByIt(
      (char) (((uint8) it[it.len - 1]) - ((uint8) '0'))
    )
  else:
    let nodes = glob("/dev/dri/renderD*").walkGlob.toSeq().reversed()
  
  for node in nodes: 
    let split = splitPath(node).tail
    let renderDev = split

    if getKernelDriver(renderDev) notin UnsupportedGPUDrivers:
      debug "container/gpu: found supported DRI node: " & renderDev
      return some(DRINode(dev: node, gpu: getCardFromRenderNode(renderDev)))
    else:
      warn "container/gpu: found unsupported DRI node: " & renderDev
      warn "container/gpu: ignoring it."

proc getVulkanDriver*(device: string): string =
  if existsEnv("EQUINOX_VK_DRIVER"):
    warn "container/gpu: using overwritten EQUINOX_VK_DRIVER: " &
      getEnv("EQUINOX_VK_DRIVER").repr
    return getEnv("EQUINOX_VK_DRIVER")

  let table = {
    "i915": "intel",
    "amdgpu": "radeon",
    "radeon": "radeon",
    "panfrost": "panfrost",
    "msm": "freedreno",
    "msm_dpu": "freedreno",
    "vc4": "broadcom",
    "nouveau": "nouveau",
  }.toTable
  let kernelDriver = getKernelDriver(device)

  if kernelDriver notin table:
    error "container/gpu: Your GPU does not support Vulkan."
    error "container/gpu: If you believe that this is a mistake, open a support ticket in the Lucem Discord server."
    raise newException(
      NoVulkanSupport, "Device \"" & device & "\" does not support Vulkan!"
    )

  table[kernelDriver]
