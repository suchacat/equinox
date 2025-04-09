import std/posix
import ../src/bindings/virgl

var cb = cast[ptr virgl_renderer_callbacks](alloc(sizeof(virgl_renderer_callbacks)))
zeroMem(cb, sizeof(virgl_renderer_callbacks))
cb.version = VIRGL_RENDERER_CALLBACKS_VERSION
echo virgl_renderer_init(nil, VIRGL_RENDERER_USE_EGL or VIRGL_RENDERER_USE_SURFACELESS, cb)
echo errno
echo errno.strerror
