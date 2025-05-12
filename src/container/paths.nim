import std/[os]
import pkg/shakar
import ../argparser

{.push inline.}
func getWorkPath*(): string =
  "/var/lib/equinox"

func getRootfsPath*(): string =
  getWorkPath() / "rootfs"

func getApkStorePath*(): string =
  getWorkPath() / "apk"

func getApkStorePathForVersion*(ver: string): string =
  getWorkPath() / "apk" / ver

func getEquinoxLocalPath*(user: string): string =
  "/home" / user / ".local" / "share" / "equinox"

func getEquinoxDataPath*(user: string): string =
  getEquinoxLocalPath(user) / "data"

func getAppDataPath*(user: string, app: string): string =
  getEquinoxDataPath(user) / app

func getLxcPath*(): string =
  getWorkPath() / "lxc"

func getEquinoxLxcConfigPath*(): string =
  getLxcPath() / "equinox"

func getContainerXdgRuntimeDir*(): string =
  "/run/xdg"

func getContainerPulseRuntimePath*(): string =
  getContainerXdgRuntimeDir() / "pulse"

func getXdgRuntimeDir*(input: Input): string =
  &input.flag("xdg-runtime-dir")

func getWaylandDisplay*(input: Input): string =
  &input.flag("wayland-display")

func getImagesPath*(): string =
  getWorkPath() / "images"

func getHostPermsPath*(): string =
  getWorkPath() / "host-permissions"

func getOverlayPath*(): string =
  getWorkPath() / "overlay"

func getOverlayRWPath*(): string =
  getWorkPath() / "overlay_rw"

{.pop.}
