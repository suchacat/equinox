#thefunny (also mostly ai generated code)

import std/[os, logging]

type
  XdgEnv* = object
    runtimeDir*: string
    waylandDisplay*: string
    user*: string

proc getXdgEnv*(): XdgEnv =
  result = XdgEnv(runtimeDir: "", waylandDisplay: "", user: "")

  try:
    result.runtimeDir = getEnv("XDG_RUNTIME_DIR")
  except KeyError:
    discard

  try:
    result.waylandDisplay = getEnv("WAYLAND_DISPLAY")
  except KeyError:
    discard

  try:
    result.user = getEnv("USER")
  except KeyError:
    discard

  #Added to check if XDG_RUNTIME_DIR contains non-ASCII characters, and if it does, default to /tmp
  #[if result.runtimeDir.len > 0 and not result.runtimeDir.allCharsInSet("Charset" !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"):
      result.runtimeDir = "/tmp" ]#
