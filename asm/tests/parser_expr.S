#include "base.inc"
#if defined(__aarch64__)
#include "abi_arm64.inc"
#elif defined(__x86_64__)
#include "abi_x86_64.inc"
#endif

.section __TEXT,__const
.p2align 2
src_expr1:
    .asciz "1+2*3"
src_expr2:
    .asciz "(1+2)*3"

#if defined(__aarch64__)

FUNC_BEGIN main
    FRAME_ENTER 0

    adrp x0, src_expr1@PAGE
    add x0, x0, src_expr1@PAGEOFF
    mov x1, #5
    bl _aster_parse__eval_expr
    cmp x0, #7
    b.ne .Lfail1

    adrp x0, src_expr2@PAGE
    add x0, x0, src_expr2@PAGEOFF
    mov x1, #7
    bl _aster_parse__eval_expr
    cmp x0, #9
    b.ne .Lfail2

    mov w0, #0
    b .Ldone

.Lfail1:
    mov w0, #1
    b .Ldone
.Lfail2:
    mov w0, #2

.Ldone:
    FRAME_LEAVE 0
FUNC_END main

#elif defined(__x86_64__)

FUNC_BEGIN main
    FRAME_ENTER 0

    leaq src_expr1(%rip), %rdi
    movq $5, %rsi
    callq _aster_parse__eval_expr
    cmpq $7, %rax
    jne .Lfail1

    leaq src_expr2(%rip), %rdi
    movq $7, %rsi
    callq _aster_parse__eval_expr
    cmpq $9, %rax
    jne .Lfail2

    movl $0, %eax
    jmp .Ldone

.Lfail1:
    movl $1, %eax
    jmp .Ldone
.Lfail2:
    movl $2, %eax

.Ldone:
    FRAME_LEAVE 0
FUNC_END main

#else
#error "parser_expr: unsupported architecture"
#endif
