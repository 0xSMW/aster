#include "base.inc"
#include "abi_arm64.inc"

#if defined(__aarch64__)

.equ N, 200000

.section __TEXT,__const
.p2align 3
lcg_a:
    .quad 6364136223846793005
lcg_c:
    .quad 1
.p2align 2
fmt_str:
    .asciz "%llu\n"

FUNC_BEGIN cmp_u64
    ldr x2, [x0]
    ldr x3, [x1]
    cmp x2, x3
    cset w4, gt
    cset w5, lt
    sub w0, w4, w5
    ret
FUNC_END cmp_u64

FUNC_BEGIN main
    FRAME_ENTER 96
    stp x19, x20, [sp, #0]
    stp x21, x22, [sp, #16]
    stp x23, x24, [sp, #32]

    movz x19, #(N & 0xFFFF)
    movk x19, #((N >> 16) & 0xFFFF), lsl #16
    lsl x0, x19, #3
    bl _malloc
    cbz x0, .Lalloc_fail
    mov x21, x0

    adrp x9, lcg_a@PAGE
    ldr x22, [x9, lcg_a@PAGEOFF]
    ldr x23, [x9, lcg_c@PAGEOFF]

    mov x24, #1
    mov x20, #0
.Lfill:
    cmp x20, x19
    b.hs .Lfill_done
    mul x24, x24, x22
    add x24, x24, x23
    str x24, [x21, x20, lsl #3]
    add x20, x20, #1
    b .Lfill
.Lfill_done:

    mov x0, x21
    mov x1, x19
    mov x2, #8
    adrp x3, _cmp_u64@PAGE
    add x3, x3, _cmp_u64@PAGEOFF
    bl _qsort

    adrp x0, fmt_str@PAGE
    add x0, x0, fmt_str@PAGEOFF
    ldr x1, [x21]
    bl _printf

    mov x0, x21
    bl _free

    mov w0, #0
    b .Ldone

.Lalloc_fail:
    mov w0, #1

.Ldone:
    ldp x19, x20, [sp, #0]
    ldp x21, x22, [sp, #16]
    ldp x23, x24, [sp, #32]
    FRAME_LEAVE 96
FUNC_END main

#else
#error "aster sort: unsupported architecture"
#endif
