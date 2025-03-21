import std/[logging]
import pkg/curly

var curl {.global.} = newCurly()

proc httpGet*(url: string, headers: HttpHeaders = emptyHttpHeaders()): Response =
  debug "http: GET: " & url
  let resp = curl.get(url, headers, timeout = -1)

  debug "http: got response code " & $resp.code

  resp
