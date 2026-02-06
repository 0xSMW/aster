#include "base.inc"
#include "abi_arm64.inc"
#include "span.inc"
#include "vec.inc"

#if defined(__aarch64__)

.equ OFF_SM, 0
.equ OFF_LINE, 32
.equ OFF_COL, 40
.equ FRAME_SIZE, 64

.section __TEXT,__const
.p2align 2
path_str:
    .asciz "test.as"
.p2align 2
src_str:
    .asciz "a\nbc\n"

FUNC_BEGIN main
    FRAME_ENTER FRAME_SIZE

    add x0, sp, #OFF_SM
    bl _aster_span__sourcemap_init
    cbnz x0, .Lfail

    add x0, sp, #OFF_SM
    adrp x1, path_str@PAGE
    add x1, x1, path_str@PAGEOFF
    mov x2, #7
    adrp x3, src_str@PAGE
    add x3, x3, src_str@PAGEOFF
    mov x4, #5
    bl _aster_span__sourcemap_add
    cmp x0, #0
    b.ne .Lfail

    add x0, sp, #OFF_SM
    mov x1, #0
    mov x2, #2
    add x3, sp, #OFF_LINE
    add x4, sp, #OFF_COL
    bl _aster_span__sourcemap_line_col
    cbnz x0, .Lfail

    ldr x5, [sp, #OFF_LINE]
    ldr x6, [sp, #OFF_COL]
    cmp x5, #2
    b.ne .Lfail
    cmp x6, #1
    b.ne .Lfail

    mov w0, #0
    b .Ldone

.Lfail:
    mov w0, #1

.Ldone:
    FRAME_LEAVE FRAME_SIZE
FUNC_END main

#else
#error "span_sanity: unsupported architecture"
#endif
