#include "base.inc"
#if defined(__aarch64__)
#include "abi_arm64.inc"
#elif defined(__x86_64__)
#include "abi_x86_64.inc"
#endif

// asterc1: next-generation compiler entrypoint (LLVM IR backend).
// For now this delegates to the existing minimal asterc0 compiler so we can
// iterate without breaking the driver until asterc1 is bench-complete.

#if defined(__aarch64__)

// int asterc1__compile(u8* src, usize len, FILE* out)
FUNC_BEGIN asterc1__compile
    FRAME_ENTER 0
    bl _asterc0__compile
    FRAME_LEAVE 0
FUNC_END asterc1__compile

#elif defined(__x86_64__)

FUNC_BEGIN asterc1__compile
    FRAME_ENTER 0
    callq _asterc0__compile
    FRAME_LEAVE 0
FUNC_END asterc1__compile

#else
#error "asterc1: unsupported architecture"
#endif

