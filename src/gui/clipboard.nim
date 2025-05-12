## Clipboard implementation
import std/[os, osproc, options, logging]
import pkg/shakar
# import pkg/simdutf/bindings

var cachedWlCopy: Option[string]
var cachedWlPaste: Option[string]

proc findWlPaste*(): string {.sideEffect.} =
  if *cachedWlPaste:
    return &cachedWlPaste

  let bin = findExe("wl-paste")
  if bin.len < 1:
    raise newException(OSError, "Cannot find `wl-paste`!")

  cachedWlPaste = some(bin)
  bin

proc findWlCopy*(): string {.sideEffect.} =
  if *cachedWlCopy:
    return &cachedWlCopy

  let bin = findExe("wl-copy")
  if bin.len < 1:
    raise newException(OSError, "Cannot find `wl-copy`!")

  cachedWlCopy = some(bin)
  bin

proc copyText*(str: string): bool {.discardable.} =
  debug "clipboard: copying text: " & str

  #[ if not validateUtf8(str.cstring, str.len.csize_t):
    error "clipboard: cannot copy text as UTF-8 validation has failed!"
    error "clipboard: silently failing."
    return false ]#

  execCmd(findWlCopy() & ' ' & str) == 0

proc pasteText*(): Option[string] =
  let text = execCmdEx(findWlPaste()).output

  #[ if not validateUtf8(text.cstring, text.len.csize_t):
    error "clipboard: cannot paste text as UTF-8 validation has failed!"
    error "clipboard: silently failing."
    return ]#

  if text.len > 0:
    return some(text)
