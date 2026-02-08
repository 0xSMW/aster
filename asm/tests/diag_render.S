#include "base.inc"
#if defined(__aarch64__)
#include "abi_arm64.inc"
#elif defined(__x86_64__)
#include "abi_x86_64.inc"
#endif
#include "span.inc"
#include "diagnostics.inc"
#include "vec.inc"

#if defined(__aarch64__)

.equ OFF_SM, 0
.equ OFF_DIAGS, 32
.equ OFF_SPAN, 64
.equ FRAME_SIZE, 128

.section __TEXT,__const
.p2align 2
path_str:
    .asciz "test.as"
.p2align 2
src_str:
    .asciz "a\nbc\n"
.p2align 2
msg_str:
    .asciz "oops"

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

    add x0, sp, #OFF_DIAGS
    bl _aster_diag__init
    cbnz x0, .Lfail

    add x0, sp, #OFF_SPAN
    mov x1, #0
    mov x2, #2
    mov x3, #3
    bl _aster_span__span_init

    add x0, sp, #OFF_DIAGS
    mov x1, #1
    mov x2, #42
    add x3, sp, #OFF_SPAN
    adrp x4, msg_str@PAGE
    add x4, x4, msg_str@PAGEOFF
    mov x5, #4
    bl _aster_diag__push
    cbnz x0, .Lfail

    add x0, sp, #OFF_DIAGS
    add x1, sp, #OFF_SM
    bl _aster_diag__render
    cbnz x0, .Lfail

    mov w0, #0
    b .Ldone

.Lfail:
    mov w0, #1

.Ldone:
    FRAME_LEAVE FRAME_SIZE
FUNC_END main

#elif defined(__x86_64__)

.equ OFF_SM, 0
.equ OFF_DIAGS, 32
.equ OFF_SPAN, 64
.equ FRAME_SIZE, 128

.section __TEXT,__const
.p2align 2
path_str:
    .asciz "test.as"
.p2align 2
src_str:
    .asciz "a\nbc\n"
.p2align 2
msg_str:
    .asciz "oops"

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

    leaq OFF_DIAGS(%rsp), %rdi
    callq _aster_diag__init
    testq %rax, %rax
    jne .Lfail_x86

    leaq OFF_SPAN(%rsp), %rdi
    movl $0, %esi
    movl $2, %edx
    movl $3, %ecx
    callq _aster_span__span_init

    leaq OFF_DIAGS(%rsp), %rdi
    movl $1, %esi
    movl $42, %edx
    leaq OFF_SPAN(%rsp), %rcx
    leaq msg_str(%rip), %r8
    movq $4, %r9
    callq _aster_diag__push
    testq %rax, %rax
    jne .Lfail_x86

    leaq OFF_DIAGS(%rsp), %rdi
    leaq OFF_SM(%rsp), %rsi
    callq _aster_diag__render
    testq %rax, %rax
    jne .Lfail_x86

    movl $0, %eax
    jmp .Ldone_x86

.Lfail_x86:
    movl $1, %eax

.Ldone_x86:
    FRAME_LEAVE FRAME_SIZE
FUNC_END main

#else
#error "diag_render: unsupported architecture"
#endif

