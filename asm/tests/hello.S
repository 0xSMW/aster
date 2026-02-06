#include "base.inc"

#if defined(__aarch64__)
#include "abi_arm64.inc"
ABI_ARM64_REGS

FUNC_BEGIN main
    mov w0, #0
    ret
FUNC_END main

ABI_ARM64_UNREGS
#elif defined(__x86_64__)
#include "abi_x86_64.inc"

FUNC_BEGIN main
    xorl %eax, %eax
    ret
FUNC_END main
#else
#error "Unsupported architecture"
#endif
