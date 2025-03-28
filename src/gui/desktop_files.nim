import std/[logging, os, strutils]

const
  MimeTemplate =
    """
[Desktop Entry]
Name=Equinox MIME Handler
Exec=$1 mime-handler %u
Type=Application
NoDisplay=true
MimeType=x-scheme-handler/roblox;
    """

  DesktopEntryTemplate =
    """
[Desktop Entry]
Name=Equinox
Comment=A runtime for Roblox on Linux using containerization
Exec=$1 auto
Terminal=false
Type=Application
Icon=equinox
Categories=Game;Utility
    """

proc ensureDirsExist*(): string {.sideEffect.} =
  var buf = newStringOfCap(32)
  buf &= getHomeDir()

  for path in [".local", "share", "applications"]:
    buf &= '/' & path
    discard existsOrCreateDir(buf)

  ensureMove(buf)

proc createMimeHandlerEntry*() =
  debug "desktop_files: creating MIME handler entry"
  writeFile(
    ensureDirsExist() / "equinox-mime.desktop",
    MimeTemplate % [
      getAppFilename()
    ]
  )

proc createDesktopEntries*() =
  debug "desktop_files: creating desktop entry for equinox"
  writeFile(
    ensureDirsExist() / "equinox.desktop",
    DesktopEntryTemplate % [
      getAppFilename()
    ]
  )
