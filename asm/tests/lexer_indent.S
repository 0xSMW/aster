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
    .asciz "a\n    b\nc\n"

#if defined(__aarch64__)

FUNC_BEGIN main
    FRAME_ENTER FRAME_SIZE

    adrp x1, src_str@PAGE
    add x1, x1, src_str@PAGEOFF
    mov x2, #10
    add x0, sp, #OFF_LEX
    bl _aster_lex__init

    add x0, sp, #OFF_LEX
    add x1, sp, #OFF_TOK
    bl _aster_lex__next
    cmp x0, #TOK_IDENT
    b.ne .Lfail1

    add x0, sp, #OFF_LEX
    add x1, sp, #OFF_TOK
    bl _aster_lex__next
    cmp x0, #TOK_NEWLINE
    b.ne .Lfail2

    add x0, sp, #OFF_LEX
    add x1, sp, #OFF_TOK
    bl _aster_lex__next
    cmp x0, #TOK_INDENT
    b.ne .Lfail3

    add x0, sp, #OFF_LEX
    add x1, sp, #OFF_TOK
    bl _aster_lex__next
    cmp x0, #TOK_IDENT
    b.ne .Lfail4

    add x0, sp, #OFF_LEX
    add x1, sp, #OFF_TOK
    bl _aster_lex__next
    cmp x0, #TOK_NEWLINE
    b.ne .Lfail5

    add x0, sp, #OFF_LEX
    add x1, sp, #OFF_TOK
    bl _aster_lex__next
    cmp x0, #TOK_DEDENT
    b.ne .Lfail6

    add x0, sp, #OFF_LEX
    add x1, sp, #OFF_TOK
    bl _aster_lex__next
    cmp x0, #TOK_IDENT
    b.ne .Lfail7

    add x0, sp, #OFF_LEX
    add x1, sp, #OFF_TOK
    bl _aster_lex__next
    cmp x0, #TOK_NEWLINE
    b.ne .Lfail8

    add x0, sp, #OFF_LEX
    add x1, sp, #OFF_TOK
    bl _aster_lex__next
    cmp x0, #TOK_EOF
    b.ne .Lfail9

    mov w0, #0
    b .Ldone

.Lfail1: mov w0, #1; b .Ldone
.Lfail2: mov w0, #2; b .Ldone
.Lfail3: mov w0, #3; b .Ldone
.Lfail4: mov w0, #4; b .Ldone
.Lfail5: mov w0, #5; b .Ldone
.Lfail6: mov w0, #6; b .Ldone
.Lfail7: mov w0, #7; b .Ldone
.Lfail8: mov w0, #8; b .Ldone
.Lfail9: mov w0, #9

.Ldone:
    FRAME_LEAVE FRAME_SIZE
FUNC_END main

#elif defined(__x86_64__)

FUNC_BEGIN main
    FRAME_ENTER FRAME_SIZE

    leaq src_str(%rip), %rsi
    movq $10, %rdx
    leaq OFF_LEX(%rsp), %rdi
    callq _aster_lex__init

    leaq OFF_LEX(%rsp), %rdi
    leaq OFF_TOK(%rsp), %rsi
    callq _aster_lex__next
    cmpq $TOK_IDENT, %rax
    jne .Lfail1

    leaq OFF_LEX(%rsp), %rdi
    leaq OFF_TOK(%rsp), %rsi
    callq _aster_lex__next
    cmpq $TOK_NEWLINE, %rax
    jne .Lfail2

    leaq OFF_LEX(%rsp), %rdi
    leaq OFF_TOK(%rsp), %rsi
    callq _aster_lex__next
    cmpq $TOK_INDENT, %rax
    jne .Lfail3

    leaq OFF_LEX(%rsp), %rdi
    leaq OFF_TOK(%rsp), %rsi
    callq _aster_lex__next
    cmpq $TOK_IDENT, %rax
    jne .Lfail4

    leaq OFF_LEX(%rsp), %rdi
    leaq OFF_TOK(%rsp), %rsi
    callq _aster_lex__next
    cmpq $TOK_NEWLINE, %rax
    jne .Lfail5

    leaq OFF_LEX(%rsp), %rdi
    leaq OFF_TOK(%rsp), %rsi
    callq _aster_lex__next
    cmpq $TOK_DEDENT, %rax
    jne .Lfail6

    leaq OFF_LEX(%rsp), %rdi
    leaq OFF_TOK(%rsp), %rsi
    callq _aster_lex__next
    cmpq $TOK_IDENT, %rax
    jne .Lfail7

    leaq OFF_LEX(%rsp), %rdi
    leaq OFF_TOK(%rsp), %rsi
    callq _aster_lex__next
    cmpq $TOK_NEWLINE, %rax
    jne .Lfail8

    leaq OFF_LEX(%rsp), %rdi
    leaq OFF_TOK(%rsp), %rsi
    callq _aster_lex__next
    cmpq $TOK_EOF, %rax
    jne .Lfail9

    movl $0, %eax
    jmp .Ldone

.Lfail1: movl $1, %eax; jmp .Ldone
.Lfail2: movl $2, %eax; jmp .Ldone
.Lfail3: movl $3, %eax; jmp .Ldone
.Lfail4: movl $4, %eax; jmp .Ldone
.Lfail5: movl $5, %eax; jmp .Ldone
.Lfail6: movl $6, %eax; jmp .Ldone
.Lfail7: movl $7, %eax; jmp .Ldone
.Lfail8: movl $8, %eax; jmp .Ldone
.Lfail9: movl $9, %eax

.Ldone:
    FRAME_LEAVE FRAME_SIZE
FUNC_END main

#else
#error "lexer_indent: unsupported architecture"
#endif
