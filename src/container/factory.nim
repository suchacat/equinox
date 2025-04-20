## factory properties
## these can be used to forcefully override read-only system properties
##
## Copyright (C) 2025 Trayambak Rai
import std/[os, logging, tables]
import ./[config],
       ./utils/exec

type
  Factory* = object
    opts*: Table[string, string]

proc mountFactory*(factory: Factory) =
  debug "factory: mounting `/factory` and attaching property list"
  discard runCmd("sudo", "mount --mkdir ")
