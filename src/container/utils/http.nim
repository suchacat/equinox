import std/[logging, options, terminal, math, json, times, posix]
import pkg/[libcurl, curly]

var curl {.global.} = newCurly()

proc httpGet*(
    url: string, headers: httpheaders.HttpHeaders = emptyHttpHeaders()
): curly.Response =
  debug "http: GET: " & url
  let resp = curl.get(url, headers, timeout = -1)

  debug "http: got response code " & $resp.code

  resp

var
  OPT_XFERINFOFUNCTION: int32 = 219'i32
  OPT_XFERINFODATA: int32 = 57'i32

proc download*(url: string, dest: string): bool =
  ## Download a file to `dest`. This function is designed for large downloads (that go into hundreds of megabytes or gigabytes)
  ## to make sure that Equinox doesn't start filling up the RAM (as it used to :P).
  ##
  ## It uses raw libcURL instead of curly, so be wary about its implications.
  debug "http: downloading from url: " & url & " to dest: " & dest

  var lcurl = libcurl.easy_init()
  var lastSpeedCalcP = epochTime().fromUnixFloat().toUnix()
  var lastTotalP = 0'i64
  var speedP: int64
  var progressData = [lastTotalP.addr, speedP.addr, lastSpeedCalcP.addr]

  discard libcurl.easy_setopt(
    lcurl, cast[libcurl.Option](OPT_PROGRESSDATA), progressData.addr
  )
  discard lcurl.easy_setopt(libcurl.OPT_NOPROGRESS, 0)
  discard libcurl.easy_setopt(
    lcurl,
    libcurl.OPT_PROGRESSFUNCTION,
    proc(clientp: pointer, dltotal, dlnow, ultotal, ulnow: float64): int32 {.cdecl.} =
      debug "http: dltotal = " & $dltotal & "; dlnow = " & $dlnow & " (bytes)"
      var
        payload = cast[ptr array[3, ptr int64]](clientp)
        lastTotal = payload[0]
        speed = payload[1]
        lastSpeedCalc = payload[2]

      let currTime = epochTime().fromUnixFloat().toUnix() # peak efficiency
      if (currTime - lastSpeedCalc[]) >= 1:
        lastSpeedCalc[] = currTime
        speed[] = dlnow.int64 - lastTotal[]
        lastTotal[] = dlnow.int64

      stdout.write("\x1b[1A")
      stdout.write("\x1b[2K")
      let
        speedKbps = speed[] / 1000'i64
        speedColor =
          if speedKbps >= 4096:
            fgGreen
          elif speedKbps >= 2048:
            fgBlue
          elif speedKbps >= 800:
            fgYellow
          else:
            fgRed

        downloadSpeedHours = round((dltotal - dlnow).int64 / speed[] / 3600, 2)

        downloadSpeedColor =
          if downloadSpeedHours < 0.1:
            fgBlue
          elif downloadSpeedHours < 0.2:
            fgGreen
          elif downloadSpeedHours < 0.5:
            fgYellow
          else:
            fgRed

      writeFile(
        "/tmp/equinox-progress.json",
        $(%*{"speedKbps": speedKbps, "totalBytes": dltotal, "downloadedBytes": dlnow}),
      )

      #[ stdout.styledWriteLine(
        fgGreen, $(dlnow / 1_000_000), resetStyle, " MB", styleBright, " / ", resetStyle, fgGreen, $(dltotal / 1_000_000), " MB",  resetStyle,
        styleBright, " (", resetStyle, speedColor, $speedKbps, resetStyle, " kb/s", styleBright, ") [", resetStyle, downloadSpeedColor, $downloadSpeedHours, resetStyle, " hours", styleBright, "]", resetStyle
      ) ]#

      0'i32,
  )

  var fd = open(dest.cstring, O_WRONLY or O_APPEND or O_CREAT, 0644)

  # discard lcurl.easy_setopt(libcurl.OPT_USERAGENT, "Mozilla/5.0")
  discard lcurl.easy_setopt(libcurl.OPT_HTTPGET, 1)
  discard lcurl.easy_setopt(libcurl.OPT_WRITEDATA, fd.addr)
  discard lcurl.easy_setopt(libcurl.OPT_URL, url.cstring)
  discard lcurl.easy_setopt(
    libcurl.OPT_WRITEFUNCTION,
    proc(buffer: cstring, size: int, count: int, outstream: pointer): uint64 =
      debug "http: download writefunction invoked: size=" & $size & "; count=" & $count
      let writeFd = cast[ptr int32](outstream)[]

      uint64(write(writeFd, buffer, count)),
  )

  debug "http: dispatching libcURL request"
  let ret = lcurl.easy_perform()
  discard close(fd)
  if ret != E_OK:
    error "http: failed to download file `" & url & "`: " & $easy_strerror(ret)
    return false

  true
