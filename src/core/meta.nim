## Compile-time build info

const
  CommitHash* = gorge("git describe --tags --long --dirty")
  Version* {.strdefine: "NimblePkgVersion".} = "<not defined at compile time>"
  LegalDisclaimerLong* = staticRead("../../legal/disclaimer.txt")
  Splashes* = [
    "\"pc game support when\" bro im not even done installing my rootkits on your pc -tray",
    "all hail the NT flying horse",
    "\"im in a perpetual state of shitting myself\" -hippoz, 2025",
    "compiled with the full clanger soyboy toolchain, complete with mimalloc",
    "eternal hunger", "iltam zumra rashupti elatim", "total soong death",
    "never forget the april 2025 chmod incident", "who up flingin they surfaces rn"
  ]
