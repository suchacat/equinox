# equinox
Equinox is a stupid runtime for Roblox on Linux that uses LXC containers to run (y)our beloved lego game.

# Progress
- [X] Get a container running
- [X] Get the GPU working in the container
- [X] Make it run Roblox
- [ ] PC-exclusive game support
- [ ] Proper mouselocking support
- [ ] Discord RPC (with Bloxstrap)
- [ ] All configuration options from Lucem 2.x
- [ ] New configuration options (possibly like Sober's asset overlay?)

# Known Issues (These will be fixed sooner or later)
- Performance is really bad in certain games (Arsenal, Dead Rails, etc.)
- Graphical artifacting on integrated GPUs
- Mouse locking does not work
- PC-exclusive games are not playable (Project Remix, Arcane Odyssey, etc.)
- Clipboard support is not implemented

# Known Issues (Which are a long-term goal to fix)
- Nvidia support (possibly via VirGL/Venus? Probably requires a custom HAL implementation)

# Notes
## Fedora
Disable SELinux with `sudo setenforce Permissive`. SELinux messes with LXC.
