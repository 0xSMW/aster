#ifndef ASTER_ABI_ARM64_INC
#define ASTER_ABI_ARM64_INC

.macro ABI_ARM64_REGS
ARG0 .req x0
ARG1 .req x1
ARG2 .req x2
ARG3 .req x3
ARG4 .req x4
ARG5 .req x5
ARG6 .req x6
ARG7 .req x7
RET0 .req x0
TMP0 .req x9
TMP1 .req x10
FP .req x29
LR .req x30
.endm

.macro ABI_ARM64_UNREGS
.unreq ARG0
.unreq ARG1
.unreq ARG2
.unreq ARG3
.unreq ARG4
.unreq ARG5
.unreq ARG6
.unreq ARG7
.unreq RET0
.unreq TMP0
.unreq TMP1
.unreq FP
.unreq LR
.endm

.macro FRAME_ENTER locals=0
    stp x29, x30, [sp, -16]!
    mov x29, sp
    .if \locals > 0
    sub sp, sp, \locals
    .endif
.endm

.macro FRAME_LEAVE locals=0
    .if \locals > 0
    add sp, sp, \locals
    .endif
    ldp x29, x30, [sp], 16
    ret
.endm

.macro CALL name
    bl _\name
.endm

.macro RET
    ret
.endm

#endif
