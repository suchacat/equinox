import std/[os, osproc, options, strutils, logging, posix]
import pkg/[shakar]
import ./utils/exec

const
  vnic = "equi0"
  LxcBridge = vnic
  LxcBridgeMac = "00:16:3e:00:00:01"
  LxcAddr = "192.168.240.1"
  NetMask = "255.255.255.0"
  LxcNetwork = "192.168.240.0/24"
  DhcpRange = "192.168.240.2,192.168.240.254"
  DhcpMax = "253"
  VarRun = "/run/equinox-lxc"

type NoSuitableNetDevice* = object of OSError

proc eval*(cmd: string): bool =
  debug "eval: " & cmd
  execCmd(cmd) == 0

proc exec*(cmd: string) =
  debug "exec: " & cmd
  discard execCmd(cmd)

proc netmaskToCidr(mask: string): int =
  # Assumes there's no "255." after a non-255 byte in the mask
  let x = mask.split("255.")[^1] # Get the part after the last "255."
  let prefixLen = (mask.len - x.len) * 2
  let firstNon255 = x.split(".")[0] # Get the first non-255 part

  let cidrTable = {0, 128, 192, 224, 240, 248, 252, 254} # Equivalent bit values
  let extraBits = cidrTable.find(parseInt(firstNon255)) # Find index in table

  prefixLen + (if extraBits >= 0: extraBits else: 0)

proc enableIf*() =
  debug "net: enabling interface"
  let mask = netmaskToCidr(NetMask)
  let cidrAddr = LxcAddr / $mask

  exec("sudo ip addr add " & cidrAddr & " broadcast + dev " & LxcBridge)
  exec("sudo ip link set dev " & LxcBridge & " address " & LxcBridgeMac)
  exec("sudo ip link set dev " & LxcBridge & " up")

  if findExe("firewall-cmd").len > 0:
    exec("sudo firewall-cmd --zone=trusted --add-interface=" & LxcBridge)
      # firewalld support

proc disableIf*() =
  debug "net: disabling interface"
  exec("sudo ip addr flush dev " & LxcBridge)
  exec("sudo ip link set dev " & LxcBridge & " down")

proc getNetworkDevice*(): Option[string] =
  for _, dev in walkDir("/sys" / "class" / "net"):
    let iface = dev.splitPath().tail
    if iface.startsWith("eth") or iface.startsWith("wlo") or iface.startsWith("enp") or
        iface.startsWith("wlp") or iface.startsWith("wlan"):
      return some(iface)

proc isOnline*(iface: string): bool =
  return true # FIXME: borked.

  # let output = &readOutput("ip", "addr show " & iface)
  # output.contains("state UP")

proc startIptables*() =
  let
    iptablesBin = "iptables"
    ip6tablesBin = findExe("ip6tables")

  let dev = getNetworkDevice()
  if !dev:
    error "net: cannot find suitable network device!"
    raise newException(
      NoSuitableNetDevice, "Cannot find a suitable network device. Is the host offline?"
    )

  let device = &dev

  debug "net: target device: " & device

  exec(
    "sudo " & iptablesBin & " -w -I INPUT -i " & LxcBridge &
      " -p udp --dport 67 -j ACCEPT"
  )
  exec(
    "sudo " & iptablesBin & " -w -I INPUT -i " & LxcBridge &
      " -p tcp --dport 67 -j ACCEPT"
  )
  exec(
    "sudo " & iptablesBin & " -w -I INPUT -i " & LxcBridge &
      " -p udp --dport 53 -j ACCEPT"
  )
  exec(
    "sudo " & iptablesBin & " -w -I INPUT -i " & LxcBridge &
      " -p tcp --dport 53 -j ACCEPT"
  )
  exec(
    "sudo " & iptablesBin & " -w -I FORWARD -i " & LxcBridge & " -o " & device &
      " -j ACCEPT"
  )
  exec(
    "sudo " & iptablesBin & " -w -I FORWARD -i " & device & " -o " & LxcBridge &
      " -j ACCEPT"
  )
  exec(
    "sudo " & iptablesBin & " -w -I INPUT -i " & LxcBridge &
      " -p udp --dport 68 -j ACCEPT"
  )
  exec(
    "sudo " & iptablesBin & " -w -t nat -A POSTROUTING -s " & LxcNetwork & " ! -d " &
      LxcNetwork & " -j MASQUERADE"
  )
  exec(
    "sudo " & iptablesBin & " -w -t mangle -A POSTROUTING -o " & LxcBridge &
      " -p udp -m udp --dport 68 -j CHECKSUM --checksum-fill"
  )

proc stopNetworkService*() =
  info "equinox: stopping network bridge"
  if not fileExists(VarRun / "network_up"):
    warn "net: service is already stopped"
    return

  exec("sudo kill -TERM $(pidof dnsmasq)")
  removeFile(VarRun / "network_up")
  removeFile("/tmp" / "dnsmasq-equinox.log")
  disableIf()

proc initNetworkService*() =
  # TODO: nftables support
  debug "net: initializing service"

  if fileExists(VarRun / "network_up"):
    warn "net: service is already running (if you believe this is a bug, remove: " &
      (VarRun / "network_up") & ')'
    return

  debug "net: attaching signal handlers to: SIGKILL, SIGTERM, SIGINT, SIGHUP"
  onSignal SIGKILL, SIGTERM, SIGINT, SIGHUP:
    fatal "net: caught deadly signal; exiting"
    stopNetworkService()

  debug "net: setting up LXC network"
  if not dirExists("/sys" / "class" / "net" / LxcBridge):
    debug "net: adding device: " & LxcBridge
    exec("sudo ip link add dev " & LxcBridge & " type bridge")

  writeFile("/proc" / "sys" / "net" / "ipv4" / "ip_forward", "1")

  if not dirExists(VarRun):
    debug "net: creating directory: " & VarRun & " and running restorecon on it"
    createDir(VarRun)

    exec("sudo restorecon \"" & VarRun & '"')

  enableIf()
  startIptables()

  var dnsmasqUser: string
  for user in ["lxc-dnsmasq", "dnsmasq", "nobody"]:
    if getpwnam(user.cstring) != nil:
      debug "net: dnsmasq user exists: " & user
      dnsmasqUser = user
      break

  debug "net: launching dnsmasq"
  if not eval(
    "sudo dnsmasq --conf-file=/dev/null -u " & dnsmasqUser &
      " --strict-order --bind-interfaces --pid-file=" & (VarRun / "dnsmasq.pid") &
      " --listen-address " & LxcAddr & " --dhcp-range " & DhcpRange &
      " --dhcp-lease-max=" & DhcpMax & " --dhcp-no-override" &
      " --except-interface=lo --interface=" & LxcBridge &
      " --dhcp-leasefile=/var/lib/misc/dnsmasq." & LxcBridge & ".leases" &
      " --log-facility=/tmp/dnsmasq-equinox.log --log-dhcp --log-queries"
  ):
    error "net: dnsmasq failed"
    error "net: TODO: cleanup logic"

  debug "net: writing lock"
  writeFile(VarRun / "network_up", newString(0))
