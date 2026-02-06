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
    cmp w7, #'"'
    b.eq .Llex_string
    cmp w7, #39
    b.eq .Llex_char

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
    cmp w7, #'['
    b.ne .Lcheck_rbrack
    add x6, x6, #1
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_LBRACK
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_LBRACK
    FRAME_LEAVE 0
.Lcheck_rbrack:
    cmp w7, #']'
    b.ne .Lcheck_dot
    add x6, x6, #1
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_RBRACK
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_RBRACK
    FRAME_LEAVE 0
.Lcheck_dot:
    cmp w7, #'.'
    b.ne .Lcheck_amp
    add x6, x6, #1
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_DOT
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_DOT
    FRAME_LEAVE 0
.Lcheck_amp:
    cmp w7, #'&'
    b.ne .Lcheck_bar
    add x6, x6, #1
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_AMP
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_AMP
    FRAME_LEAVE 0
.Lcheck_bar:
    cmp w7, #'|'
    b.ne .Lcheck_caret
    add x6, x6, #1
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_BAR
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_BAR
    FRAME_LEAVE 0
.Lcheck_caret:
    cmp w7, #'^'
    b.ne .Lcheck_lparen
    add x6, x6, #1
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_CARET
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_CARET
    FRAME_LEAVE 0
.Lcheck_lparen:
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
    b.ne .Lcheck_bang
    add x6, x6, #1
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_SLASH
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_SLASH
    FRAME_LEAVE 0
.Lcheck_bang:
    cmp w7, #'!'
    b.ne .Lcheck_eq
    add x11, x6, #1
    cmp x11, x5
    b.hs .Lemit_unknown
    ldrb w10, [x4, x11]
    cmp w10, #'='
    b.ne .Lemit_unknown
    add x6, x6, #2
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_NEQ
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_NEQ
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
    cmp x6, x5
    b.hs .Lemit_lt
    ldrb w10, [x4, x6]
    cmp w10, #'='
    b.eq .Lemit_lte
    cmp w10, #'<'
    b.eq .Lemit_shl
.Lemit_lt:
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_LT
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_LT
    FRAME_LEAVE 0
.Lemit_lte:
    add x6, x6, #1
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_LTE
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_LTE
    FRAME_LEAVE 0
.Lemit_shl:
    add x6, x6, #1
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_SHL
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_SHL
    FRAME_LEAVE 0
.Lcheck_gt:
    cmp w7, #'>'
    b.ne .Lemit_unknown
    add x6, x6, #1
    cmp x6, x5
    b.hs .Lemit_gt
    ldrb w10, [x4, x6]
    cmp w10, #'='
    b.eq .Lemit_gte
    cmp w10, #'>'
    b.eq .Lemit_shr
.Lemit_gt:
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_GT
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_GT
    FRAME_LEAVE 0
.Lemit_gte:
    add x6, x6, #1
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_GTE
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_GTE
    FRAME_LEAVE 0
.Lemit_shr:
    add x6, x6, #1
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_SHR
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_SHR
    FRAME_LEAVE 0

.Llex_string:
    // scan until closing quote, handling backslash escapes
    add x6, x6, #1 // consume opening '"'
.Lstring_loop:
    cmp x6, x5
    b.hs .Lemit_unknown
    ldrb w7, [x4, x6]
    cmp w7, #'"'
    b.eq .Lstring_done
    cmp w7, #'\\'
    b.ne .Lstring_advance
    add x6, x6, #1 // consume '\'
    cmp x6, x5
    b.hs .Lemit_unknown
.Lstring_advance:
    add x6, x6, #1
    b .Lstring_loop
.Lstring_done:
    add x6, x6, #1 // consume closing '"'
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_STRING
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_STRING
    FRAME_LEAVE 0

.Llex_char:
    // scan a single-quoted character literal: 'a' or '\n'
    add x6, x6, #1 // consume opening '\''
    cmp x6, x5
    b.hs .Lemit_unknown
    ldrb w7, [x4, x6]
    cmp w7, #'\\'
    b.ne .Lchar_norm
    // escape: consume '\' and one following byte
    add x6, x6, #1
    cmp x6, x5
    b.hs .Lemit_unknown
    add x6, x6, #1
    b .Lchar_check_close
.Lchar_norm:
    // reject empty/unterminated/line-ending literals
    cmp w7, #39
    b.eq .Lemit_unknown
    cmp w7, #10
    b.eq .Lemit_unknown
    cmp w7, #13
    b.eq .Lemit_unknown
    add x6, x6, #1
.Lchar_check_close:
    cmp x6, x5
    b.hs .Lemit_unknown
    ldrb w7, [x4, x6]
    cmp w7, #39
    b.ne .Lemit_unknown
    add x6, x6, #1 // consume closing '\''
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_CHAR
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_CHAR
    FRAME_LEAVE 0

.Llex_ident:
    add x6, x6, #1
.Lident_loop:
    cmp x6, x5
    b.hs .Lident_done
    ldrb w7, [x4, x6]
    // allow '_' anywhere in identifiers
    cmp w7, #'_'
    b.eq .Lident_advance
    cmp w7, #'A'
    b.lo .Lident_check_digit
    cmp w7, #'Z'
    b.ls .Lident_advance
    cmp w7, #'a'
    b.lo .Lident_check_digit
    cmp w7, #'z'
    b.ls .Lident_advance
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

    // keyword checks (fast path by length)
    cmp x9, #2
    b.ne .Lkw_len3
    ldrb w10, [x16]
    ldrb w11, [x16, #1]
    cmp w10, #'i'
    b.ne .Lkw_len2_o
    cmp w11, #'f'
    b.eq .Lkw_emit_if
    cmp w11, #'s'
    b.eq .Lkw_emit_is
    b .Lkw_len3
.Lkw_len2_o:
    cmp w10, #'o'
    b.ne .Lkw_len2_d
    cmp w11, #'f'
    b.eq .Lkw_emit_of
    cmp w11, #'r'
    b.eq .Lkw_emit_or
    b .Lkw_len3
.Lkw_len2_d:
    cmp w10, #'d'
    b.ne .Lkw_len3
    cmp w11, #'o'
    b.eq .Lkw_emit_do
    b .Lkw_len3
.Lkw_emit_if:
    mov w12, #TOK_KW_IF
    b .Lemit_kw
.Lkw_emit_is:
    mov w12, #TOK_KW_IS
    b .Lemit_kw
.Lkw_emit_of:
    mov w12, #TOK_KW_OF
    b .Lemit_kw
.Lkw_emit_or:
    mov w12, #TOK_KW_OR
    b .Lemit_kw
.Lkw_emit_do:
    mov w12, #TOK_KW_DO
    b .Lemit_kw

.Lkw_len3:
    cmp x9, #3
    b.ne .Lkw_len4
    ldrb w10, [x16]
    ldrb w11, [x16, #1]
    ldrb w12, [x16, #2]
    cmp w10, #'d'
    b.ne .Lkw_len3_let
    cmp w11, #'e'
    b.ne .Lkw_len3_let
    cmp w12, #'f'
    b.ne .Lkw_len3_let
    mov w12, #TOK_KW_DEF
    b .Lemit_kw
.Lkw_len3_let:
    cmp w10, #'l'
    b.ne .Lkw_len3_var
    cmp w11, #'e'
    b.ne .Lkw_len3_var
    cmp w12, #'t'
    b.ne .Lkw_len3_var
    mov w12, #TOK_KW_LET
    b .Lemit_kw
.Lkw_len3_var:
    cmp w10, #'v'
    b.ne .Lkw_len3_and
    cmp w11, #'a'
    b.ne .Lkw_len3_and
    cmp w12, #'r'
    b.ne .Lkw_len3_and
    mov w12, #TOK_KW_VAR
    b .Lemit_kw
.Lkw_len3_and:
    cmp w10, #'a'
    b.ne .Lkw_len3_not
    cmp w11, #'n'
    b.ne .Lkw_len3_not
    cmp w12, #'d'
    b.ne .Lkw_len3_not
    mov w12, #TOK_KW_AND
    b .Lemit_kw
.Lkw_len3_not:
    cmp w10, #'n'
    b.ne .Lkw_len3_mut
    cmp w11, #'o'
    b.ne .Lkw_len3_mut
    cmp w12, #'t'
    b.ne .Lkw_len3_mut
    mov w12, #TOK_KW_NOT
    b .Lemit_kw
.Lkw_len3_mut:
    cmp w10, #'m'
    b.ne .Lkw_len3_ref
    cmp w11, #'u'
    b.ne .Lkw_len3_ref
    cmp w12, #'t'
    b.ne .Lkw_len3_ref
    mov w12, #TOK_KW_MUT
    b .Lemit_kw
.Lkw_len3_ref:
    cmp w10, #'r'
    b.ne .Lkw_len3_ptr
    cmp w11, #'e'
    b.ne .Lkw_len3_ptr
    cmp w12, #'f'
    b.ne .Lkw_len3_ptr
    mov w12, #TOK_KW_REF
    b .Lemit_kw
.Lkw_len3_ptr:
    cmp w10, #'p'
    b.ne .Lemit_ident
    cmp w11, #'t'
    b.ne .Lemit_ident
    cmp w12, #'r'
    b.ne .Lemit_ident
    mov w12, #TOK_KW_PTR
    b .Lemit_kw

.Lkw_len4:
    cmp x9, #4
    b.ne .Lkw_len5
    ldrb w10, [x16]
    ldrb w11, [x16, #1]
    ldrb w12, [x16, #2]
    ldrb w13, [x16, #3]
    // else
    cmp w10, #'e'
    b.ne .Lkw_len4_null
    cmp w11, #'l'
    b.ne .Lkw_len4_null
    cmp w12, #'s'
    b.ne .Lkw_len4_null
    cmp w13, #'e'
    b.ne .Lkw_len4_null
    mov w12, #TOK_KW_ELSE
    b .Lemit_kw
.Lkw_len4_null:
    // null
    cmp w10, #'n'
    b.ne .Lkw_len4_then
    cmp w11, #'u'
    b.ne .Lkw_len4_then
    cmp w12, #'l'
    b.ne .Lkw_len4_then
    cmp w13, #'l'
    b.ne .Lkw_len4_then
    mov w12, #TOK_KW_NULL
    b .Lemit_kw
.Lkw_len4_then:
    // then
    cmp w10, #'t'
    b.ne .Lkw_len4_true
    cmp w11, #'h'
    b.ne .Lkw_len4_true
    cmp w12, #'e'
    b.ne .Lkw_len4_true
    cmp w13, #'n'
    b.ne .Lkw_len4_true
    mov w12, #TOK_KW_THEN
    b .Lemit_kw
.Lkw_len4_true:
    // true
    cmp w10, #'t'
    b.ne .Lemit_ident
    cmp w11, #'r'
    b.ne .Lemit_ident
    cmp w12, #'u'
    b.ne .Lemit_ident
    cmp w13, #'e'
    b.ne .Lemit_ident
    mov w12, #TOK_KW_TRUE
    b .Lemit_kw

.Lkw_len5:
    cmp x9, #5
    b.ne .Lkw_len6
    ldrb w10, [x16]
    ldrb w11, [x16, #1]
    ldrb w12, [x16, #2]
    ldrb w13, [x16, #3]
    ldrb w14, [x16, #4]
    // while
    cmp w10, #'w'
    b.ne .Lkw_len5_const
    cmp w11, #'h'
    b.ne .Lkw_len5_const
    cmp w12, #'i'
    b.ne .Lkw_len5_const
    cmp w13, #'l'
    b.ne .Lkw_len5_const
    cmp w14, #'e'
    b.ne .Lkw_len5_const
    mov w12, #TOK_KW_WHILE
    b .Lemit_kw
.Lkw_len5_const:
    // const
    cmp w10, #'c'
    b.ne .Lkw_len5_break
    cmp w11, #'o'
    b.ne .Lkw_len5_break
    cmp w12, #'n'
    b.ne .Lkw_len5_break
    cmp w13, #'s'
    b.ne .Lkw_len5_break
    cmp w14, #'t'
    b.ne .Lkw_len5_break
    mov w12, #TOK_KW_CONST
    b .Lemit_kw
.Lkw_len5_break:
    // break
    cmp w10, #'b'
    b.ne .Lkw_len5_slice
    cmp w11, #'r'
    b.ne .Lkw_len5_slice
    cmp w12, #'e'
    b.ne .Lkw_len5_slice
    cmp w13, #'a'
    b.ne .Lkw_len5_slice
    cmp w14, #'k'
    b.ne .Lkw_len5_slice
    mov w12, #TOK_KW_BREAK
    b .Lemit_kw
.Lkw_len5_slice:
    // slice
    cmp w10, #'s'
    b.ne .Lkw_len5_false
    cmp w11, #'l'
    b.ne .Lkw_len5_false
    cmp w12, #'i'
    b.ne .Lkw_len5_false
    cmp w13, #'c'
    b.ne .Lkw_len5_false
    cmp w14, #'e'
    b.ne .Lkw_len5_false
    mov w12, #TOK_KW_SLICE
    b .Lemit_kw
.Lkw_len5_false:
    // false
    cmp w10, #'f'
    b.ne .Lemit_ident
    cmp w11, #'a'
    b.ne .Lemit_ident
    cmp w12, #'l'
    b.ne .Lemit_ident
    cmp w13, #'s'
    b.ne .Lemit_ident
    cmp w14, #'e'
    b.ne .Lemit_ident
    mov w12, #TOK_KW_FALSE
    b .Lemit_kw

.Lkw_len6:
    cmp x9, #6
    b.ne .Lkw_len7
    ldrb w10, [x16]
    ldrb w11, [x16, #1]
    ldrb w12, [x16, #2]
    ldrb w13, [x16, #3]
    ldrb w14, [x16, #4]
    ldrb w15, [x16, #5]
    // return
    cmp w10, #'r'
    b.ne .Lkw_len6_extern
    cmp w11, #'e'
    b.ne .Lkw_len6_extern
    cmp w12, #'t'
    b.ne .Lkw_len6_extern
    cmp w13, #'u'
    b.ne .Lkw_len6_extern
    cmp w14, #'r'
    b.ne .Lkw_len6_extern
    cmp w15, #'n'
    b.ne .Lkw_len6_extern
    mov w12, #TOK_KW_RETURN
    b .Lemit_kw
.Lkw_len6_extern:
    // extern
    cmp w10, #'e'
    b.ne .Lkw_len6_struct
    cmp w11, #'x'
    b.ne .Lkw_len6_struct
    cmp w12, #'t'
    b.ne .Lkw_len6_struct
    cmp w13, #'e'
    b.ne .Lkw_len6_struct
    cmp w14, #'r'
    b.ne .Lkw_len6_struct
    cmp w15, #'n'
    b.ne .Lkw_len6_struct
    mov w12, #TOK_KW_EXTERN
    b .Lemit_kw
.Lkw_len6_struct:
    // struct
    cmp w10, #'s'
    b.ne .Lemit_ident
    cmp w11, #'t'
    b.ne .Lemit_ident
    cmp w12, #'r'
    b.ne .Lemit_ident
    cmp w13, #'u'
    b.ne .Lemit_ident
    cmp w14, #'c'
    b.ne .Lemit_ident
    cmp w15, #'t'
    b.ne .Lemit_ident
    mov w12, #TOK_KW_STRUCT
    b .Lemit_kw

.Lkw_len7:
    cmp x9, #7
    b.ne .Lkw_len8
    ldrb w10, [x16]
    ldrb w11, [x16, #1]
    ldrb w12, [x16, #2]
    ldrb w13, [x16, #3]
    ldrb w14, [x16, #4]
    ldrb w15, [x16, #5]
    ldrb w17, [x16, #6]
    // returns
    cmp w10, #'r'
    b.ne .Lemit_ident
    cmp w11, #'e'
    b.ne .Lemit_ident
    cmp w12, #'t'
    b.ne .Lemit_ident
    cmp w13, #'u'
    b.ne .Lemit_ident
    cmp w14, #'r'
    b.ne .Lemit_ident
    cmp w15, #'n'
    b.ne .Lemit_ident
    cmp w17, #'s'
    b.ne .Lemit_ident
    mov w12, #TOK_KW_RETURNS
    b .Lemit_kw

.Lkw_len8:
    cmp x9, #8
    b.ne .Lemit_ident
    ldrb w10, [x16]
    ldrb w11, [x16, #1]
    ldrb w12, [x16, #2]
    ldrb w13, [x16, #3]
    ldrb w14, [x16, #4]
    ldrb w15, [x16, #5]
    ldrb w17, [x16, #6]
    ldrb w18, [x16, #7]
    // continue
    cmp w10, #'c'
    b.ne .Lemit_ident
    cmp w11, #'o'
    b.ne .Lemit_ident
    cmp w12, #'n'
    b.ne .Lemit_ident
    cmp w13, #'t'
    b.ne .Lemit_ident
    cmp w14, #'i'
    b.ne .Lemit_ident
    cmp w15, #'n'
    b.ne .Lemit_ident
    cmp w17, #'u'
    b.ne .Lemit_ident
    cmp w18, #'e'
    b.ne .Lemit_ident
    mov w12, #TOK_KW_CONTINUE
    b .Lemit_kw

.Lemit_ident:
    mov w12, #TOK_IDENT
.Lemit_kw:
    str w12, [x3, #TOK_KIND]
    mov x0, x12
    FRAME_LEAVE 0

.Llex_int:
    add x6, x6, #1

    // hex literal (0x...)
    cmp w7, #'0'
    b.ne .Lint_loop_dec
    cmp x6, x5
    b.hs .Lint_loop_dec
    ldrb w10, [x4, x6]
    cmp w10, #'x'
    b.eq .Lhex_loop_start
    cmp w10, #'X'
    b.ne .Lint_loop_dec
.Lhex_loop_start:
    add x6, x6, #1
.Lhex_loop:
    cmp x6, x5
    b.hs .Lemit_int
    ldrb w7, [x4, x6]
    cmp w7, #'0'
    b.lo .Lemit_int
    cmp w7, #'9'
    b.ls .Lhex_advance
    cmp w7, #'a'
    b.lo .Lhex_check_A
    cmp w7, #'f'
    b.ls .Lhex_advance
.Lhex_check_A:
    cmp w7, #'A'
    b.lo .Lemit_int
    cmp w7, #'F'
    b.hi .Lemit_int
.Lhex_advance:
    add x6, x6, #1
    b .Lhex_loop

    // decimal literal
.Lint_loop_dec:
    cmp x6, x5
    b.hs .Lint_done_dec
    ldrb w7, [x4, x6]
    cmp w7, #'0'
    b.lo .Lint_done_dec
    cmp w7, #'9'
    b.hi .Lint_done_dec
    add x6, x6, #1
    b .Lint_loop_dec
.Lint_done_dec:
    // float literal: digits '.' digits
    cmp x6, x5
    b.hs .Lemit_int
    ldrb w10, [x4, x6]
    cmp w10, #'.'
    b.ne .Lemit_int
    add x11, x6, #1
    cmp x11, x5
    b.hs .Lemit_int
    ldrb w12, [x4, x11]
    cmp w12, #'0'
    b.lo .Lemit_int
    cmp w12, #'9'
    b.hi .Lemit_int
    // consume '.'
    add x6, x6, #1
.Lfloat_loop:
    cmp x6, x5
    b.hs .Lemit_float
    ldrb w10, [x4, x6]
    cmp w10, #'0'
    b.lo .Lemit_float
    cmp w10, #'9'
    b.hi .Lemit_float
    add x6, x6, #1
    b .Lfloat_loop
.Lemit_float:
    str w8, [x3, #TOK_START]
    str w6, [x3, #TOK_END]
    mov w9, #TOK_FLOAT
    str w9, [x3, #TOK_KIND]
    str x6, [x2, #LEX_POS]
    mov x0, #TOK_FLOAT
    FRAME_LEAVE 0

.Lemit_int:
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
    cmpb $34, %al
    je .Llex_string_x86
    cmpb $39, %al
    je .Llex_char_x86

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
    cmpb $'[', %al
    jne .Lcheck_rbrack_x86
    addq $1, %rdx
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_LBRACK, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_LBRACK, %rax
    FRAME_LEAVE 0
.Lcheck_rbrack_x86:
    cmpb $']', %al
    jne .Lcheck_dot_x86
    addq $1, %rdx
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_RBRACK, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_RBRACK, %rax
    FRAME_LEAVE 0
.Lcheck_dot_x86:
    cmpb $'.', %al
    jne .Lcheck_amp_x86
    addq $1, %rdx
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_DOT, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_DOT, %rax
    FRAME_LEAVE 0
.Lcheck_amp_x86:
    cmpb $'&', %al
    jne .Lcheck_bar_x86
    addq $1, %rdx
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_AMP, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_AMP, %rax
    FRAME_LEAVE 0
.Lcheck_bar_x86:
    cmpb $'|', %al
    jne .Lcheck_caret_x86
    addq $1, %rdx
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_BAR, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_BAR, %rax
    FRAME_LEAVE 0
.Lcheck_caret_x86:
    cmpb $'^', %al
    jne .Lcheck_lparen_x86
    addq $1, %rdx
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_CARET, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_CARET, %rax
    FRAME_LEAVE 0
.Lcheck_lparen_x86:
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
    jne .Lcheck_bang_x86
    addq $1, %rdx
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_SLASH, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_SLASH, %rax
    FRAME_LEAVE 0
.Lcheck_bang_x86:
    cmpb $'!', %al
    jne .Lcheck_eq_x86
    leaq 1(%rdx), %rcx
    cmpq %r11, %rcx
    jae .Lemit_unknown_x86
    movzbl (%r10,%rcx,1), %eax
    cmpb $'=', %al
    jne .Lemit_unknown_x86
    addq $2, %rdx
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_NEQ, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_NEQ, %rax
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
    cmpq %r11, %rdx
    jae .Lemit_lt_x86
    movzbl (%r10,%rdx,1), %eax
    cmpb $'=', %al
    je .Lemit_lte_x86
    cmpb $'<', %al
    je .Lemit_shl_x86
.Lemit_lt_x86:
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_LT, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_LT, %rax
    FRAME_LEAVE 0
.Lemit_lte_x86:
    addq $1, %rdx
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_LTE, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_LTE, %rax
    FRAME_LEAVE 0
.Lemit_shl_x86:
    addq $1, %rdx
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_SHL, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_SHL, %rax
    FRAME_LEAVE 0
.Lcheck_gt_x86:
    cmpb $'>', %al
    jne .Lemit_unknown_x86
    addq $1, %rdx
    cmpq %r11, %rdx
    jae .Lemit_gt_x86
    movzbl (%r10,%rdx,1), %eax
    cmpb $'=', %al
    je .Lemit_gte_x86
    cmpb $'>', %al
    je .Lemit_shr_x86
.Lemit_gt_x86:
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_GT, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_GT, %rax
    FRAME_LEAVE 0
.Lemit_gte_x86:
    addq $1, %rdx
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_GTE, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_GTE, %rax
    FRAME_LEAVE 0
.Lemit_shr_x86:
    addq $1, %rdx
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_SHR, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_SHR, %rax
    FRAME_LEAVE 0

.Llex_string_x86:
    addq $1, %rdx # consume opening '"'
.Lstring_loop_x86:
    cmpq %r11, %rdx
    jae .Lemit_unknown_x86
    movzbl (%r10,%rdx,1), %eax
    cmpb $34, %al
    je .Lstring_done_x86
    cmpb $'\\', %al
    jne .Lstring_advance_x86
    addq $1, %rdx # consume '\'
    cmpq %r11, %rdx
    jae .Lemit_unknown_x86
.Lstring_advance_x86:
    addq $1, %rdx
    jmp .Lstring_loop_x86
.Lstring_done_x86:
    addq $1, %rdx # consume closing '"'
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_STRING, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_STRING, %rax
    FRAME_LEAVE 0

.Llex_char_x86:
    addq $1, %rdx # consume opening '\''
    cmpq %r11, %rdx
    jae .Lemit_unknown_x86
    movzbl (%r10,%rdx,1), %eax
    cmpb $'\\', %al
    jne .Lchar_norm_x86
    addq $1, %rdx # consume '\'
    cmpq %r11, %rdx
    jae .Lemit_unknown_x86
    addq $1, %rdx # consume escaped byte
    jmp .Lchar_check_close_x86
.Lchar_norm_x86:
    cmpb $39, %al
    je .Lemit_unknown_x86
    cmpb $10, %al
    je .Lemit_unknown_x86
    cmpb $13, %al
    je .Lemit_unknown_x86
    addq $1, %rdx
.Lchar_check_close_x86:
    cmpq %r11, %rdx
    jae .Lemit_unknown_x86
    movzbl (%r10,%rdx,1), %eax
    cmpb $39, %al
    jne .Lemit_unknown_x86
    addq $1, %rdx # consume closing '\''
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_CHAR, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_CHAR, %rax
    FRAME_LEAVE 0

.Llex_ident_x86:
    addq $1, %rdx
.Lident_loop_x86:
    cmpq %r11, %rdx
    jae .Lident_done_x86
    movzbl (%r10,%rdx,1), %eax
    // allow '_' anywhere in identifiers
    cmpb $'_', %al
    je .Lident_advance_x86
    cmpb $'A', %al
    jb .Lident_check_digit_x86
    cmpb $'Z', %al
    jbe .Lident_advance_x86
    cmpb $'a', %al
    jb .Lident_check_digit_x86
    cmpb $'z', %al
    jbe .Lident_advance_x86
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

    // keyword checks (fast path by length)
    cmpq $2, %rcx
    jne .Lkw_len3_x86
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'i', %al
    jne .Lkw_len2_o_x86
    cmpb $'f', %dl
    je .Lkw_emit_if_x86
    cmpb $'s', %dl
    je .Lkw_emit_is_x86
    jmp .Lkw_len3_x86
.Lkw_len2_o_x86:
    cmpb $'o', %al
    jne .Lkw_len2_d_x86
    cmpb $'f', %dl
    je .Lkw_emit_of_x86
    cmpb $'r', %dl
    je .Lkw_emit_or_x86
    jmp .Lkw_len3_x86
.Lkw_len2_d_x86:
    cmpb $'d', %al
    jne .Lkw_len3_x86
    cmpb $'o', %dl
    je .Lkw_emit_do_x86
    jmp .Lkw_len3_x86
.Lkw_emit_if_x86:
    movl $TOK_KW_IF, %eax
    jmp .Lemit_kw_x86
.Lkw_emit_is_x86:
    movl $TOK_KW_IS, %eax
    jmp .Lemit_kw_x86
.Lkw_emit_of_x86:
    movl $TOK_KW_OF, %eax
    jmp .Lemit_kw_x86
.Lkw_emit_or_x86:
    movl $TOK_KW_OR, %eax
    jmp .Lemit_kw_x86
.Lkw_emit_do_x86:
    movl $TOK_KW_DO, %eax
    jmp .Lemit_kw_x86

.Lkw_len3_x86:
    cmpq $3, %rcx
    jne .Lkw_len4_x86
    // def
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'d', %al
    jne .Lkw_len3_let_x86
    cmpb $'e', %dl
    jne .Lkw_len3_let_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'f', %dl
    jne .Lkw_len3_let_x86
    movl $TOK_KW_DEF, %eax
    jmp .Lemit_kw_x86
.Lkw_len3_let_x86:
    // let
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'l', %al
    jne .Lkw_len3_var_x86
    cmpb $'e', %dl
    jne .Lkw_len3_var_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'t', %dl
    jne .Lkw_len3_var_x86
    movl $TOK_KW_LET, %eax
    jmp .Lemit_kw_x86
.Lkw_len3_var_x86:
    // var
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'v', %al
    jne .Lkw_len3_and_x86
    cmpb $'a', %dl
    jne .Lkw_len3_and_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'r', %dl
    jne .Lkw_len3_and_x86
    movl $TOK_KW_VAR, %eax
    jmp .Lemit_kw_x86
.Lkw_len3_and_x86:
    // and
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'a', %al
    jne .Lkw_len3_not_x86
    cmpb $'n', %dl
    jne .Lkw_len3_not_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'d', %dl
    jne .Lkw_len3_not_x86
    movl $TOK_KW_AND, %eax
    jmp .Lemit_kw_x86
.Lkw_len3_not_x86:
    // not
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'n', %al
    jne .Lkw_len3_mut_x86
    cmpb $'o', %dl
    jne .Lkw_len3_mut_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'t', %dl
    jne .Lkw_len3_mut_x86
    movl $TOK_KW_NOT, %eax
    jmp .Lemit_kw_x86
.Lkw_len3_mut_x86:
    // mut
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'m', %al
    jne .Lkw_len3_ref_x86
    cmpb $'u', %dl
    jne .Lkw_len3_ref_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'t', %dl
    jne .Lkw_len3_ref_x86
    movl $TOK_KW_MUT, %eax
    jmp .Lemit_kw_x86
.Lkw_len3_ref_x86:
    // ref
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'r', %al
    jne .Lkw_len3_ptr_x86
    cmpb $'e', %dl
    jne .Lkw_len3_ptr_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'f', %dl
    jne .Lkw_len3_ptr_x86
    movl $TOK_KW_REF, %eax
    jmp .Lemit_kw_x86
.Lkw_len3_ptr_x86:
    // ptr
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'p', %al
    jne .Lemit_ident_x86
    cmpb $'t', %dl
    jne .Lemit_ident_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'r', %dl
    jne .Lemit_ident_x86
    movl $TOK_KW_PTR, %eax
    jmp .Lemit_kw_x86

.Lkw_len4_x86:
    cmpq $4, %rcx
    jne .Lkw_len5_x86
    // else
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'e', %al
    jne .Lkw_len4_null_x86
    cmpb $'l', %dl
    jne .Lkw_len4_null_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'s', %dl
    jne .Lkw_len4_null_x86
    movzbl 3(%r10,%rsi,1), %edx
    cmpb $'e', %dl
    jne .Lkw_len4_null_x86
    movl $TOK_KW_ELSE, %eax
    jmp .Lemit_kw_x86
.Lkw_len4_null_x86:
    // null
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'n', %al
    jne .Lkw_len4_then_x86
    cmpb $'u', %dl
    jne .Lkw_len4_then_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'l', %dl
    jne .Lkw_len4_then_x86
    movzbl 3(%r10,%rsi,1), %edx
    cmpb $'l', %dl
    jne .Lkw_len4_then_x86
    movl $TOK_KW_NULL, %eax
    jmp .Lemit_kw_x86
.Lkw_len4_then_x86:
    // then
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'t', %al
    jne .Lkw_len4_true_x86
    cmpb $'h', %dl
    jne .Lkw_len4_true_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'e', %dl
    jne .Lkw_len4_true_x86
    movzbl 3(%r10,%rsi,1), %edx
    cmpb $'n', %dl
    jne .Lkw_len4_true_x86
    movl $TOK_KW_THEN, %eax
    jmp .Lemit_kw_x86
.Lkw_len4_true_x86:
    // true
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'t', %al
    jne .Lemit_ident_x86
    cmpb $'r', %dl
    jne .Lemit_ident_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'u', %dl
    jne .Lemit_ident_x86
    movzbl 3(%r10,%rsi,1), %edx
    cmpb $'e', %dl
    jne .Lemit_ident_x86
    movl $TOK_KW_TRUE, %eax
    jmp .Lemit_kw_x86

.Lkw_len5_x86:
    cmpq $5, %rcx
    jne .Lkw_len6_x86
    // while
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'w', %al
    jne .Lkw_len5_const_x86
    cmpb $'h', %dl
    jne .Lkw_len5_const_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'i', %dl
    jne .Lkw_len5_const_x86
    movzbl 3(%r10,%rsi,1), %edx
    cmpb $'l', %dl
    jne .Lkw_len5_const_x86
    movzbl 4(%r10,%rsi,1), %edx
    cmpb $'e', %dl
    jne .Lkw_len5_const_x86
    movl $TOK_KW_WHILE, %eax
    jmp .Lemit_kw_x86
.Lkw_len5_const_x86:
    // const
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'c', %al
    jne .Lkw_len5_break_x86
    cmpb $'o', %dl
    jne .Lkw_len5_break_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'n', %dl
    jne .Lkw_len5_break_x86
    movzbl 3(%r10,%rsi,1), %edx
    cmpb $'s', %dl
    jne .Lkw_len5_break_x86
    movzbl 4(%r10,%rsi,1), %edx
    cmpb $'t', %dl
    jne .Lkw_len5_break_x86
    movl $TOK_KW_CONST, %eax
    jmp .Lemit_kw_x86
.Lkw_len5_break_x86:
    // break
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'b', %al
    jne .Lkw_len5_slice_x86
    cmpb $'r', %dl
    jne .Lkw_len5_slice_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'e', %dl
    jne .Lkw_len5_slice_x86
    movzbl 3(%r10,%rsi,1), %edx
    cmpb $'a', %dl
    jne .Lkw_len5_slice_x86
    movzbl 4(%r10,%rsi,1), %edx
    cmpb $'k', %dl
    jne .Lkw_len5_slice_x86
    movl $TOK_KW_BREAK, %eax
    jmp .Lemit_kw_x86
.Lkw_len5_slice_x86:
    // slice
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'s', %al
    jne .Lkw_len5_false_x86
    cmpb $'l', %dl
    jne .Lkw_len5_false_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'i', %dl
    jne .Lkw_len5_false_x86
    movzbl 3(%r10,%rsi,1), %edx
    cmpb $'c', %dl
    jne .Lkw_len5_false_x86
    movzbl 4(%r10,%rsi,1), %edx
    cmpb $'e', %dl
    jne .Lkw_len5_false_x86
    movl $TOK_KW_SLICE, %eax
    jmp .Lemit_kw_x86
.Lkw_len5_false_x86:
    // false
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'f', %al
    jne .Lemit_ident_x86
    cmpb $'a', %dl
    jne .Lemit_ident_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'l', %dl
    jne .Lemit_ident_x86
    movzbl 3(%r10,%rsi,1), %edx
    cmpb $'s', %dl
    jne .Lemit_ident_x86
    movzbl 4(%r10,%rsi,1), %edx
    cmpb $'e', %dl
    jne .Lemit_ident_x86
    movl $TOK_KW_FALSE, %eax
    jmp .Lemit_kw_x86

.Lkw_len6_x86:
    cmpq $6, %rcx
    jne .Lkw_len7_x86
    // return
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'r', %al
    jne .Lkw_len6_extern_x86
    cmpb $'e', %dl
    jne .Lkw_len6_extern_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'t', %dl
    jne .Lkw_len6_extern_x86
    movzbl 3(%r10,%rsi,1), %edx
    cmpb $'u', %dl
    jne .Lkw_len6_extern_x86
    movzbl 4(%r10,%rsi,1), %edx
    cmpb $'r', %dl
    jne .Lkw_len6_extern_x86
    movzbl 5(%r10,%rsi,1), %edx
    cmpb $'n', %dl
    jne .Lkw_len6_extern_x86
    movl $TOK_KW_RETURN, %eax
    jmp .Lemit_kw_x86
.Lkw_len6_extern_x86:
    // extern
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'e', %al
    jne .Lkw_len6_struct_x86
    cmpb $'x', %dl
    jne .Lkw_len6_struct_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'t', %dl
    jne .Lkw_len6_struct_x86
    movzbl 3(%r10,%rsi,1), %edx
    cmpb $'e', %dl
    jne .Lkw_len6_struct_x86
    movzbl 4(%r10,%rsi,1), %edx
    cmpb $'r', %dl
    jne .Lkw_len6_struct_x86
    movzbl 5(%r10,%rsi,1), %edx
    cmpb $'n', %dl
    jne .Lkw_len6_struct_x86
    movl $TOK_KW_EXTERN, %eax
    jmp .Lemit_kw_x86
.Lkw_len6_struct_x86:
    // struct
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'s', %al
    jne .Lemit_ident_x86
    cmpb $'t', %dl
    jne .Lemit_ident_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'r', %dl
    jne .Lemit_ident_x86
    movzbl 3(%r10,%rsi,1), %edx
    cmpb $'u', %dl
    jne .Lemit_ident_x86
    movzbl 4(%r10,%rsi,1), %edx
    cmpb $'c', %dl
    jne .Lemit_ident_x86
    movzbl 5(%r10,%rsi,1), %edx
    cmpb $'t', %dl
    jne .Lemit_ident_x86
    movl $TOK_KW_STRUCT, %eax
    jmp .Lemit_kw_x86

.Lkw_len7_x86:
    cmpq $7, %rcx
    jne .Lkw_len8_x86
    // returns
    movzbl (%r10,%rsi,1), %eax
    movzbl 1(%r10,%rsi,1), %edx
    cmpb $'r', %al
    jne .Lemit_ident_x86
    cmpb $'e', %dl
    jne .Lemit_ident_x86
    movzbl 2(%r10,%rsi,1), %edx
    cmpb $'t', %dl
    jne .Lemit_ident_x86
    movzbl 3(%r10,%rsi,1), %edx
    cmpb $'u', %dl
    jne .Lemit_ident_x86
    movzbl 4(%r10,%rsi,1), %edx
    cmpb $'r', %dl
    jne .Lemit_ident_x86
    movzbl 5(%r10,%rsi,1), %edx
    cmpb $'n', %dl
    jne .Lemit_ident_x86
    movzbl 6(%r10,%rsi,1), %edx
    cmpb $'s', %dl
    jne .Lemit_ident_x86
    movl $TOK_KW_RETURNS, %eax
    jmp .Lemit_kw_x86

.Lkw_len8_x86:
    cmpq $8, %rcx
    jne .Lemit_ident_x86
    // continue
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
    cmpb $'t', %dl
    jne .Lemit_ident_x86
    movzbl 4(%r10,%rsi,1), %edx
    cmpb $'i', %dl
    jne .Lemit_ident_x86
    movzbl 5(%r10,%rsi,1), %edx
    cmpb $'n', %dl
    jne .Lemit_ident_x86
    movzbl 6(%r10,%rsi,1), %edx
    cmpb $'u', %dl
    jne .Lemit_ident_x86
    movzbl 7(%r10,%rsi,1), %edx
    cmpb $'e', %dl
    jne .Lemit_ident_x86
    movl $TOK_KW_CONTINUE, %eax
    jmp .Lemit_kw_x86

.Lemit_ident_x86:
    movl $TOK_IDENT, %eax
.Lemit_kw_x86:
    movl %eax, TOK_KIND(%r9)
    movq %rax, %rax
    FRAME_LEAVE 0

.Llex_int_x86:
    addq $1, %rdx

    // hex literal (0x...)
    cmpb $'0', %al
    jne .Lint_loop_dec_x86
    cmpq %r11, %rdx
    jae .Lint_loop_dec_x86
    movzbl (%r10,%rdx,1), %eax
    cmpb $'x', %al
    je .Lhex_loop_start_x86
    cmpb $'X', %al
    jne .Lint_loop_dec_x86
.Lhex_loop_start_x86:
    addq $1, %rdx
.Lhex_loop_x86:
    cmpq %r11, %rdx
    jae .Lemit_int_x86
    movzbl (%r10,%rdx,1), %eax
    cmpb $'0', %al
    jb .Lemit_int_x86
    cmpb $'9', %al
    jbe .Lhex_advance_x86
    cmpb $'a', %al
    jb .Lhex_check_A_x86
    cmpb $'f', %al
    jbe .Lhex_advance_x86
.Lhex_check_A_x86:
    cmpb $'A', %al
    jb .Lemit_int_x86
    cmpb $'F', %al
    ja .Lemit_int_x86
.Lhex_advance_x86:
    addq $1, %rdx
    jmp .Lhex_loop_x86

    // decimal literal
.Lint_loop_dec_x86:
    cmpq %r11, %rdx
    jae .Lint_done_dec_x86
    movzbl (%r10,%rdx,1), %eax
    cmpb $'0', %al
    jb .Lint_done_dec_x86
    cmpb $'9', %al
    ja .Lint_done_dec_x86
    addq $1, %rdx
    jmp .Lint_loop_dec_x86
.Lint_done_dec_x86:
    // float literal: digits '.' digits
    cmpq %r11, %rdx
    jae .Lemit_int_x86
    movzbl (%r10,%rdx,1), %eax
    cmpb $'.', %al
    jne .Lemit_int_x86
    leaq 1(%rdx), %rcx
    cmpq %r11, %rcx
    jae .Lemit_int_x86
    movzbl (%r10,%rcx,1), %eax
    cmpb $'0', %al
    jb .Lemit_int_x86
    cmpb $'9', %al
    ja .Lemit_int_x86
    addq $1, %rdx # consume '.'
.Lfloat_loop_x86:
    cmpq %r11, %rdx
    jae .Lemit_float_x86
    movzbl (%r10,%rdx,1), %eax
    cmpb $'0', %al
    jb .Lemit_float_x86
    cmpb $'9', %al
    ja .Lemit_float_x86
    addq $1, %rdx
    jmp .Lfloat_loop_x86
.Lemit_float_x86:
    movl %esi, TOK_START(%r9)
    movl %edx, TOK_END(%r9)
    movl $TOK_FLOAT, TOK_KIND(%r9)
    movq %rdx, LEX_POS(%r8)
    movq $TOK_FLOAT, %rax
    FRAME_LEAVE 0

.Lemit_int_x86:
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
