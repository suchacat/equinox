import std/[os, options, logging, strutils, tables, times, posix]
import pkg/[glob]
import utils/exec
import ../argparser
import ./[trayperion, lxc_config, sugar, cpu, gpu, configuration, drivers]

type BinaryNotFound* = object of Defect

var exeCache: Table[string, string]

proc findBin*(cmd: string): string =
  debug "lxc: finding LXC related binary: " & cmd

  if cmd in exeCache:
    debug "lxc: findBin hit the cache"
    return exeCache[cmd]
  else:
    debug "lxc: findBin missed the cache"
    let path = findExe(cmd)
    if path.len < 1:
      raise newException(BinaryNotFound, "Couldn't find binary: " & path)

    debug "lxc: " & cmd & " -> " & path
    exeCache[cmd] = path
    return path

proc getLxcVersion*(): string {.inline.} =
  &readOutput("lxc-info", "--version")

proc getLxcMajor*(): uint {.inline, raises: [ValueError, Exception].} =
  getLxcVersion().split('.')[0].parseUint()

proc addNodeEntry*(
    nodes: var seq[string],
    src: string,
    dest: Option[string],
    mntType, options: string,
    check: bool,
): bool {.discardable.} =
  if check and not fileExists(src) and not devExists(src) and not dirExists(src):
    return false

  var entry = "lxc.mount.entry = "
  entry &= src & ' '
  if not *dest:
    entry &= src[1 ..< src.len] & ' '
  else:
    entry &= &dest & ' '

  entry &= mntType & ' '
  entry &= options
  nodes &= ensureMove(entry)

  true

proc generateNodesLxcConfig*(): seq[string] =
  var nodes: seq[string]

  proc entry(
      src: string,
      dest: Option[string] = none(string),
      mntType: string = "none",
      options: string = "bind,create=file,optional 0 0",
      check: bool = true,
  ): bool {.discardable.} =
    addNodeEntry(nodes, src, dest, mntType, options, check)

  entry "tmpfs", some("dev"), "tmpfs", "nosuid 0 0", false
  entry "/dev/zero"
  entry "/dev/null"
  entry "/dev/full"
  entry "/dev/ashmem"
  entry "/dev/fuse"
  entry "/dev/ion"
  entry "/dev/tty"
  entry("/dev/char", options = "bind,create=dir,optional 0 0")

  for gfxNode in [
    "/dev/kgsl-3d0", "/dev/mali0", "/dev/pvr_sync", "/dev/pmsg0", "/dev/dxg"
  ]:
    entry gfxNode

  let noded = getDriNode()
  if not *noded:
    error "container/gpu: no suitable GPU found. If you believe that this is an error, please open a bug ticket in the Lucem Discord server with the output of `lspci`"
    raise newException(Defect, "No suitable GPU found.")

  let node = &noded

  entry node.dev # , some("dev/dri/renderD128")
  entry node.gpu # , some("dev/dri/card1") 

  for node in glob("/dev/fb*").walkGlob:
    entry node

  for node in glob("/dev/graphics/fb*").walkGlob:
    entry node

  for node in glob("/dev/video*").walkGlob:
    entry node

  entry "/dev" / config.binder, some("dev/binder"), check = false
  entry "/dev" / config.vndbinder, some("dev/vndbinder"), check = false
  entry "/dev" / config.hwbinder, some("dev/hwbinder"), check = false

  if config.vendorType != "MAINLINE":
    if not entry("/dev/hwbinder", some("dev/host_hwbinder")):
      raise newException(Defect, "Binder node \"hwbinder\" of host not found!")

    entry "/vendor", some("vendor_extra"), "rbind,optional 0 0"

  entry "none",
    some("dev/pts"),
    "devpts",
    "defaults,mode=644,ptmxmode=666,create=dir 0 0",
    check = false
  entry "/dev/uhid"

  entry "/sys/module/lowmemorykiller", options = "bind,create=dir,optional 0 0"

  entry "/dev/Vcodec"
  entry "/dev/MTK_SMI"
  entry "/dev/mdp_sync"
  entry "/dev/mtk_cmdq"

  entry "tmpfs", some("mnt_extra"), "tmpfs", "nodev 0 0", false
  entry "tmpfs", some("tmp"), "tmpfs", "nodev 0 0", false
  entry "tmpfs", some("var"), "tmpfs", "nodev 0 0", false
  entry "tmpfs", some("run"), "tmpfs", "nodev 0 0", false

  nodes

proc setLxcConfig*() =
  info "lxc: setting up configuration"
  debug "lxc: working directory = " & config.work
  debug "lxc: LXCARCH = " & getArchStr()
  let lxcMajor = getLxcMajor()
  let lxcPath = config.lxc / "equinox"

  let substituteTable = {
    "LXCARCH": getArchStr(),
    "WORKING": config.work,
    "WLDISPLAY": config.containerWaylandDisplay,
  }

  var configs = @[CONFIG_BASE.multiReplace(substituteTable)]
  if lxcMajor <= 2:
    configs &= CONFIG_1
  else:
    for ver in 3 .. 4:
      if lxcMajor >= ver.uint:
        configs &=
          (
            case ver
            of 3: CONFIG_3
            of 4: CONFIG_4
            else:
              assert(false, "Unreachable")
              ""
          ).multiReplace(substituteTable)

  discard existsOrCreateDir(config.lxc)

  debug "lxc: creating LXC path"
  discard existsOrCreateDir(lxcPath)

  debug "lxc: writing LXC config"
  writeFile(lxcPath / "config", configs.join("\n"))

  debug "lxc: writing LXC seccomp profile"
  writeFile(lxcPath / "equinox.seccomp", SECCOMP_POLICY)

  let nodes = generateNodesLxcConfig()

  var buffer: string
  for node in nodes:
    buffer &= node & '\n'

  writeFile(lxcPath / "config_nodes", ensureMove(buffer))

  # Write an empty file to config_session. It'll be overwritten every run.
  writeFile(lxcPath / "config_session", newString(0))

proc generateSessionLxcConfig*() =
  ## Generate session-specific LXC configurations

  var nodes: seq[string]
  proc entry(
      src: string,
      dest: Option[string] = none(string),
      mntType: string = "none",
      options = "rbind,create=file 0 0",
  ): bool {.discardable.} =
    for x in src:
      if x in {'\n', '\r'}:
        warn "lxc: user-provided mount path contains illegal character: " & x.repr
        return false

    # if not *dist and (not (fileExists(src) or dirExists(src) or devExists(src)))

    addNodeEntry(nodes, src, dest, mntType, options, check = false)

  if not entry("tmpfs", config.containerXdgRuntimeDir.some, options = "create=dir 0 0"):
    fatal "lxc: failed to create runtime dir mount point. We'll now crash. :("
    raise newException(OSError, "Failed to create XDG_RUNTIME_DIR mount point!")

  let
    waylandContainerSocket =
      absolutePath(config.containerXdgRuntimeDir / config.containerWaylandDisplay)
    waylandHostSocket =
      absolutePath(config.containerXdgRuntimeDir / config.containerWaylandDisplay)

  if not entry(
    waylandHostSocket, waylandContainerSocket[1 ..< waylandContainerSocket.len].some
  ):
    fatal "equinox: failed to bind Wayland socket!"
    raise newException(
      OSError,
      "Cannot bind Wayland socket.\nContainer = " & waylandContainerSocket & "\nHost = " &
        waylandHostSocket,
    )

  setLenUninit()

  let
    pulseHostSocket = config.containerPulseRuntimePath / "native"
    pulseContainerSocket = config.containerPulseRuntimePath / "native"

  entry pulseHostSocket, pulseContainerSocket[1 ..< pulseContainerSocket.len].some

  if not entry(config.equinoxData, "data".some, options = "rbind 0 0"):
    raise newException(OSError, "Failed to bind userdata")

  var buffer: string
  for node in nodes:
    buffer &= node & '\n'

  buffer &= "lxc.environment=WAYLAND_DISPLAY=" & config.containerWaylandDisplay

  setLenUninit()
  writeFile(config.lxc / "equinox" / "config_session", ensureMove(buffer))

proc getLxcStatus*(): string =
  let value = readOutput("sudo lxc-info", "-P " & config.lxc & " -n equinox -sH")

  if not *value:
    return "STOPPED"

  &value

proc startLxcContainer*(input: Input) =
  debug "lxc: starting container"

  var debugLog = input.flag("log-file")

  runCmd(
    "sudo lxc-start",
    "-l DEBUG -P " & config.lxc & (if *debugLog: " -o " & &debugLog else: "") &
      " -n equinox -- /init",
  )
  let pid = (&readOutput("pidof", "lxc-start")).strip().parseUint()  # FIXME: please fix this PEAK code to be less PEAK
  setLenUninit()

  if *debugLog:
    runCmd("sudo chown", "1000 " & &debugLog)
  
  var status: cint
  discard waitpid(Pid(pid), status, 0)

  if WIFEXITED(status):
    info "equinox: runtime has been stopped."
  else:
    warn "equinox: runtime stopped abnormally."

proc stopLxcContainer*(force: bool = false) =
  debug "lxc: stopping container"

  if force:
    warn "lxc: forcefully stopping container. This might cause wonky stuff to happen in the next run."

  if getLxcStatus() == "STOPPED":
    warn "lxc: container has already stopped"
    quit(1)

  runCmd(
    "sudo lxc-stop", "-P " & config.lxc & " -n equinox" & (if force: " -k" else: "")
  )

  info "equinox: stopped container."

proc waitForContainerBoot*(maxAttempts: uint64 = 32'u64) =
  ## Block this thread until the container boots up.
  debug "lxc: waiting for container to boot up"

  var attempts: uint64
  while getLxcStatus() != "RUNNING":
    if attempts > maxAttempts:
      break

    debug "lxc: wait #" & $attempts
    inc attempts
    sleep(10) # professional locking mechanism

  if getLxcStatus() != "RUNNING":
    raise newException(
      Defect,
      "The container did not start after " & $maxAttempts &
        " iterations. It might be deadlocked.\nConsider running the following command to forcefully kill it:\nsudo equinox halt -F\n",
    )

  setLenUninit()

  info "lxc: container booted up after " & $attempts & " attempts."

proc runCmdInContainer*(cmd: string): Option[string] =
  setLenUninit()
  readOutput("sudo lxc-attach", "-P " & config.lxc & " -n equinox -- " & cmd)
