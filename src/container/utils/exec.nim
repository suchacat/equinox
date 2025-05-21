## All the utilities for executing commands
import std/[os, osproc, options, logging, strutils]

proc readOutput*(bin: string, cmd: string): Option[string] =
  let command = bin & ' ' & cmd
  debug "container/utils/exec: readOutput: " & command

  let res = execCmdEx(command)

  some(res.output.strip())

proc runCmd*(bin: string, cmd: string, resolve: bool = false): bool {.discardable.} =
  let command = (if resolve: findExe(bin) else: bin) & ' ' & cmd
  debug "runCmd(" & command & ')'

  execCmd(command) == 0
