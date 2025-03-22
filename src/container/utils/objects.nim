proc make*[T](typ: typedesc[T]): ptr T {.inline, sideEffect.} =
  cast[ptr T](alloc(sizeof(typ)))
