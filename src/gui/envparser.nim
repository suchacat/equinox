import std/[os, options]
import ../[argparser]

type XdgEnv* = object
  runtimeDir*: string
  waylandDisplay*: string
  user*: string
  equinoxPath*: string

const AppImageRoot* {.strdefine.} = ""

proc getXdgEnv*(input: Input): XdgEnv =
  let equinoxPath =
    if (let flag = input.flag("appimage-build-root"); flag.isSome):
      let path = flag.get() / "usr" / "bin" / "equinox"
      assert fileExists(path),
        "PACKAGING BUG: EQUINOX WAS NOT BUNDLED WITH THE APPIMAGE!"

      path
    elif defined(packagedInstall):
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
