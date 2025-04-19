import std/[httpclient, asyncdispatch, logging, options, importutils, locks, terminal, math]
import pkg/curly # {.all.}

# privateAccess(RequestWrapObj)
# privateAccess(CurlyObj)

var curl {.global.} = newCurly()

proc httpGet*(url: string, headers: httpheaders.HttpHeaders = emptyHttpHeaders()): curly.Response =
  debug "http: GET: " & url
  let resp = curl.get(url, headers, timeout = -1)

  debug "http: got response code " & $resp.code

  resp

proc download*(url: string): string =
  debug "http: downloading content: " & url

  var client = newAsyncHttpClient()
  client.onProgressChanged = proc(total, progress, speed: int64) {.async.} =
    stdout.write("\x1b[1A")
    stdout.write("\x1b[2K")
    
    let
      speedKbps = speed / 1000
      speedColor =
        if speedKbps >= 4096:
          fgGreen
        elif speedKbps >= 2048:
          fgBlue
        elif speedKbps >= 800:
          fgYellow
        else: fgRed

      downloadSpeedHours =
        round(
          (total - progress) / speed / 3600,
          2
        )

      downloadSpeedColor =
        if downloadSpeedHours < 0.1:
          fgBlue
        elif downloadSpeedHours < 0.2:
          fgGreen
        elif downloadSpeedHours < 0.5:
          fgYellow
        else:
          fgRed

    stdout.styledWriteLine(
      fgGreen, $(progress / 1_000_000), resetStyle, " MB", styleBright, " / ", resetStyle, fgGreen, $(total / 1_000_000), " MB",  resetStyle,
      styleBright, " (", resetStyle, speedColor, $speedKbps, resetStyle, " kb/s", styleBright, ") [", resetStyle, downloadSpeedColor, $downloadSpeedHours, resetStyle, " hours", styleBright, "]", resetStyle
    )

  let content = waitFor client.getContent(url)
  
  content
