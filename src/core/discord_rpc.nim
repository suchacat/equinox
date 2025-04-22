import std/[logging, options, json, options]
import ./api/[games, thumbnails]
import pkg/[discord_rpc, shakar]

const RPCApplicationId* {.intdefine.} = 1276893796679942195

proc handleIdleRPC*(rpc: DiscordRPC) =
  if rpc == nil:
    return

  rpc.setActivity(
    Activity(
      details: "Roblox",
      state: "In the App",
      assets: some ActivityAssets(
        largeImage: "lucem",
        largeText: "Equinox is a FOSS containerized runtime for Roblox on Linux.",
      ),
    )
  )

proc handleBloxstrapRPC*(rpc: DiscordRPC, payload: JsonNode) =
  if rpc == nil:
    return

  let
    details = payload["details"].getStr()
    state = payload["state"].getStr()
    largeImage = payload["largeImage"]

  let thumbnailLarge = getThumbnailUrl(
    ThumbnailRequest(
      targetId: uint64(largeImage["assetId"].getBiggestInt()),
      `type`: "Asset",
      size: "512x512",
      format: "png",
      isCircular: false
    )
  )
  
  var activity = Activity(
    details: details,
    state: state,
    assets: some ActivityAssets(
      largeImage:
        if *thumbnailLarge.imageUrl:
          &thumbnailLarge.imageUrl
        else:
          newString(0)
      ,
      largeText: largeImage["hoverText"].getStr(),
      smallImage: "lucem",
      smallText: "Equinox is a FOSS containerized runtime for Roblox on Linux.",
    ),
  )

  rpc.setActivity(move(activity))

proc handleGameRPC*(rpc: DiscordRPC, placeId: string) =
  if rpc == nil:
    return

  let
    id = getUniverseFromPlace(placeId)
    details = getGameDetail(id)

  debug "Name => " & details.name
  debug "Description => " & details.description
  debug "Creator => " & details.creator.name

  let thumbnail = getGameIcon(id)

  info "equinox: updating rich presence"
  rpc.setActivity(
    Activity(
      details: details.name,
      state: "by " & details.creator.name,
      assets: some ActivityAssets(
        largeImage: thumbnail.imageUrl,
        # largeText: details.description,
        smallImage: "lucem",
        smallText: "Equinox is a FOSS containerized runtime for Roblox on Linux.",
      ),
    )
  )
