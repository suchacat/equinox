# <img width="36" src="assets/equinox.svg"> equinox
Equinox is a runtime for Roblox on Linux that uses LXC containers to run (y)our beloved lego game.

| | | | |
|-------------------|--------------------|------------------|-------------|
|<img src="https://raw.githubusercontent.com/equinoxhq/equinox/refs/heads/master/images/equinox001.jpg"> | <img src="https://raw.githubusercontent.com/equinoxhq/equinox/refs/heads/master/images/equinox002.jpg"> | <img src="https://raw.githubusercontent.com/equinoxhq/equinox/refs/heads/master/images/equinox003.jpg">
| <img src="https://raw.githubusercontent.com/equinoxhq/equinox/refs/heads/master/images/equinox004.jpg"> | <img src="https://raw.githubusercontent.com/equinoxhq/equinox/refs/heads/master/images/equinox005.jpg"> | <img src="https://raw.githubusercontent.com/equinoxhq/equinox/refs/heads/master/images/equinox007.png"> | <img src="https://raw.githubusercontent.com/equinoxhq/equinox/refs/heads/master/images/equinox006.jpg"> | <img src="https://raw.githubusercontent.com/equinoxhq/equinox/refs/heads/master/images/equinox008.jpg">


# Progress
- [X] Get a container running
- [X] Get the GPU working in the container
- [X] Make it run Roblox
- [X] Discord RPC
- [X] BloxstrapRPC
- [ ] PC-exclusive game support
- [X] Proper mouselocking support* <small>(with caveats)</small>
- [ ] All configuration options from Lucem 2.x
- [ ] New configuration options (possibly like Sober's asset overlay?)

# Known Issues (These will be fixed sooner or later)
- Performance is really bad in certain games (Arsenal, Dead Rails, etc.)
- Graphical artifacting on integrated GPUs
- Mouse locking sometimes does not work
- PC-exclusive games are not playable (Project Remix, Arcane Odyssey, etc.)

# Known Issues (Which are a long-term goal to fix)
- Nvidia support (possibly via VirGL/Venus? Probably requires a custom HAL implementation)
