#ifndef ASTER_BASE_INC
#define ASTER_BASE_INC

.macro SECTION_TEXT
    .text
.endm

.macro SECTION_RODATA
    .section __TEXT,__const
.endm

.macro SECTION_DATA
    .data
.endm

.macro SECTION_BSS
    .bss
.endm

.macro ALIGN_P2 n
    .p2align \n
.endm

.macro STRZ label, text
    SECTION_RODATA
    .p2align 2
\label:
    .asciz "\text"
.endm

.macro FUNC_BEGIN name
    SECTION_TEXT
    .p2align 2
    .globl _\name
_\name:
    .cfi_startproc
.endm

.macro FUNC_END name
    .cfi_endproc
.endm

.macro EXPORT name
    .globl _\name
_\name:
.endm

#endif
