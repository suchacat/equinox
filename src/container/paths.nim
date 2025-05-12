import std/[os]

{.push inline.}
func getWorkPath*(): string =
  "/var" / "lib" / "equinox"

func getRootfsPath*(): string =
  getWorkPath() / "rootfs"

{.pop.}
