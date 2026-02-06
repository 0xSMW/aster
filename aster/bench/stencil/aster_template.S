#include "base.inc"
#include "abi_arm64.inc"

#if defined(__aarch64__)

.equ W, 512
.equ H, 512
.equ REPS, 3

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

    mov x19, #W
    mov x20, #H
    mov x24, #REPS

    mul x25, x19, x20
    lsl x26, x25, #3

    mov x0, x26
    bl _malloc
    cbz x0, .Lalloc_fail
    mov x21, x0

    mov x0, x26
    bl _malloc
    cbz x0, .Lalloc_fail
    mov x22, x0

    fmov d0, #1.0
    fmov d1, xzr
    mov x23, #0
.Lfill_loop:
    cmp x23, x25
    b.hs .Lfill_done
    str d0, [x21, x23, lsl #3]
    str d1, [x22, x23, lsl #3]
    add x23, x23, #1
    b .Lfill_loop
.Lfill_done:

    fmov d28, #0.5
    fmov d29, #0.125
    dup v28.2d, v28.d[0]
    dup v29.2d, v29.d[0]

    mov x28, #0
.Lrep_loop:
    cmp x28, x24
    b.hs .Lrep_done

    sub x27, x20, #1
    mov x23, #1 // i
.Li_loop:
    cmp x23, x27
    b.hs .Lswap_done

    // base pointers for rows
    mul x14, x23, x19
    lsl x14, x14, #3
    add x9, x21, x14   // row
    add x13, x22, x14  // out row

    sub x15, x23, #1
    mul x15, x15, x19
    lsl x15, x15, #3
    add x11, x21, x15  // row up

    add x16, x23, #1
    mul x16, x16, x19
    lsl x16, x16, #3
    add x12, x21, x16  // row down

    // j loop pointers start at j=1 (vectorized, 2 doubles per iter)
    add x9, x9, #8
    add x11, x11, #8
    add x12, x12, #8
    add x13, x13, #8

    sub x17, x19, #2
    lsr x17, x17, #1 // pair count
.Lj_loop:
    cbz x17, .Lnext_i

    ld1 {v0.2d}, [x9]
    ld1 {v1.2d}, [x11]
    ld1 {v2.2d}, [x12]
    sub x5, x9, #8
    ld1 {v3.2d}, [x5]
    add x5, x9, #8
    ld1 {v4.2d}, [x5]

    fadd v1.2d, v1.2d, v2.2d
    fadd v3.2d, v3.2d, v4.2d
    fadd v1.2d, v1.2d, v3.2d
    fmul v0.2d, v0.2d, v28.2d
    fmul v1.2d, v1.2d, v29.2d
    fadd v0.2d, v0.2d, v1.2d

    st1 {v0.2d}, [x13]

    add x9, x9, #16
    add x11, x11, #16
    add x12, x12, #16
    add x13, x13, #16
    subs x17, x17, #1
    b.ne .Lj_loop

.Lnext_i:
    add x23, x23, #1
    b .Li_loop

.Lswap_done:
    // swap buffers
    mov x9, x21
    mov x21, x22
    mov x22, x9
    add x28, x28, #1
    b .Lrep_loop

.Lrep_done:
    // print one value
    adrp x0, fmt_str@PAGE
    add x0, x0, fmt_str@PAGEOFF
    ldr d0, [x21]
    bl _printf

    mov x0, x21
    bl _free
    mov x0, x22
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
#error "aster stencil: unsupported architecture"
#endif
