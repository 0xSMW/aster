#include "base.inc"
#if defined(__aarch64__)
#include "abi_arm64.inc"
#elif defined(__x86_64__)
#include "abi_x86_64.inc"
#endif
#include "lexer.inc"

#if defined(__aarch64__)

FUNC_BEGIN aster_lex__init
    FRAME_ENTER 0
    str x1, [x0, #LEX_SRC_PTR]
    str x2, [x0, #LEX_SRC_LEN]
    mov x3, #0
    str x3, [x0, #LEX_POS]
    str x3, [x0, #LEX_INDENT_TOP]
    str x3, [x0, #LEX_PENDING_DEDENT]
    str x3, [x0, #LEX_PENDING_INDENT]
    mov x4, #1
    str x4, [x0, #LEX_AT_LINE_START]
    add x5, x0, #LEX_STACK
    str x3, [x5]
    mov x0, #0
    FRAME_LEAVE 0
FUNC_END aster_lex__init

FUNC_BEGIN aster_lex__next
    FRAME_ENTER 0
    mov x2, x0
    mov x3, x1
    ldr x4, [x2, #LEX_SRC_PTR]
    ldr x5, [x2, #LEX_SRC_LEN]
    ldr x6, [x2, #LEX_POS]

    ldr x7, [x2, #LEX_PENDING_INDENT]
    cbz x7, .Lcheck_dedent
    mov x7, #0
    str x7, [x2, #LEX_PENDING_INDENT]
    str w6, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w8, #TOK_INDENT
    str w8, [x3, #TOK_KIND]
    mov x0, #TOK_INDENT
    FRAME_LEAVE 0

.Lcheck_dedent:
    ldr x7, [x2, #LEX_PENDING_DEDENT]
    cbz x7, .Lmaybe_indent
    sub x7, x7, #1
    str x7, [x2, #LEX_PENDING_DEDENT]
    str w6, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w8, #TOK_DEDENT
    str w8, [x3, #TOK_KIND]
    mov x0, #TOK_DEDENT
    FRAME_LEAVE 0

.Lmaybe_indent:
    ldr x7, [x2, #LEX_AT_LINE_START]
    cbz x7, .Lskip_ws

    cmp x6, x5
    b.hs .Leof

    mov x9, #0
.Lindent_loop:
    cmp x6, x5
    b.hs .Lindent_done
    ldrb w10, [x4, x6]
    cmp w10, #32
    b.ne .Lindent_check_tab
    add x9, x9, #1
    add x6, x6, #1
    b .Lindent_loop
.Lindent_check_tab:
    cmp w10, #9
    b.ne .Lindent_done
    add x6, x6, #1
    str x6, [x2, #LEX_POS]
    str w6, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w11, #TOK_UNKNOWN
    str w11, [x3, #TOK_KIND]
    mov x0, #TOK_UNKNOWN
    FRAME_LEAVE 0

.Lindent_done:
    cmp x6, x5
    b.hs .Leof
    ldrb w10, [x4, x6]
    cmp w10, #10
    b.eq .Lemit_newline_from_indent
    cmp w10, #13
    b.eq .Lemit_newline_from_indent

    ldr x12, [x2, #LEX_INDENT_TOP]
    add x13, x2, #LEX_STACK
    lsl x14, x12, #3
    add x13, x13, x14
    ldr x15, [x13]

    cmp x9, x15
    b.eq .Lindent_equal
    b.hi .Lindent_increase

    mov x16, #0
.Lindent_pop:
    cbz x12, .Lindent_pop_done
    ldr x15, [x13]
    cmp x15, x9
    b.ls .Lindent_pop_done
    sub x12, x12, #1
    add x13, x2, #LEX_STACK
    lsl x14, x12, #3
    add x13, x13, x14
    add x16, x16, #1
    b .Lindent_pop
.Lindent_pop_done:
    ldr x15, [x13]
    cmp x15, x9
    b.eq .Lindent_emit_dedent
    mov w11, #TOK_UNKNOWN
    str w11, [x3, #TOK_KIND]
    str w6, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov x0, #TOK_UNKNOWN
    FRAME_LEAVE 0

.Lindent_emit_dedent:
    str x12, [x2, #LEX_INDENT_TOP]
    str x16, [x2, #LEX_PENDING_DEDENT]
    mov x11, #0
    str x11, [x2, #LEX_AT_LINE_START]
    str x6, [x2, #LEX_POS]
    sub x16, x16, #1
    str x16, [x2, #LEX_PENDING_DEDENT]
    str w6, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w11, #TOK_DEDENT
    str w11, [x3, #TOK_KIND]
    mov x0, #TOK_DEDENT
    FRAME_LEAVE 0

.Lindent_increase:
    add x12, x12, #1
    add x13, x2, #LEX_STACK
    lsl x14, x12, #3
    add x13, x13, x14
    str x9, [x13]
    str x12, [x2, #LEX_INDENT_TOP]
    mov x11, #0
    str x11, [x2, #LEX_PENDING_INDENT]
    mov x11, #0
    str x11, [x2, #LEX_AT_LINE_START]
    str x6, [x2, #LEX_POS]
    str w6, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w11, #TOK_INDENT
    str w11, [x3, #TOK_KIND]
    mov x0, #TOK_INDENT
    FRAME_LEAVE 0

.Lindent_equal:
    mov x11, #0
    str x11, [x2, #LEX_AT_LINE_START]
    str x6, [x2, #LEX_POS]

.Lskip_ws:
    cmp x6, x5
    b.hs .Leof
    ldrb w7, [x4, x6]
    cmp w7, #32
    b.eq .Lws_advance
    cmp w7, #9
    b.eq .Lws_advance
    b .Ltoken_start
.Lws_advance:
    add x6, x6, #1
    b .Lskip_ws

.Ltoken_start:
    mov x8, x6
    cmp w7, #10
    b.eq .Lemit_newline
    cmp w7, #13
    b.eq .Lemit_newline
    cmp w7, #'#'
    b.eq .Lskip_comment

    cmp w7, #'A'
    b.lo .Lcheck_digit
    cmp w7, #'Z'
    b.ls .Llex_ident
    cmp w7, #'a'
    b.lo .Lcheck_digit
    cmp w7, #'z'
    b.ls .Llex_ident
    cmp w7, #'_'
    b.eq .Llex_ident

.Lcheck_digit:
    cmp w7, #'0'
    b.lo .Lcheck_punct
    cmp w7, #'9'
    b.ls .Llex_int
    b .Lcheck_punct

.Lcheck_punct:
    cmp w7, #'('
    b.ne .Lcheck_rparen
    add x6, x6, #1
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_LPAREN
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_LPAREN
    FRAME_LEAVE 0
.Lcheck_rparen:
    cmp w7, #')'
    b.ne .Lcheck_comma
    add x6, x6, #1
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_RPAREN
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_RPAREN
    FRAME_LEAVE 0
.Lcheck_comma:
    cmp w7, #','
    b.ne .Lcheck_plus
    add x6, x6, #1
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_COMMA
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_COMMA
    FRAME_LEAVE 0
.Lcheck_plus:
    cmp w7, #'+'
    b.ne .Lcheck_minus
    add x6, x6, #1
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_PLUS
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_PLUS
    FRAME_LEAVE 0
.Lcheck_minus:
    cmp w7, #'-'
    b.ne .Lcheck_star
    add x6, x6, #1
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_MINUS
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_MINUS
    FRAME_LEAVE 0
.Lcheck_star:
    cmp w7, #'*'
    b.ne .Lcheck_slash
    add x6, x6, #1
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_STAR
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_STAR
    FRAME_LEAVE 0
.Lcheck_slash:
    cmp w7, #'/'
    b.ne .Lcheck_eq
    add x6, x6, #1
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_SLASH
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_SLASH
    FRAME_LEAVE 0
.Lcheck_eq:
    cmp w7, #'='
    b.ne .Lcheck_lt
    add x6, x6, #1
    cmp x6, x5
    b.hs .Lemit_eq
    ldrb w10, [x4, x6]
    cmp w10, #'='
    b.ne .Lemit_eq
    add x6, x6, #1
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_EQEQ
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_EQEQ
    FRAME_LEAVE 0
.Lemit_eq:
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_EQ
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_EQ
    FRAME_LEAVE 0
.Lcheck_lt:
    cmp w7, #'<'
    b.ne .Lcheck_gt
    add x6, x6, #1
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_LT
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_LT
    FRAME_LEAVE 0
.Lcheck_gt:
    cmp w7, #'>'
    b.ne .Lemit_unknown
    add x6, x6, #1
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_GT
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_GT
    FRAME_LEAVE 0

.Llex_ident:
    add x6, x6, #1
.Lident_loop:
    cmp x6, x5
    b.hs .Lident_done
    ldrb w7, [x4, x6]
    cmp w7, #'A'
    b.lo .Lident_check_digit
    cmp w7, #'Z'
    b.ls .Lident_advance
    cmp w7, #'a'
    b.lo .Lident_check_digit
    cmp w7, #'z'
    b.ls .Lident_advance
    cmp w7, #'_'
    b.eq .Lident_advance
.Lident_check_digit:
    cmp w7, #'0'
    b.lo .Lident_done
    cmp w7, #'9'
    b.ls .Lident_advance
    b .Lident_done
.Lident_advance:
    add x6, x6, #1
    b .Lident_loop
.Lident_done:
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    str x6, [x2, #LEX_POS]
    sub x9, x6, x8
    add x16, x4, x8

    // keyword checks
    cmp x9, #2
    b.ne .Lkw_def
    ldrb w10, [x16]
    ldrb w11, [x16, #1]
    cmp w10, #'i'
    b.ne .Lkw_def
    cmp w11, #'f'
    b.ne .Lkw_def
    mov w12, #TOK_KW_IF
    b .Lemit_kw
.Lkw_def:
    cmp x9, #3
    b.ne .Lkw_else
    ldrb w10, [x16]
    ldrb w11, [x16, #1]
    ldrb w12, [x16, #2]
    cmp w10, #'d'
    b.ne .Lkw_else
    cmp w11, #'e'
    b.ne .Lkw_else
    cmp w12, #'f'
    b.ne .Lkw_else
    mov w12, #TOK_KW_DEF
    b .Lemit_kw
.Lkw_else:
    cmp x9, #4
    b.ne .Lkw_while
    ldrb w10, [x16]
    ldrb w11, [x16, #1]
    ldrb w12, [x16, #2]
    ldrb w13, [x16, #3]
    cmp w10, #'e'
    b.ne .Lkw_while
    cmp w11, #'l'
    b.ne .Lkw_while
    cmp w12, #'s'
    b.ne .Lkw_while
    cmp w13, #'e'
    b.ne .Lkw_while
    mov w12, #TOK_KW_ELSE
    b .Lemit_kw
.Lkw_while:
    cmp x9, #5
    b.ne .Lkw_return
    ldrb w10, [x16]
    ldrb w11, [x16, #1]
    ldrb w12, [x16, #2]
    ldrb w13, [x16, #3]
    ldrb w14, [x16, #4]
    cmp w10, #'w'
    b.ne .Lkw_return
    cmp w11, #'h'
    b.ne .Lkw_return
    cmp w12, #'i'
    b.ne .Lkw_return
    cmp w13, #'l'
    b.ne .Lkw_return
    cmp w14, #'e'
    b.ne .Lkw_return
    mov w12, #TOK_KW_WHILE
    b .Lemit_kw
.Lkw_return:
    cmp x9, #6
    b.ne .Lkw_let
    ldrb w10, [x16]
    ldrb w11, [x16, #1]
    ldrb w12, [x16, #2]
    ldrb w13, [x16, #3]
    ldrb w14, [x16, #4]
    ldrb w15, [x16, #5]
    cmp w10, #'r'
    b.ne .Lkw_let
    cmp w11, #'e'
    b.ne .Lkw_let
    cmp w12, #'t'
    b.ne .Lkw_let
    cmp w13, #'u'
    b.ne .Lkw_let
    cmp w14, #'r'
    b.ne .Lkw_let
    cmp w15, #'n'
    b.ne .Lkw_let
    mov w12, #TOK_KW_RETURN
    b .Lemit_kw
.Lkw_let:
    cmp x9, #3
    b.ne .Lkw_var
    ldrb w10, [x16]
    ldrb w11, [x16, #1]
    ldrb w12, [x16, #2]
    cmp w10, #'l'
    b.ne .Lkw_var
    cmp w11, #'e'
    b.ne .Lkw_var
    cmp w12, #'t'
    b.ne .Lkw_var
    mov w12, #TOK_KW_LET
    b .Lemit_kw
.Lkw_var:
    cmp x9, #3
    b.ne .Lkw_const
    ldrb w10, [x16]
    ldrb w11, [x16, #1]
    ldrb w12, [x16, #2]
    cmp w10, #'v'
    b.ne .Lkw_const
    cmp w11, #'a'
    b.ne .Lkw_const
    cmp w12, #'r'
    b.ne .Lkw_const
    mov w12, #TOK_KW_VAR
    b .Lemit_kw
.Lkw_const:
    cmp x9, #5
    b.ne .Lemit_ident
    ldrb w10, [x16]
    ldrb w11, [x16, #1]
    ldrb w12, [x16, #2]
    ldrb w13, [x16, #3]
    ldrb w14, [x16, #4]
    cmp w10, #'c'
    b.ne .Lemit_ident
    cmp w11, #'o'
    b.ne .Lemit_ident
    cmp w12, #'n'
    b.ne .Lemit_ident
    cmp w13, #'s'
    b.ne .Lemit_ident
    cmp w14, #'t'
    b.ne .Lemit_ident
    mov w12, #TOK_KW_CONST
    b .Lemit_kw

.Lemit_ident:
    mov w12, #TOK_IDENT
.Lemit_kw:
    str w12, [x3, #TOK_KIND]
    mov x0, x12
    FRAME_LEAVE 0

.Llex_int:
    add x6, x6, #1
.Lint_loop:
    cmp x6, x5
    b.hs .Lint_done
    ldrb w7, [x4, x6]
    cmp w7, #'0'
    b.lo .Lint_done
    cmp w7, #'9'
    b.hi .Lint_done
    add x6, x6, #1
    b .Lint_loop
.Lint_done:
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_INT
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_INT
    FRAME_LEAVE 0

.Lskip_comment:
    add x6, x6, #1
.Lcomment_loop:
    cmp x6, x5
    b.hs .Leof
    ldrb w7, [x4, x6]
    cmp w7, #10
    b.eq .Lemit_newline
    cmp w7, #13
    b.eq .Lemit_newline
    add x6, x6, #1
    b .Lcomment_loop

.Lemit_newline_from_indent:
    add x6, x6, #1
    b .Lemit_newline_common

.Lemit_newline:
    add x6, x6, #1
.Lemit_newline_common:
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_NEWLINE
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x9, #1
    str x9, [x2, #LEX_AT_LINE_START]
    mov x0, #TOK_NEWLINE
    FRAME_LEAVE 0

.Leof:
    ldr x7, [x2, #LEX_INDENT_TOP]
    cbz x7, .Leof_emit
    str xzr, [x2, #LEX_INDENT_TOP]
    str x7, [x2, #LEX_PENDING_DEDENT]
    sub x7, x7, #1
    str x7, [x2, #LEX_PENDING_DEDENT]
    str w6, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w8, #TOK_DEDENT
    str w8, [x3, #TOK_KIND]
    mov x0, #TOK_DEDENT
    FRAME_LEAVE 0

.Leof_emit:
    str w6, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_EOF
    str w9, [x3, #TOK_KIND]
    mov x0, #TOK_EOF
    FRAME_LEAVE 0

.Lemit_unknown:
    add x6, x6, #1
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_UNKNOWN
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_UNKNOWN
    FRAME_LEAVE 0

FUNC_END aster_lex__next

#else
#if defined(__x86_64__)

FUNC_BEGIN aster_lex__init
    FRAME_ENTER 0
    movq %rsi, LEX_SRC_PTR(%rdi)
    movq %rdx, LEX_SRC_LEN(%rdi)
    xorq %rax, %rax
    movq %rax, LEX_POS(%rdi)
    movq %rax, LEX_INDENT_TOP(%rdi)
    movq %rax, LEX_PENDING_DEDENT(%rdi)
    movq %rax, LEX_PENDING_INDENT(%rdi)
    movq $1, %rcx
    movq %rcx, LEX_AT_LINE_START(%rdi)
    leaq LEX_STACK(%rdi), %rcx
    movq %rax, (%rcx)
    xorq %rax, %rax
    FRAME_LEAVE 0
FUNC_END aster_lex__init

FUNC_BEGIN aster_lex__next
    FRAME_ENTER 0
    movq %rdi, %r8
    movq %rsi, %r9
    movq LEX_SRC_PTR(%r8), %r10
    movq LEX_SRC_LEN(%r8), %r11
    movq LEX_POS(%r8), %rdx

    movq LEX_PENDING_INDENT(%r8), %rcx
    testq %rcx, %rcx
    jz .Lcheck_dedent_x86
    xorq %rcx, %rcx
    movq %rcx, LEX_PENDING_INDENT(%r8)
    movl %edx, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_INDENT, TOK_KIND(%r9)
    movq $TOK_INDENT, %rax
    FRAME_LEAVE 0

.Lcheck_dedent_x86:
    movq LEX_PENDING_DEDENT(%r8), %rcx
    testq %rcx, %rcx
    jz .Lmaybe_indent_x86
    subq $1, %rcx
    movq %rcx, LEX_PENDING_DEDENT(%r8)
    movl %edx, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_DEDENT, TOK_KIND(%r9)
    movq $TOK_DEDENT, %rax
    FRAME_LEAVE 0

.Lmaybe_indent_x86:
    movq LEX_AT_LINE_START(%r8), %rcx
    testq %rcx, %rcx
    jz .Lskip_ws_x86

    cmpq %r11, %rdx
    jae .Leof_x86

    xorq %rsi, %rsi
.Lindent_loop_x86:
    cmpq %r11, %rdx
    jae .Lindent_done_x86
    movzbl (%r10,%rdx,1), %eax
    cmpb $32, %al
    jne .Lindent_check_tab_x86
    addq $1, %rsi
    addq $1, %rdx
    jmp .Lindent_loop_x86
.Lindent_check_tab_x86:
    cmpb $9, %al
    jne .Lindent_done_x86
    addq $1, %rdx
    movq %rdx, LEX_POS(%r8)
    movl %edx, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_UNKNOWN, TOK_KIND(%r9)
    movq $TOK_UNKNOWN, %rax
    FRAME_LEAVE 0

.Lindent_done_x86:
    cmpq %r11, %rdx
    jae .Leof_x86
    movzbl (%r10,%rdx,1), %eax
    cmpb $10, %al
    je .Lemit_newline_from_indent_x86
    cmpb $13, %al
    je .Lemit_newline_from_indent_x86

    movq LEX_INDENT_TOP(%r8), %rcx
    leaq LEX_STACK(%r8), %rdi
    movq %rcx, %rax
    shlq $3, %rax
    addq %rax, %rdi
    movq (%rdi), %rax

    cmpq %rsi, %rax
    je .Lindent_equal_x86
    jb .Lindent_increase_x86

    movq $0, -8(%rbp)
.Lindent_pop_x86:
    testq %rcx, %rcx
    je .Lindent_pop_done_x86
    movq (%rdi), %rax
    cmpq %rsi, %rax
    jbe .Lindent_pop_done_x86
    subq $1, %rcx
    leaq LEX_STACK(%r8), %rdi
    movq %rcx, %rax
    shlq $3, %rax
    addq %rax, %rdi
    movq -8(%rbp), %rax
    addq $1, %rax
    movq %rax, -8(%rbp)
    jmp .Lindent_pop_x86
.Lindent_pop_done_x86:
    movq (%rdi), %rax
    cmpq %rsi, %rax
    je .Lindent_emit_dedent_x86
    movl $TOK_UNKNOWN, TOK_KIND(%r9)
    movl %edx, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movq $TOK_UNKNOWN, %rax
    FRAME_LEAVE 0

.Lindent_emit_dedent_x86:
    movq %rcx, LEX_INDENT_TOP(%r8)
    movq -8(%rbp), %rax
    movq %rax, LEX_PENDING_DEDENT(%r8)
    xorq %rax, %rax
    movq %rax, LEX_AT_LINE_START(%r8)
    movq %rdx, LEX_POS(%r8)
    movq -8(%rbp), %rax
    subq $1, %rax
    movq %rax, LEX_PENDING_DEDENT(%r8)
    movl %edx, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_DEDENT, TOK_KIND(%r9)
    movq $TOK_DEDENT, %rax
    FRAME_LEAVE 0

.Lindent_increase_x86:
    addq $1, %rcx
    leaq LEX_STACK(%r8), %rdi
    movq %rcx, %rax
    shlq $3, %rax
    addq %rax, %rdi
    movq %rsi, (%rdi)
    movq %rcx, LEX_INDENT_TOP(%r8)
    xorq %rax, %rax
    movq %rax, LEX_PENDING_INDENT(%r8)
    xorq %rax, %rax
    movq %rax, LEX_AT_LINE_START(%r8)
    movq %rdx, LEX_POS(%r8)
    movl %edx, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_INDENT, TOK_KIND(%r9)
    movq $TOK_INDENT, %rax
    FRAME_LEAVE 0

.Lindent_equal_x86:
    xorq %rax, %rax
    movq %rax, LEX_AT_LINE_START(%r8)
    movq %rdx, LEX_POS(%r8)

.Lskip_ws_x86:
    cmpq %r11, %rdx
    jae .Leof_x86
    movzbl (%r10,%rdx,1), %eax
    cmpb $32, %al
    je .Lws_advance_x86
    cmpb $9, %al
    je .Lws_advance_x86
    jmp .Ltoken_start_x86
.Lws_advance_x86:
    addq $1, %rdx
    jmp .Lskip_ws_x86

.Ltoken_start_x86:
    movq %rdx, %rsi
    cmpb $10, %al
    je .Lemit_newline_x86
    cmpb $13, %al
    je .Lemit_newline_x86
    cmpb $'#', %al
    je .Lskip_comment_x86

    cmpb $'A', %al
    jb .Lcheck_digit_x86
    cmpb $'Z', %al
    jbe .Llex_ident_x86
    cmpb $'a', %al
    jb .Lcheck_digit_x86
    cmpb $'z', %al
    jbe .Llex_ident_x86
    cmpb $'_', %al
    je .Llex_ident_x86

.Lcheck_digit_x86:
    cmpb $'0', %al
    jb .Lcheck_punct_x86
    cmpb $'9', %al
    jbe .Llex_int_x86
    jmp .Lcheck_punct_x86

.Lcheck_punct_x86:
    cmpb $'(', %al
    jne .Lcheck_rparen_x86
    addq $1, %rdx
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_LPAREN, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_LPAREN, %rax
    FRAME_LEAVE 0
.Lcheck_rparen_x86:
    cmpb $')', %al
    jne .Lcheck_comma_x86
    addq $1, %rdx
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_RPAREN, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_RPAREN, %rax
    FRAME_LEAVE 0
.Lcheck_comma_x86:
    cmpb $',', %al
    jne .Lcheck_plus_x86
    addq $1, %rdx
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_COMMA, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_COMMA, %rax
    FRAME_LEAVE 0
.Lcheck_plus_x86:
    cmpb $'+', %al
    jne .Lcheck_minus_x86
    addq $1, %rdx
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_PLUS, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_PLUS, %rax
    FRAME_LEAVE 0
.Lcheck_minus_x86:
    cmpb $'-', %al
    jne .Lcheck_star_x86
    addq $1, %rdx
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_MINUS, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_MINUS, %rax
    FRAME_LEAVE 0
.Lcheck_star_x86:
    cmpb $'*', %al
    jne .Lcheck_slash_x86
    addq $1, %rdx
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_STAR, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_STAR, %rax
    FRAME_LEAVE 0
.Lcheck_slash_x86:
    cmpb $'/', %al
    jne .Lcheck_eq_x86
    addq $1, %rdx
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_SLASH, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_SLASH, %rax
    FRAME_LEAVE 0
.Lcheck_eq_x86:
    cmpb $'=', %al
    jne .Lcheck_lt_x86
    addq $1, %rdx
    cmpq %r11, %rdx
    jae .Lemit_eq_x86
    movzbl (%r10,%rdx,1), %eax
    cmpb $'=', %al
    jne .Lemit_eq_x86
    addq $1, %rdx
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_EQEQ, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_EQEQ, %rax
    FRAME_LEAVE 0
.Lemit_eq_x86:
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_EQ, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_EQ, %rax
    FRAME_LEAVE 0
.Lcheck_lt_x86:
    cmpb $'<', %al
    jne .Lcheck_gt_x86
    addq $1, %rdx
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_LT, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_LT, %rax
    FRAME_LEAVE 0
.Lcheck_gt_x86:
    cmpb $'>', %al
    jne .Lemit_unknown_x86
    addq $1, %rdx
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_GT, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_GT, %rax
    FRAME_LEAVE 0

.Llex_ident_x86:
    addq $1, %rdx
.Lident_loop_x86:
    cmpq %r11, %rdx
    jae .Lident_done_x86
    movzbl (%r10,%rdx,1), %eax
    cmpb $'A', %al
    jb .Lident_check_digit_x86
    cmpb $'Z', %al
    jbe .Lident_advance_x86
    cmpb $'a', %al
    jb .Lident_check_digit_x86
    cmpb $'z', %al
    jbe .Lident_advance_x86
    cmpb $'_', %al
    je .Lident_advance_x86
.Lident_check_digit_x86:
    cmpb $'0', %al
    jb .Lident_done_x86
    cmpb $'9', %al
    jbe .Lident_advance_x86
    jmp .Lident_done_x86
.Lident_advance_x86:
    addq $1, %rdx
    jmp .Lident_loop_x86
.Lident_done_x86:
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movq %rdx, LEX_POS(%r8)
    movq %rdx, %rcx
    subq %rsi, %rcx

    cmpq $2, %rcx
    jne .Lkw_def_x86
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'i', %al
    jne .Lkw_def_x86
    cmpb $'f', %dl
    jne .Lkw_def_x86
    movl $TOK_KW_IF, %eax
    jmp .Lemit_kw_x86
.Lkw_def_x86:
    cmpq $3, %rcx
    jne .Lkw_else_x86
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'d', %al
    jne .Lkw_else_x86
    cmpb $'e', %dl
    jne .Lkw_else_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'f', %dl
    jne .Lkw_else_x86
    movl $TOK_KW_DEF, %eax
    jmp .Lemit_kw_x86
.Lkw_else_x86:
    cmpq $4, %rcx
    jne .Lkw_while_x86
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'e', %al
    jne .Lkw_while_x86
    cmpb $'l', %dl
    jne .Lkw_while_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'s', %dl
    jne .Lkw_while_x86
    movzbl 3(%r10,%rsi,1), %edx
    cmpb $'e', %dl
    jne .Lkw_while_x86
    movl $TOK_KW_ELSE, %eax
    jmp .Lemit_kw_x86
.Lkw_while_x86:
    cmpq $5, %rcx
    jne .Lkw_return_x86
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'w', %al
    jne .Lkw_return_x86
    cmpb $'h', %dl
    jne .Lkw_return_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'i', %dl
    jne .Lkw_return_x86
    movzbl 3(%r10,%rsi,1), %edx
    cmpb $'l', %dl
    jne .Lkw_return_x86
    movzbl 4(%r10,%rsi,1), %edx
    cmpb $'e', %dl
    jne .Lkw_return_x86
    movl $TOK_KW_WHILE, %eax
    jmp .Lemit_kw_x86
.Lkw_return_x86:
    cmpq $6, %rcx
    jne .Lkw_let_x86
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'r', %al
    jne .Lkw_let_x86
    cmpb $'e', %dl
    jne .Lkw_let_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'t', %dl
    jne .Lkw_let_x86
    movzbl 3(%r10,%rsi,1), %edx
    cmpb $'u', %dl
    jne .Lkw_let_x86
    movzbl 4(%r10,%rsi,1), %edx
    cmpb $'r', %dl
    jne .Lkw_let_x86
    movzbl 5(%r10,%rsi,1), %edx
    cmpb $'n', %dl
    jne .Lkw_let_x86
    movl $TOK_KW_RETURN, %eax
    jmp .Lemit_kw_x86
.Lkw_let_x86:
    cmpq $3, %rcx
    jne .Lkw_var_x86
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'l', %al
    jne .Lkw_var_x86
    cmpb $'e', %dl
    jne .Lkw_var_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'t', %dl
    jne .Lkw_var_x86
    movl $TOK_KW_LET, %eax
    jmp .Lemit_kw_x86
.Lkw_var_x86:
    cmpq $3, %rcx
    jne .Lkw_const_x86
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'v', %al
    jne .Lkw_const_x86
    cmpb $'a', %dl
    jne .Lkw_const_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'r', %dl
    jne .Lkw_const_x86
    movl $TOK_KW_VAR, %eax
    jmp .Lemit_kw_x86
.Lkw_const_x86:
    cmpq $5, %rcx
    jne .Lemit_ident_x86
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'c', %al
    jne .Lemit_ident_x86
    cmpb $'o', %dl
    jne .Lemit_ident_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'n', %dl
    jne .Lemit_ident_x86
    movzbl 3(%r10,%rsi,1), %edx
    cmpb $'s', %dl
    jne .Lemit_ident_x86
    movzbl 4(%r10,%rsi,1), %edx
    cmpb $'t', %dl
    jne .Lemit_ident_x86
    movl $TOK_KW_CONST, %eax
    jmp .Lemit_kw_x86

.Lemit_ident_x86:
    movl $TOK_IDENT, %eax
.Lemit_kw_x86:
    movl %eax, TOK_KIND(%r9)
    movq %rax, %rax
    FRAME_LEAVE 0

.Llex_int_x86:
    addq $1, %rdx
.Lint_loop_x86:
    cmpq %r11, %rdx
    jae .Lint_done_x86
    movzbl (%r10,%rdx,1), %eax
    cmpb $'0', %al
    jb .Lint_done_x86
    cmpb $'9', %al
    ja .Lint_done_x86
    addq $1, %rdx
    jmp .Lint_loop_x86
.Lint_done_x86:
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_INT, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_INT, %rax
    FRAME_LEAVE 0

.Lskip_comment_x86:
    addq $1, %rdx
.Lcomment_loop_x86:
    cmpq %r11, %rdx
    jae .Leof_x86
    movzbl (%r10,%rdx,1), %eax
    cmpb $10, %al
    je .Lemit_newline_x86
    cmpb $13, %al
    je .Lemit_newline_x86
    addq $1, %rdx
    jmp .Lcomment_loop_x86

.Lemit_newline_from_indent_x86:
    addq $1, %rdx
    jmp .Lemit_newline_common_x86

.Lemit_newline_x86:
    addq $1, %rdx
.Lemit_newline_common_x86:
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_NEWLINE, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $1, %rax
    movq %rax, LEX_AT_LINE_START(%r8)
    movq $TOK_NEWLINE, %rax
    FRAME_LEAVE 0

.Leof_x86:
    movq LEX_INDENT_TOP(%r8), %rcx
    testq %rcx, %rcx
    jz .Leof_emit_x86
    xorq %rax, %rax
    movq %rax, LEX_INDENT_TOP(%r8)
    movq %rcx, LEX_PENDING_DEDENT(%r8)
    subq $1, %rcx
    movq %rcx, LEX_PENDING_DEDENT(%r8)
    movl %edx, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_DEDENT, TOK_KIND(%r9)
    movq $TOK_DEDENT, %rax
    FRAME_LEAVE 0

.Leof_emit_x86:
    movl %edx, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_EOF, TOK_KIND(%r9)
    movq $TOK_EOF, %rax
    FRAME_LEAVE 0

.Lemit_unknown_x86:
    addq $1, %rdx
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_UNKNOWN, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_UNKNOWN, %rax
    FRAME_LEAVE 0

FUNC_END aster_lex__next

#else
#error "lexer: unsupported architecture"
#endif
#endif
