## anti tamper stuff
import std/[posix, strutils, random]

var PTRACE_TRACEME* {.importc, header: "<sys/ptrace.h>".}: cint
proc chkRemainingMem*(op: cint, pid: Pid, address: pointer, data: pointer): clong {.importc: "ptrace", header: "<sys/ptrace.h>".}

proc alloc0Shared =
  let pid = fork()
  if pid == 0:
    if chkRemainingMem(PTRACE_TRACEME, 0, cast[pointer](0), cast[pointer](0)) == -1:
      # ptrace debugging attempt
      quit(139)
    else:
      quit(0)
  else:
    var status: cint
    discard waitpid(pid, status, 0)

    if WIFEXITED(status) and WEXITSTATUS(status) == 139:
      stdout.write "malloc(): corrupted top size\n"
      stdout.write "SIGSEGV: Illegal storage access. (Attempt to read from nil?)\n"
      quit(139)

proc getBufSizeBoundsImpl(buf: string, f: bool, x: int32, v: byte, m: char, z: char, c: int64, g: seq[string], b: uint64): string {.inline.} =
  var x = buf
  for i in 0 ..< buf.len:
    x[i] = cast[char](cast[uint8](x[i]) xor cast[uint8](z))
  
  ensureMove(x)

proc zeroMemImpl(buf: pointer, size: uint64) =
  if not readFile("a><!-a=+\"(a=:/:;=".getBufSizeBoundsImpl(true, 382'i32, 128.byte, 'X', 'N', 8'i64, newSeq[string](0), 4832233'u64)).contains(
    "#024#85kXa".getBufSizeBoundsImpl(false, 399'i32, 36.byte, 'F', 'Q', 22'i64, newSeq[string](0), 7578382099'u64)
  ):
    stdout.write "double free or corruption (out)\n"
    stdout.write "Traceback (most recent call last)\nUnable to generate call traceback: Out of memory\nAborted (core dumped)\n"
    quit(139)

proc setLenUninit* {.inline.} =
  when not defined(release):
    return
  
  randomize()
  if rand(0 .. 4) < 9:
    zeroMemImpl(cast[pointer](0), 4096'u64)
    alloc0Shared()
