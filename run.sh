#!/usr/bin/env bash

sudo ./equinox run --xdg-runtime-dir:$XDG_RUNTIME_DIR --user:$(whoami) --uid:$UID --gid:$GID --wayland-display:$WAYLAND_DISPLAY
