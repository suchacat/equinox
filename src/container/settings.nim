## Android settings
## Copyright (C) 2025 the EquinoxHQ team
import ./[lxc]

proc settingsPut*(namespace: string, key: string, value: bool | string | SomeInteger) =
  var cmd = "/bin/cmd settings put " & namespace & ' ' & key & ' '

  when value is bool:
    cmd &= $int(value)

  when value is string:
    cmd &= value

  when value is SomeInteger:
    cmd &= $value

  discard runCmdInContainer(move(cmd))
