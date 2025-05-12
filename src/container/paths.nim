import std/[os]

{.push inline.}
func getWorkPath*(): string =
  "/var" / "lib" / "equinox"

func getRootfsPath*(): string =
  getWorkPath() / "rootfs"

func getApkStorePath*(): string =
  getWorkPath() / "apk"

func getApkStorePathForVersion*(ver: string): string =
  getWorkPath() / "apk" / ver

{.pop.}
