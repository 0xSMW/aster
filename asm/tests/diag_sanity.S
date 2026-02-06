#include "base.inc"
#include "abi_arm64.inc"
#include "span.inc"
#include "diagnostics.inc"
#include "vec.inc"

#if defined(__aarch64__)

.equ OFF_DIAGS, 0
.equ OFF_SPAN, 32
.equ FRAME_SIZE, 96

.section __TEXT,__const
.p2align 2
msg_str:
    .asciz "oops"

FUNC_BEGIN main
    FRAME_ENTER FRAME_SIZE

    add x0, sp, #OFF_DIAGS
    bl _aster_diag__init
    cbnz x0, .Lfail

    add x0, sp, #OFF_SPAN
    mov x1, #1
    mov x2, #10
    mov x3, #20
    bl _aster_span__span_init

    add x0, sp, #OFF_DIAGS
    mov x1, #1
    mov x2, #100
    add x3, sp, #OFF_SPAN
    adrp x4, msg_str@PAGE
    add x4, x4, msg_str@PAGEOFF
    mov x5, #4
    bl _aster_diag__push
    cbnz x0, .Lfail

    add x0, sp, #OFF_DIAGS
    bl _aster_diag__count
    cmp x0, #1
    b.ne .Lfail

    mov w0, #0
    b .Ldone

.Lfail:
    mov w0, #1

.Ldone:
    FRAME_LEAVE FRAME_SIZE
FUNC_END main

#else
#error "diag_sanity: unsupported architecture"
#endif
