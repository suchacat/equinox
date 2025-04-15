import std/[logging, options, importutils, locks]
import pkg/curly # {.all.}

# privateAccess(RequestWrapObj)
# privateAccess(CurlyObj)

var curl {.global.} = newCurly()

proc httpGet*(url: string, headers: HttpHeaders = emptyHttpHeaders()): Response =
  debug "http: GET: " & url
  let resp = curl.get(url, headers, timeout = -1)

  debug "http: got response code " & $resp.code

  resp

proc malloc_usable_size*(p: pointer): uint64 {.importc, header: "<malloc.h>".}

#[
proc download*(url: string): string =
  ## Download data from a URL while also showing the progress (and writing it to `/tmp/equinox-download-progress.json` as a small hack)
  debug "http/download: GET: " & url

  curl.startRequest("GET", url)

  while true:
    let resp = curl.pollForResponse()
    if resp.isSome:
      info "download completed!"
      return resp.get().body
      
    acquire(curl.lock)

    # We're only sending 1 request so we can just safely pick up the first one here.
    let inflight =
      block:
        var request: RequestWrap
        for easy, req in curl.inFlight:
          req = request

        request

    let
      received = malloc_usable_size(inflight.body).int
      total = inflight.bodyLen
      progress = float(received / total)

    info "GET: " & url & " (" & $(progress * 100f) & "%)"
    writeFile(
      "/tmp/equinox-download-progress.json",
    )
  ]#
