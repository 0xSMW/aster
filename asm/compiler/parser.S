#include "base.inc"
#if defined(__aarch64__)
#include "abi_arm64.inc"
#elif defined(__x86_64__)
#include "abi_x86_64.inc"
#endif
#include "lexer.inc"

#if defined(__aarch64__)

FUNC_BEGIN aster_parse__sum_two_ints
    FRAME_ENTER 0
    mov x2, #0

    // parse first int
    mov x3, x0
    mov x4, x1
    bl .Lparse_one
    cbz x0, .Lparse_fail
    mov x5, x0

    // parse second int
    mov x0, x3
    mov x1, x4
    bl .Lparse_one
    cbz x0, .Lparse_fail
    add x0, x5, x0
    b .Lparse_done

.Lparse_fail:
    mov x0, #0

.Lparse_done:
    FRAME_LEAVE 0
FUNC_END aster_parse__sum_two_ints

// Expression parser: supports +, -, *, /, and parentheses on integer literals.
.equ PARSE_OFF_LEX, 0
.equ PARSE_OFF_TOK, 576
.equ PARSE_OFF_SRC, 592
.equ PARSE_OFF_LEN, 600
.equ PARSE_OFF_OK, 608
.equ PARSE_FRAME_SIZE, 672

FUNC_BEGIN aster_parse__eval_expr
    FRAME_ENTER PARSE_FRAME_SIZE

    str x0, [sp, #PARSE_OFF_SRC]
    str x1, [sp, #PARSE_OFF_LEN]
    mov x2, #1
    str x2, [sp, #PARSE_OFF_OK]

    add x0, sp, #PARSE_OFF_LEX
    ldr x1, [sp, #PARSE_OFF_SRC]
    ldr x2, [sp, #PARSE_OFF_LEN]
    bl _aster_lex__init

    mov x0, sp
    bl _aster_parse__eval_expr__next_token
    mov x0, sp
    bl _aster_parse__eval_expr__parse_expr

    ldr x1, [sp, #PARSE_OFF_OK]
    cbz x1, .Lparse_fail_expr
    ldr w2, [sp, #PARSE_OFF_TOK + TOK_KIND]
    cmp w2, #TOK_EOF
    b.ne .Lparse_fail_expr
    b .Lparse_done_expr

.Lparse_fail_expr:
    mov x0, #0
.Lparse_done_expr:
    FRAME_LEAVE PARSE_FRAME_SIZE
FUNC_END aster_parse__eval_expr

// Internal helpers for eval_expr. The old implementation used local labels as
// subroutines; on arm64 `bl` clobbers LR (x30), so nested calls never returned
// and `parser_expr` would hang.

FUNC_BEGIN aster_parse__eval_expr__next_token
    FRAME_ENTER 16
    str x19, [sp, #0]
    mov x19, x0

.Lnext_tok_loop:
    add x0, x19, #PARSE_OFF_LEX
    add x1, x19, #PARSE_OFF_TOK
    bl _aster_lex__next
    ldr w2, [x19, #PARSE_OFF_TOK + TOK_KIND]
    cmp w2, #TOK_NEWLINE
    b.eq .Lnext_tok_loop
    cmp w2, #TOK_INDENT
    b.eq .Lnext_tok_loop
    cmp w2, #TOK_DEDENT
    b.eq .Lnext_tok_loop
    mov w0, w2

    ldr x19, [sp, #0]
    FRAME_LEAVE 16
FUNC_END aster_parse__eval_expr__next_token

FUNC_BEGIN aster_parse__eval_expr__parse_expr
    FRAME_ENTER 32
    str x19, [sp, #0]
    mov x19, x0

    mov x0, x19
    bl _aster_parse__eval_expr__parse_term
    ldr x1, [x19, #PARSE_OFF_OK]
    cbz x1, .Lexpr_ret
    str x0, [sp, #16] // acc

.Lexpr_loop2:
    ldr w2, [x19, #PARSE_OFF_TOK + TOK_KIND]
    cmp w2, #TOK_PLUS
    b.eq .Lexpr_op2
    cmp w2, #TOK_MINUS
    b.ne .Lexpr_done2
.Lexpr_op2:
    str w2, [sp, #24] // op
    mov x0, x19
    bl _aster_parse__eval_expr__next_token
    mov x0, x19
    bl _aster_parse__eval_expr__parse_term
    ldr x1, [x19, #PARSE_OFF_OK]
    cbz x1, .Lexpr_done2
    ldr x3, [sp, #16]
    ldr w2, [sp, #24]
    cmp w2, #TOK_PLUS
    b.eq .Lexpr_add2
    sub x0, x3, x0
    b .Lexpr_store2
.Lexpr_add2:
    add x0, x3, x0
.Lexpr_store2:
    str x0, [sp, #16]
    b .Lexpr_loop2

.Lexpr_done2:
    ldr x0, [sp, #16]
.Lexpr_ret:
    ldr x19, [sp, #0]
    FRAME_LEAVE 32
FUNC_END aster_parse__eval_expr__parse_expr

FUNC_BEGIN aster_parse__eval_expr__parse_term
    FRAME_ENTER 32
    str x19, [sp, #0]
    mov x19, x0

    mov x0, x19
    bl _aster_parse__eval_expr__parse_factor
    ldr x1, [x19, #PARSE_OFF_OK]
    cbz x1, .Lterm_ret
    str x0, [sp, #16] // acc

.Lterm_loop2:
    ldr w2, [x19, #PARSE_OFF_TOK + TOK_KIND]
    cmp w2, #TOK_STAR
    b.eq .Lterm_op2
    cmp w2, #TOK_SLASH
    b.ne .Lterm_done2
.Lterm_op2:
    str w2, [sp, #24] // op
    mov x0, x19
    bl _aster_parse__eval_expr__next_token
    mov x0, x19
    bl _aster_parse__eval_expr__parse_factor
    ldr x1, [x19, #PARSE_OFF_OK]
    cbz x1, .Lterm_done2
    ldr x3, [sp, #16]
    ldr w2, [sp, #24]
    cmp w2, #TOK_STAR
    b.eq .Lterm_mul2
    sdiv x0, x3, x0
    b .Lterm_store2
.Lterm_mul2:
    mul x0, x3, x0
.Lterm_store2:
    str x0, [sp, #16]
    b .Lterm_loop2

.Lterm_done2:
    ldr x0, [sp, #16]
.Lterm_ret:
    ldr x19, [sp, #0]
    FRAME_LEAVE 32
FUNC_END aster_parse__eval_expr__parse_term

FUNC_BEGIN aster_parse__eval_expr__parse_factor
    FRAME_ENTER 32
    str x19, [sp, #0]
    mov x19, x0

    ldr w2, [x19, #PARSE_OFF_TOK + TOK_KIND]
    cmp w2, #TOK_INT
    b.eq .Lfactor_int2
    cmp w2, #TOK_LPAREN
    b.eq .Lfactor_lparen2
    mov x0, #0
    mov x1, #0
    str x1, [x19, #PARSE_OFF_OK]
    b .Lfactor_ret2

.Lfactor_int2:
    ldr w3, [x19, #PARSE_OFF_TOK + TOK_START]
    ldr w4, [x19, #PARSE_OFF_TOK + TOK_END]
    ldr x5, [x19, #PARSE_OFF_SRC]
    uxtw x3, w3
    uxtw x4, w4
    add x5, x5, x3
    sub x4, x4, x3
    mov x6, #0
    mov x7, #0
.Lint_loop2:
    cmp x7, x4
    b.hs .Lint_done2
    ldrb w8, [x5, x7]
    sub w8, w8, #'0'
    mov x9, #10
    mul x6, x6, x9
    add x6, x6, x8
    add x7, x7, #1
    b .Lint_loop2
.Lint_done2:
    mov x0, x6
    str x0, [sp, #16]
    // consume INT
    mov x0, x19
    bl _aster_parse__eval_expr__next_token
    ldr x0, [sp, #16]
    b .Lfactor_ret2

.Lfactor_lparen2:
    // consume '('
    mov x0, x19
    bl _aster_parse__eval_expr__next_token
    mov x0, x19
    bl _aster_parse__eval_expr__parse_expr
    ldr x1, [x19, #PARSE_OFF_OK]
    cbz x1, .Lfactor_ret2
    ldr w2, [x19, #PARSE_OFF_TOK + TOK_KIND]
    cmp w2, #TOK_RPAREN
    b.ne .Lfactor_fail2
    str x0, [sp, #16]
    // consume ')'
    mov x0, x19
    bl _aster_parse__eval_expr__next_token
    ldr x0, [sp, #16]
    b .Lfactor_ret2

.Lfactor_fail2:
    mov x1, #0
    str x1, [x19, #PARSE_OFF_OK]
    mov x0, #0

.Lfactor_ret2:
    ldr x19, [sp, #0]
    FRAME_LEAVE 32
FUNC_END aster_parse__eval_expr__parse_factor

// x0: src_ptr, x1: src_len, x2: pos (caller-saved)
// returns value in x0, updates x2
.Lparse_one:
    // skip whitespace (space, tab, newline)
.Lskip_ws:
    cmp x2, x1
    b.hs .Lparse_one_fail
    ldrb w6, [x0, x2]
    cmp w6, #32
    b.eq .Lws_advance
    cmp w6, #9
    b.eq .Lws_advance
    cmp w6, #10
    b.eq .Lws_advance
    b .Lparse_digits
.Lws_advance:
    add x2, x2, #1
    b .Lskip_ws

.Lparse_digits:
    cmp w6, #'0'
    b.lo .Lparse_one_fail
    cmp w6, #'9'
    b.hi .Lparse_one_fail
    mov x7, #0
.Ldigit_loop:
    cmp x2, x1
    b.hs .Lparse_one_done
    ldrb w6, [x0, x2]
    cmp w6, #'0'
    b.lo .Lparse_one_done
    cmp w6, #'9'
    b.hi .Lparse_one_done
    sub w6, w6, #'0'
    mov x8, #10
    mul x7, x7, x8
    add x7, x7, x6
    add x2, x2, #1
    b .Ldigit_loop

.Lparse_one_done:
    mov x0, x7
    ret

.Lparse_one_fail:
    mov x0, #0
    ret

#else
#if defined(__x86_64__)

FUNC_BEGIN aster_parse__sum_two_ints
    FRAME_ENTER 0
    xorq %rdx, %rdx

    callq .Lparse_one_x86
    testq %rax, %rax
    je .Lparse_fail_x86
    movq %rax, %r10

    callq .Lparse_one_x86
    testq %rax, %rax
    je .Lparse_fail_x86
    addq %r10, %rax
    jmp .Lparse_done_x86

.Lparse_fail_x86:
    xorq %rax, %rax

.Lparse_done_x86:
    FRAME_LEAVE 0
FUNC_END aster_parse__sum_two_ints

// Expression parser: supports +, -, *, /, and parentheses on integer literals.
.equ PARSE_OFF_LEX, 0
.equ PARSE_OFF_TOK, 576
.equ PARSE_OFF_SRC, 592
.equ PARSE_OFF_LEN, 600
.equ PARSE_OFF_OK, 608
.equ PARSE_OFF_TMP_EXPR, 616
.equ PARSE_OFF_OP_EXPR, 624
.equ PARSE_OFF_TMP_TERM, 632
.equ PARSE_OFF_OP_TERM, 640
.equ PARSE_OFF_TMP_PAREN, 648
.equ PARSE_FRAME_SIZE, 672

FUNC_BEGIN aster_parse__eval_expr
    FRAME_ENTER PARSE_FRAME_SIZE

    movq %rdi, PARSE_OFF_SRC(%rsp)
    movq %rsi, PARSE_OFF_LEN(%rsp)
    movq $1, %rax
    movq %rax, PARSE_OFF_OK(%rsp)

    leaq PARSE_OFF_LEX(%rsp), %rdi
    movq PARSE_OFF_SRC(%rsp), %rsi
    movq PARSE_OFF_LEN(%rsp), %rdx
    callq _aster_lex__init

    callq .Lnext_token_x86
    callq .Lparse_expr_x86

    movq PARSE_OFF_OK(%rsp), %rcx
    testq %rcx, %rcx
    jz .Lparse_fail_expr_x86
    movl PARSE_OFF_TOK + TOK_KIND(%rsp), %edx
    cmpl $TOK_EOF, %edx
    jne .Lparse_fail_expr_x86
    jmp .Lparse_done_expr_x86

.Lparse_fail_expr_x86:
    xorq %rax, %rax
.Lparse_done_expr_x86:
    FRAME_LEAVE PARSE_FRAME_SIZE
FUNC_END aster_parse__eval_expr

.Lnext_token_x86:
    leaq PARSE_OFF_LEX(%rsp), %rdi
    leaq PARSE_OFF_TOK(%rsp), %rsi
    callq _aster_lex__next
    movl PARSE_OFF_TOK + TOK_KIND(%rsp), %edx
    cmpl $TOK_NEWLINE, %edx
    je .Lnext_token_x86
    cmpl $TOK_INDENT, %edx
    je .Lnext_token_x86
    cmpl $TOK_DEDENT, %edx
    je .Lnext_token_x86
    ret

.Lparse_expr_x86:
    callq .Lparse_term_x86
    movq PARSE_OFF_OK(%rsp), %rcx
    testq %rcx, %rcx
    jz .Lparse_expr_done_x86
    movq %rax, PARSE_OFF_TMP_EXPR(%rsp)
.Lexpr_loop_x86:
    movl PARSE_OFF_TOK + TOK_KIND(%rsp), %edx
    cmpl $TOK_PLUS, %edx
    je .Lexpr_op_x86
    cmpl $TOK_MINUS, %edx
    jne .Lexpr_done_x86
.Lexpr_op_x86:
    movl %edx, PARSE_OFF_OP_EXPR(%rsp)
    callq .Lnext_token_x86
    callq .Lparse_term_x86
    movq PARSE_OFF_OK(%rsp), %rcx
    testq %rcx, %rcx
    jz .Lexpr_done_x86
    movq PARSE_OFF_TMP_EXPR(%rsp), %r8
    movl PARSE_OFF_OP_EXPR(%rsp), %edx
    cmpl $TOK_PLUS, %edx
    je .Lexpr_add_x86
    subq %rax, %r8
    movq %r8, %rax
    jmp .Lexpr_store_x86
.Lexpr_add_x86:
    addq %r8, %rax
.Lexpr_store_x86:
    movq %rax, PARSE_OFF_TMP_EXPR(%rsp)
    jmp .Lexpr_loop_x86
.Lexpr_done_x86:
    movq PARSE_OFF_TMP_EXPR(%rsp), %rax
.Lparse_expr_done_x86:
    ret

.Lparse_term_x86:
    callq .Lparse_factor_x86
    movq PARSE_OFF_OK(%rsp), %rcx
    testq %rcx, %rcx
    jz .Lparse_term_done_x86
    movq %rax, PARSE_OFF_TMP_TERM(%rsp)
.Lterm_loop_x86:
    movl PARSE_OFF_TOK + TOK_KIND(%rsp), %edx
    cmpl $TOK_STAR, %edx
    je .Lterm_op_x86
    cmpl $TOK_SLASH, %edx
    jne .Lterm_done_x86
.Lterm_op_x86:
    movl %edx, PARSE_OFF_OP_TERM(%rsp)
    callq .Lnext_token_x86
    callq .Lparse_factor_x86
    movq PARSE_OFF_OK(%rsp), %rcx
    testq %rcx, %rcx
    jz .Lterm_done_x86
    movq PARSE_OFF_TMP_TERM(%rsp), %r8
    movl PARSE_OFF_OP_TERM(%rsp), %edx
    cmpl $TOK_STAR, %edx
    je .Lterm_mul_x86
    movq %rax, %r9
    movq %r8, %rax
    cqto
    idivq %r9
    jmp .Lterm_store_x86
.Lterm_mul_x86:
    imulq %r8, %rax
.Lterm_store_x86:
    movq %rax, PARSE_OFF_TMP_TERM(%rsp)
    jmp .Lterm_loop_x86
.Lterm_done_x86:
    movq PARSE_OFF_TMP_TERM(%rsp), %rax
.Lparse_term_done_x86:
    ret

.Lparse_factor_x86:
    movl PARSE_OFF_TOK + TOK_KIND(%rsp), %edx
    cmpl $TOK_INT, %edx
    je .Lfactor_int_x86
    cmpl $TOK_LPAREN, %edx
    je .Lfactor_lparen_x86
    xorq %rax, %rax
    movq $0, PARSE_OFF_OK(%rsp)
    ret

.Lfactor_int_x86:
    movl PARSE_OFF_TOK + TOK_START(%rsp), %edx
    movl PARSE_OFF_TOK + TOK_END(%rsp), %ecx
    movq PARSE_OFF_SRC(%rsp), %r8
    movslq %edx, %r9
    movslq %ecx, %r10
    addq %r9, %r8
    subq %r9, %r10
    xorq %r11, %r11
    xorq %r9, %r9
.Lint_loop_x86:
    cmpq %r10, %r9
    jae .Lint_done_x86
    movzbl (%r8,%r9,1), %eax
    subb $'0', %al
    imulq $10, %r11, %r11
    addq %rax, %r11
    addq $1, %r9
    jmp .Lint_loop_x86
.Lint_done_x86:
    movq %r11, %rax
    callq .Lnext_token_x86
    ret

.Lfactor_lparen_x86:
    callq .Lnext_token_x86
    callq .Lparse_expr_x86
    movq PARSE_OFF_OK(%rsp), %rcx
    testq %rcx, %rcx
    jz .Lfactor_return_x86
    movl PARSE_OFF_TOK + TOK_KIND(%rsp), %edx
    cmpl $TOK_RPAREN, %edx
    jne .Lfactor_fail_x86
    movq %rax, PARSE_OFF_TMP_PAREN(%rsp)
    callq .Lnext_token_x86
    movq PARSE_OFF_TMP_PAREN(%rsp), %rax
    ret

.Lfactor_fail_x86:
    movq $0, PARSE_OFF_OK(%rsp)
    xorq %rax, %rax
.Lfactor_return_x86:
    ret

// rdi: src_ptr, rsi: src_len, rdx: pos (in/out)
.Lparse_one_x86:
.Lskip_ws_x86:
    cmpq %rsi, %rdx
    jae .Lparse_one_fail_x86
    movzbl (%rdi,%rdx,1), %eax
    cmpb $32, %al
    je .Lws_advance_x86
    cmpb $9, %al
    je .Lws_advance_x86
    cmpb $10, %al
    je .Lws_advance_x86
    jmp .Lparse_digits_x86
.Lws_advance_x86:
    addq $1, %rdx
    jmp .Lskip_ws_x86

.Lparse_digits_x86:
    cmpb $'0', %al
    jb .Lparse_one_fail_x86
    cmpb $'9', %al
    ja .Lparse_one_fail_x86
    xorq %r8, %r8
.Ldigit_loop_x86:
    cmpq %rsi, %rdx
    jae .Lparse_one_done_x86
    movzbl (%rdi,%rdx,1), %eax
    cmpb $'0', %al
    jb .Lparse_one_done_x86
    cmpb $'9', %al
    ja .Lparse_one_done_x86
    subb $'0', %al
    imulq $10, %r8, %r8
    addq %rax, %r8
    addq $1, %rdx
    jmp .Ldigit_loop_x86

.Lparse_one_done_x86:
    movq %r8, %rax
    ret

.Lparse_one_fail_x86:
    xorq %rax, %rax
    ret

#else
#error "parser: unsupported architecture"
#endif
#endif
