## All the utilities for executing commands
import std/[osproc, options, logging, strutils]

proc readOutput*(bin: string, cmd: string): Option[string] =
  let command = bin & ' ' & cmd
  debug "container/utils/exec: readOutput: " & command

  let res = execCmdEx(command)

  if res.exitCode != 0:
    warn "container/utils/exec: readOutput: exit code " & $res.exitCode
    echo res.output
    return

  some(res.output.strip())

proc runCmd*(bin: string, cmd: string): bool {.discardable.} =
  let command = bin & ' ' & cmd
  debug "runCmd(" & command & ')'

  execCmd(command) == 0
