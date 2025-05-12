import std/[os]
import pkg/[jsony]

type AppState* = object
  promptGsm*: bool = true

proc save*(state: AppState) =
  var directory: string

  for parts in [getHomeDir(), ".local", "state", "equinox"]:
    directory &= parts & '/'
    discard existsOrCreateDir(directory)

  writeFile(directory / "state.json", toJson(state))

proc getAppState*(): AppState =
  var directory: string

  for parts in [getHomeDir(), ".local", "state", "equinox"]:
    directory &= parts & '/'
    discard existsOrCreateDir(directory)

  let
    stateExists = fileExists(directory / "state.json")
    state =
      if stateExists:
        readFile(directory / "state.json").fromJson(AppState)
      else:
        default(AppState)

  if not stateExists:
    writeFile(directory / "state.json", toJson(state))

  state
