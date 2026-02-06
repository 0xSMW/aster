#include "base.inc"
#if defined(__aarch64__)
#include "abi_arm64.inc"
#elif defined(__x86_64__)
#include "abi_x86_64.inc"
#endif
#include "lexer.inc"

.equ OFF_LEX, 0
.equ OFF_TOK, 576
.equ FRAME_SIZE, 640

.section __TEXT,__const
.p2align 2
src_str:
    .asciz "10\t32"

#if defined(__aarch64__)

FUNC_BEGIN main
    FRAME_ENTER FRAME_SIZE

    adrp x1, src_str@PAGE
    add x1, x1, src_str@PAGEOFF
    mov x2, #5
    add x0, sp, #OFF_LEX
    bl _aster_lex__init

    add x0, sp, #OFF_LEX
    add x1, sp, #OFF_TOK
    bl _aster_lex__next
    cmp x0, #TOK_INT
    b.ne .Lfail1
    ldr w3, [sp, #OFF_TOK + TOK_START]
    ldr w4, [sp, #OFF_TOK + TOK_END]
    cmp w3, #0
    b.ne .Lfail2
    cmp w4, #2
    b.ne .Lfail3

    add x0, sp, #OFF_LEX
    add x1, sp, #OFF_TOK
    bl _aster_lex__next
    cmp x0, #TOK_INT
    b.ne .Lfail4
    ldr w3, [sp, #OFF_TOK + TOK_START]
    ldr w4, [sp, #OFF_TOK + TOK_END]
    cmp w3, #3
    b.ne .Lfail5
    cmp w4, #5
    b.ne .Lfail6

    mov w0, #0
    b .Ldone

.Lfail1: mov w0, #1; b .Ldone
.Lfail2: mov w0, #2; b .Ldone
.Lfail3: mov w0, #3; b .Ldone
.Lfail4: mov w0, #4; b .Ldone
.Lfail5: mov w0, #5; b .Ldone
.Lfail6: mov w0, #6

.Ldone:
    FRAME_LEAVE FRAME_SIZE
FUNC_END main

#elif defined(__x86_64__)

FUNC_BEGIN main
    FRAME_ENTER FRAME_SIZE

    leaq src_str(%rip), %rsi
    movq $5, %rdx
    leaq OFF_LEX(%rsp), %rdi
    callq _aster_lex__init

    leaq OFF_LEX(%rsp), %rdi
    leaq OFF_TOK(%rsp), %rsi
    callq _aster_lex__next
    cmpq $TOK_INT, %rax
    jne .Lfail1
    movl OFF_TOK + TOK_START(%rsp), %ecx
    movl OFF_TOK + TOK_END(%rsp), %edx
    cmpl $0, %ecx
    jne .Lfail2
    cmpl $2, %edx
    jne .Lfail3

    leaq OFF_LEX(%rsp), %rdi
    leaq OFF_TOK(%rsp), %rsi
    callq _aster_lex__next
    cmpq $TOK_INT, %rax
    jne .Lfail4
    movl OFF_TOK + TOK_START(%rsp), %ecx
    movl OFF_TOK + TOK_END(%rsp), %edx
    cmpl $3, %ecx
    jne .Lfail5
    cmpl $5, %edx
    jne .Lfail6

    movl $0, %eax
    jmp .Ldone

.Lfail1: movl $1, %eax; jmp .Ldone
.Lfail2: movl $2, %eax; jmp .Ldone
.Lfail3: movl $3, %eax; jmp .Ldone
.Lfail4: movl $4, %eax; jmp .Ldone
.Lfail5: movl $5, %eax; jmp .Ldone
.Lfail6: movl $6, %eax

.Ldone:
    FRAME_LEAVE FRAME_SIZE
FUNC_END main

#else
#error "lexer_nums: unsupported architecture"
#endif
