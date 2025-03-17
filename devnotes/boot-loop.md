# Everything I know about the bootloop problem
The SystemUIBootTiming process keeps segfaulting.
Upon checking its tombstone data, it seems like it has occupied some memory from gralloc. I have a sneaking suspicion that the fallback Android gralloc HAL is shitting itself.

# Fix
IT WAS MESA. IT WAS FUCKING MESA.

If you rename expose `/dev/dri/renderD129` as `/dev/dri/renderD128` to the container, Mesa shits itself and you're downgraded to LLVMPipe, and that causes the entire graphics stack to shit itself, hence the bootloops.
