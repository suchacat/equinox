# equinox
Equinox is a stupid runtime for Roblox on Linux that uses LXC containers to run (y)our beloved lego game.

# Progress
- Get a container running [X]
- Get the GPU working in the container [X]
- Make it run Roblox [ ]

# Notes
## Fedora
Disable SELinux with `sudo setenforce Permissive`. SELinux messes with LXC.
