#include "base.inc"
#if defined(__aarch64__)
#include "abi_arm64.inc"
#elif defined(__x86_64__)
#include "abi_x86_64.inc"
#endif
#include "span.inc"
#include "vec.inc"

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

#if defined(__aarch64__)

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

#elif defined(__x86_64__)

FUNC_BEGIN main
    FRAME_ENTER FRAME_SIZE

    leaq OFF_SM(%rsp), %rdi
    callq _aster_span__sourcemap_init
    testq %rax, %rax
    jne .Lfail_x86

    leaq OFF_SM(%rsp), %rdi
    leaq path_str(%rip), %rsi
    movq $7, %rdx
    leaq src_str(%rip), %rcx
    movq $5, %r8
    callq _aster_span__sourcemap_add
    cmpq $0, %rax
    jne .Lfail_x86

    leaq OFF_SM(%rsp), %rdi
    movq $0, %rsi
    movq $2, %rdx
    leaq OFF_LINE(%rsp), %rcx
    leaq OFF_COL(%rsp), %r8
    callq _aster_span__sourcemap_line_col
    testq %rax, %rax
    jne .Lfail_x86

    movq OFF_LINE(%rsp), %r9
    movq OFF_COL(%rsp), %r10
    cmpq $2, %r9
    jne .Lfail_x86
    cmpq $1, %r10
    jne .Lfail_x86

    movl $0, %eax
    jmp .Ldone_x86

.Lfail_x86:
    movl $1, %eax

.Ldone_x86:
    FRAME_LEAVE FRAME_SIZE
FUNC_END main

#else
#error "span_sanity: unsupported architecture"
#endif
