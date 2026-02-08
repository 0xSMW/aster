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
    .asciz "'a'\n"

#if defined(__aarch64__)

FUNC_BEGIN main
    FRAME_ENTER FRAME_SIZE

    adrp x1, src_str@PAGE
    add x1, x1, src_str@PAGEOFF
    mov x2, #4
    add x0, sp, #OFF_LEX
    bl _aster_lex__init

    add x0, sp, #OFF_LEX
    add x1, sp, #OFF_TOK
    bl _aster_lex__next
    cmp x0, #TOK_CHAR
    b.ne .Lfail1
    ldr w3, [sp, #OFF_TOK + TOK_START]
    ldr w4, [sp, #OFF_TOK + TOK_END]
    cmp w3, #0
    b.ne .Lfail2
    cmp w4, #3
    b.ne .Lfail3

    mov w0, #0
    b .Ldone

.Lfail1: mov w0, #1; b .Ldone
.Lfail2: mov w0, #2; b .Ldone
.Lfail3: mov w0, #3

.Ldone:
    FRAME_LEAVE FRAME_SIZE
FUNC_END main

#elif defined(__x86_64__)

FUNC_BEGIN main
    FRAME_ENTER FRAME_SIZE

    leaq src_str(%rip), %rsi
    movq $4, %rdx
    leaq OFF_LEX(%rsp), %rdi
    callq _aster_lex__init

    leaq OFF_LEX(%rsp), %rdi
    leaq OFF_TOK(%rsp), %rsi
    callq _aster_lex__next
    cmpq $TOK_CHAR, %rax
    jne .Lfail1
    movl OFF_TOK + TOK_START(%rsp), %ecx
    movl OFF_TOK + TOK_END(%rsp), %edx
    cmpl $0, %ecx
    jne .Lfail2
    cmpl $3, %edx
    jne .Lfail3

    movl $0, %eax
    jmp .Ldone

.Lfail1: movl $1, %eax; jmp .Ldone
.Lfail2: movl $2, %eax; jmp .Ldone
.Lfail3: movl $3, %eax

.Ldone:
    FRAME_LEAVE FRAME_SIZE
FUNC_END main

#else
#error "lexer_char: unsupported architecture"
#endif

