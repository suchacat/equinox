## All the utilities for executing commands
import std/[osproc, options, logging, strutils]

proc readOutput*(bin: string, cmd: string): Option[string] =
  let command = bin & ' ' & cmd
  debug "container/utils/exec: readOutput: " & command

  let res = execCmdEx(command)

  some(res.output.strip())

proc runCmd*(bin: string, cmd: string): bool {.discardable.} =
  let command = bin & ' ' & cmd
  # debug "runCmd(" & command & ')'

  execCmd(command) == 0
