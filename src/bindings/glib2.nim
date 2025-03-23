## yippee
import std/[strutils]

{.passC: gorge("pkg-config --cflags glib-2.0").}
{.passL: gorge("pkg-config --libs glib-2.0").}

{.push header: "<glib-2.0/glib.h>".}
type
  GMainContext* {.importc.} = object
  GMainLoop* {.importc.} = object

{.push importc.}
var G_PRIORITY_HIGH*: int32
var G_PRIORITY_DEFAULT*: int32
var G_PRIORITY_HIGH_IDLE*: int32
var G_PRIORITY_DEFAULT_IDLE*: int32
var G_PRIORITY_LOW*: int32
var G_PRIORITY_LOW_IDLE*: int32

proc g_main_context_new*(): ptr GMainContext
proc g_main_context_ref*(ctx: ptr GMainContext)
proc g_main_context_is_owner*(ctx: ptr GMainContext): bool
proc g_main_context_default*(): ptr GMainContext
proc g_main_context_get_thread_default*(): ptr GMainContext
proc g_main_context_ref_thread_default*(): ptr GMainContext
proc g_main_context_push_thread_default*(ctx: ptr GMainContext)
proc g_main_context_pop_thread_default*(ctx: ptr GMainContext)
proc g_main_context_unref*(ctx: ptr GMainContext)

proc g_main_loop_new*(ctx: ptr GMainContext, isRunning: bool): ptr GMainLoop
proc g_main_loop_run*(loop: ptr GMainLoop)
proc g_main_loop_quit*(loop: ptr GMainLoop)
proc g_main_loop_ref*(loop: ptr GMainLoop)
proc g_main_loop_unref*(loop: ptr GMainLoop)
proc g_main_loop_is_running*(loop: ptr GMainLoop): bool
proc g_main_loop_get_context*(loop: ptr GMainLoop): ptr GMainContext

{.pop.}

{.pop.}
