import std/[logging, os, strutils]
import ./envparser

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

  DesktopEntryShell =
    """
[Desktop Entry]
Name=Equinox Settings
Comment=Settings menu for Equinox
Terminal=false
Type=Application
Icon=equinox
Categories=Game;Utility
Exec=$1 shell
    """

proc ensureDirsExist*(): string {.sideEffect.} =
  if equinoxBin.len < 1:
    var buf = newStringOfCap(32)
    buf &= getHomeDir()

    for path in [".local", "share", "applications"]:
      buf &= '/' & path
      discard existsOrCreateDir(buf)

    return ensureMove(buf)

proc createMimeHandlerEntry*() =
  if equinoxBin.len < 1:
    debug "desktop_files: creating MIME handler entry"
    writeFile(
      ensureDirsExist() / "equinox-mime.desktop", MimeTemplate % [getAppFilename()]
    )

proc createDesktopEntries*() =
  if equinoxBin.len < 1:
    debug "desktop_files: creating desktop entry for equinox"
    writeFile(
      ensureDirsExist() / "equinox.desktop", DesktopEntryTemplate % [getAppFilename()]
    )
    writeFile(
      ensureDirsExist() / "equinox_shell.desktop", DesktopEntryShell % [getAppFilename()]
    )
