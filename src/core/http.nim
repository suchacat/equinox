## Exception-tolerant HTTP wrapper around curly.
import pkg/[curly, jsony, results, sanchar/parse/url]

var pool {.global.} = newCurlPool(2)

template validateUrl(url: string) =
  if (let validation = isValidUrl(url); not validation.answer):
    return err("Invalid URL: ferus-sanchar says: " & validation.reason)

proc httpGet*(url: string): Result[string, string] {.raises: [].} =
  validateUrl(url)

  pool.withHandle curl:
    try:
      let response = curl.get(url)

      if response.code != 200:
        return err("Got response code " & $response.code)

      return ok(response.body)
    except CatchableError as exc:
      return err("curly/libcURL error: " & exc.msg)

proc httpPost*[T](url: string, body: T): Result[string, string] {.raises: [].} =
  validateUrl(url)

  pool.withHandle curl:
    try:
      let response = curl.post(url, body = body.toJson)

      if response.code != 200:
        return err("Got response code " & $response.code)

      return ok(response.body)
    except CatchableError as exc:
      return err("curly/libcURL error: " & exc.msg)
