import std/[logging]
import pkg/curly

var curl {.global.} = newCurly()

proc httpGet*(url: string, headers: HttpHeaders = emptyHttpHeaders()): Response =
  debug "http: GET: " & url
  curl.get(url, headers, timeout = -1)
