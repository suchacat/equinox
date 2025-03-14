import std/[logging, strutils]
import pkg/nimsimd/runtimecheck

proc getArchStr*(): string =
  when defined(amd64):
    return "x86_64"

  when defined(i686):
    return "i686"

  when defined(arm64):
    return "aarch64"

  when defined(arm32):
    return "armv8l"

proc getHost*(): string =
  when defined(amd64):
    return "x86_64"

  when defined(i686):
    return "x86"

  when defined(arm64):
    return "arm64"

  when defined(arm32):
    return "arm"

  raise newException(Defect, "Attempt to run Equinox on unsupported architecture.")

proc maybeRemap*(target: string): string =
  if target.contains("x86"):
    if not checkInstructionSets({SSE3}):
      raise newException(
        Defect,
        "Attempt to run Equinox on CPU without SSE3 support. Your CPU must support SSE3 to run Roblox!",
      )

    if not checkInstructionSets({SSE42}):
      warn "container/cpu: CPU does not support SSE 4.2, downgrading to i686"
      return "x86"

  target
