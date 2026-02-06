#include "base.inc"
#include "abi_arm64.inc"

#if defined(__aarch64__)

.equ N, 128
.equ REPS, 2

.section __TEXT,__const
.p2align 2
fmt_str:
    .asciz "%f\n"

FUNC_BEGIN main
    FRAME_ENTER 128
    stp x19, x20, [sp, #0]
    stp x21, x22, [sp, #16]
    stp x23, x24, [sp, #32]
    stp x25, x26, [sp, #48]
    stp x27, x28, [sp, #64]

    mov x19, #N
    mov x20, #REPS
    mul x24, x19, x19
    lsl x25, x24, #3

    mov x0, x25
    bl _malloc
    cbz x0, .Lalloc_fail
    mov x21, x0

    mov x0, x25
    bl _malloc
    cbz x0, .Lalloc_fail
    mov x22, x0

    mov x0, x25
    bl _malloc
    cbz x0, .Lalloc_fail
    mov x23, x0

    fmov d0, #1.0
    fmov d1, #2.0
    fmov d2, xzr
    mov x26, #0
.Lfill_loop:
    cmp x26, x24
    b.hs .Lfill_done
    str d0, [x21, x26, lsl #3]
    str d1, [x22, x26, lsl #3]
    str d2, [x23, x26, lsl #3]
    add x26, x26, #1
    b .Lfill_loop
.Lfill_done:

    mov x28, #0
.Lrep_loop:
    cmp x28, x20
    b.hs .Lrep_done

    // zero C
    mov x26, #0
.Lzero_loop:
    cmp x26, x24
    b.hs .Lzero_done
    str d2, [x23, x26, lsl #3]
    add x26, x26, #1
    b .Lzero_loop
.Lzero_done:

    mov x26, #0 // i
.Li_loop:
    cmp x26, x19
    b.hs .Lrep_next

    mul x27, x26, x19
    lsl x27, x27, #3
    add x9, x21, x27  // a_row
    add x10, x23, x27 // c_row

    mov x11, #0 // k
.Lk_loop:
    cmp x11, x19
    b.hs .Li_next

    ldr d3, [x9, x11, lsl #3]
    dup v4.2d, v3.d[0]
    mul x12, x11, x19
    lsl x12, x12, #3
    add x13, x22, x12 // b_row

    mov x14, #0 // j
.Lj_loop:
    cmp x14, x19
    b.hs .Lk_next

    lsl x15, x14, #3
    add x16, x10, x15
    add x17, x13, x15
    ldr q0, [x16]
    ldr q1, [x16, #16]
    ldr q2, [x17]
    ldr q3, [x17, #16]
    fmla v0.2d, v2.2d, v4.2d
    fmla v1.2d, v3.2d, v4.2d
    str q0, [x16]
    str q1, [x16, #16]
    add x14, x14, #4
    b .Lj_loop

.Lk_next:
    add x11, x11, #1
    b .Lk_loop

.Li_next:
    add x26, x26, #1
    b .Li_loop

.Lrep_next:
    add x28, x28, #1
    b .Lrep_loop

.Lrep_done:
    adrp x0, fmt_str@PAGE
    add x0, x0, fmt_str@PAGEOFF
    ldr d0, [x23]
    bl _printf

    mov x0, x21
    bl _free
    mov x0, x22
    bl _free
    mov x0, x23
    bl _free

    mov w0, #0
    b .Ldone

.Lalloc_fail:
    mov w0, #1

.Ldone:
    ldp x19, x20, [sp, #0]
    ldp x21, x22, [sp, #16]
    ldp x23, x24, [sp, #32]
    ldp x25, x26, [sp, #48]
    ldp x27, x28, [sp, #64]
    FRAME_LEAVE 128
FUNC_END main

#else
#error "aster gemm: unsupported architecture"
#endif
