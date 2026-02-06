#include "base.inc"
#include "abi_arm64.inc"

#if defined(__aarch64__)

.equ N_ELEMS, 5000000
.equ REPS, 3

.section __TEXT,__const
.p2align 2
fmt_str:
    .asciz "%f\n"

FUNC_BEGIN main
    FRAME_ENTER 96
    // save callee-saved
    stp x19, x20, [sp, #0]
    stp x21, x22, [sp, #16]
    stp x23, x24, [sp, #32]

    movz x19, #0x4B40
    movk x19, #0x004C, lsl #16
    mov w20, #REPS

    // allocate arrays
    mov x0, x19
    lsl x0, x0, #3
    bl _malloc
    cbz x0, .Lalloc_fail
    mov x21, x0

    mov x0, x19
    lsl x0, x0, #3
    bl _malloc
    cbz x0, .Lalloc_fail
    mov x22, x0

    // fill arrays (vectorized)
    fmov d0, #1.0
    fmov d1, #2.0
    dup v0.2d, v0.d[0]
    dup v1.2d, v1.d[0]
    mov x9, x21
    mov x10, x22
    bic x23, x19, #7
    cbz x23, .Lfill_scalar
    add x11, x21, x23, lsl #3
.Lfill_vec:
    cmp x9, x11
    b.hs .Lfill_vec_done
    st1 {v0.2d}, [x9], #16
    st1 {v0.2d}, [x9], #16
    st1 {v0.2d}, [x9], #16
    st1 {v0.2d}, [x9], #16
    st1 {v1.2d}, [x10], #16
    st1 {v1.2d}, [x10], #16
    st1 {v1.2d}, [x10], #16
    st1 {v1.2d}, [x10], #16
    b .Lfill_vec
.Lfill_vec_done:
.Lfill_scalar:
    sub x12, x19, x23
    cbz x12, .Lfill_done
.Lfill_scalar_loop:
    str d0, [x9], #8
    str d1, [x10], #8
    subs x12, x12, #1
    b.ne .Lfill_scalar_loop
.Lfill_done:

    mov x24, #0
    fmov d2, #0.0
.Lreps_loop:
    cmp x24, x20
    b.hs .Lreps_done

    // vectorized dot
    fmov d2, xzr
    eor v20.16b, v20.16b, v20.16b
    eor v21.16b, v21.16b, v21.16b
    eor v22.16b, v22.16b, v22.16b
    eor v23.16b, v23.16b, v23.16b

    mov x9, x21
    mov x10, x22
    bic x23, x19, #7
    cbz x23, .Ldot_scalar
    add x11, x21, x23, lsl #3

.Ldot_vec:
    cmp x9, x11
    b.hs .Ldot_vec_done
    prfm pldl1keep, [x9, #256]
    prfm pldl1keep, [x10, #256]
    ld1 {v0.2d, v1.2d, v2.2d, v3.2d}, [x9], #64
    ld1 {v4.2d, v5.2d, v6.2d, v7.2d}, [x10], #64
    fmla v20.2d, v0.2d, v4.2d
    fmla v21.2d, v1.2d, v5.2d
    fmla v22.2d, v2.2d, v6.2d
    fmla v23.2d, v3.2d, v7.2d
    b .Ldot_vec

.Ldot_vec_done:
    fadd v20.2d, v20.2d, v21.2d
    fadd v22.2d, v22.2d, v23.2d
    fadd v20.2d, v20.2d, v22.2d
    faddp d2, v20.2d

.Ldot_scalar:
    sub x12, x19, x23
    cbz x12, .Ldot_done
.Ldot_scalar_loop:
    ldr d3, [x9], #8
    ldr d4, [x10], #8
    fmadd d2, d3, d4, d2
    subs x12, x12, #1
    b.ne .Ldot_scalar_loop

.Ldot_done:
    add x24, x24, #1
    b .Lreps_loop

.Lreps_done:
    // print sum
    adrp x0, fmt_str@PAGE
    add x0, x0, fmt_str@PAGEOFF
    fmov d0, d2
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
    FRAME_LEAVE 96
FUNC_END main

#else
#error "aster dot: unsupported architecture"
#endif
