import std/[os, logging]

type XdgEnv* = object
  runtimeDir*: string
  waylandDisplay*: string
  user*: string
  equinoxPath*: string

proc getXdgEnv*(): XdgEnv =
  let equinoxPath =
    when defined(release):
      findExe("equinox")
    else:
      getCurrentDir() / "equinox"

  XdgEnv(
    runtimeDir: getEnv("XDG_RUNTIME_DIR"),
    waylandDisplay: getEnv("WAYLAND_DISPLAY"),
    user: getEnv("USER"),
    equinoxPath: equinoxPath,
  )
