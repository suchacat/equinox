## Roblox games/places ("experiences") API
## Copyright (C) 2024 Trayambak Rai
## Copyright (C) 2025 the EquinoxHQ team
import std/[logging, strutils, json, options]
import pkg/[curly, jsony]

var curl = newCurly()

type
  PlaceID* = int64
  CreatorID* = int64
  UniverseID* = int64

  Creator* = object
    id*: CreatorID
    name*: string
    `type`*: string
    isRNVAccount*: bool
    hasVerifiedBadge*: bool

  AvatarType* = enum
    MorphToR6 = "MorphToR6"
    PlayerChoice = "PlayerChoice"
    MorphToR15 = "MorphToR15"

  StubData*[T] = object
    data*: seq[T]

  GameDetail* = object
    id*, rootPlaceId*: PlaceID
    name*, description*, sourceName*, sourceDescription*: string
    creator*: Creator
    price*: Option[int64]
    allowedGearGenres*: seq[string]
    allowedGearCategories*: seq[string]
    isGenreEnforced*, copyingAllowed*: bool
    playing*, visits*: int64
    maxPlayers*: int32
    created*, updated*: string
    studioAccessToApisAllowed*, createVipServersAllowed*: bool
    avatarType*: AvatarType
    genre*: string
    isAllGenre*, isFavoritedByUser*: bool
    favoritedCount*: int64

  PlaceDetail* = object
    id*: PlaceID
    name*, description*, sourceName*, sourceDescription*, url*, builder*: string
    builderId*: CreatorID
    hasVerifiedBadge*, isPlayable*: bool
    reasonProhibited*: string
    universeId*: UniverseID
    universeRootPlaceId*: PlaceID
    price*: Option[int64]
    imageToken*: string

proc getUniverseFromPlace*(placeId: string): UniverseID {.inline.} =
  let payload = curl.get(
      "https://apis.roblox.com/universes/v1/places/$1/universe" % [placeId]
    ) # TODO: better error handling? if we get an erroneous output we'll just shit ourselves
    .body
    .parseJson()["universeId"]
    .getInt()
    .UniverseID()

  payload

proc getGameDetail*(id: UniverseID): GameDetail =
  let
    url = "https://games.roblox.com/v1/games/?universeIds=" & $id
    resp = curl.get(url).body

  debug "getGameDetail($1): $2" % [$id, resp]
  let payload = fromJson(resp, StubData[GameDetail]).data[0]

  payload
