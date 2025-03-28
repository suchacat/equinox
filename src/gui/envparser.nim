import std/[os, logging]

type XdgEnv* = object
  runtimeDir*: string
  waylandDisplay*: string
  user*: string
  equinoxPath*: string

proc getXdgEnv*(): XdgEnv =
  let equinoxPath =
    when defined(packagedInstall):
      findExe("equinox")
    elif not defined(release):
      getCurrentDir() / "equinox"
    else:
      getHomeDir() / ".nimble" / "bin" / "equinox" # FIXME: stupid hack

  XdgEnv(
    runtimeDir: getEnv("XDG_RUNTIME_DIR"),
    waylandDisplay: getEnv("WAYLAND_DISPLAY"),
    user: getEnv("USER"),
    equinoxPath: equinoxPath,
  )
