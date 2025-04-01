import std/[logging, options]
import ./api/[games, thumbnails]
import pkg/[discord_rpc]

const
  RPCApplicationId* {.intdefine.} = 1276893796679942195

proc handleIdleRPC*(rpc: DiscordRPC) =
  rpc.setActivity(
    Activity(
      details: "Roblox",
      state: "In the App",
      assets: some ActivityAssets(
        largeImage: "lucem",
        largeText: "Equinox is a FOSS containerized runtime for Roblox on Linux."
      )
    )
  )

proc handleGameRPC*(rpc: DiscordRPC, placeId: string) =
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
        smallText: "Equinox is a FOSS containerized runtime for Roblox on Linux."
      )
    )
  )
