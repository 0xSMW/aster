#include "base.inc"
#if defined(__aarch64__)
#include "abi_arm64.inc"
#elif defined(__x86_64__)
#include "abi_x86_64.inc"
#endif
#include "lexer.inc"
#include "vec.inc"

.section __TEXT,__cstring,cstring_literals
.p2align 2
ir_header:
    .asciz "; ModuleID = 'aster'\nsource_filename = \"aster\"\n\n"
ir_main_prefix:
    .asciz "define i32 @main() {\nentry:\n  ret i32 "
ir_main_suffix:
    .asciz "\n}\n"

#if defined(__aarch64__)

.equ OFF_LEX, 0
.equ OFF_TOK, 576
.equ OFF_SRC, 592
.equ OFF_LEN, 600
.equ OFF_OUT, 608
.equ FRAME_SIZE, 640

// int asterc0__compile(u8* src, usize len, FILE* out)
FUNC_BEGIN asterc0__compile
    FRAME_ENTER FRAME_SIZE
    str x0, [sp, #OFF_SRC]
    str x1, [sp, #OFF_LEN]
    str x2, [sp, #OFF_OUT]

    // init lexer
    add x0, sp, #OFF_LEX
    ldr x1, [sp, #OFF_SRC]
    ldr x2, [sp, #OFF_LEN]
    bl _aster_lex__init

    // find "def"
.Lscan_top:
    add x0, sp, #OFF_LEX
    add x1, sp, #OFF_TOK
    bl _aster_lex__next
    cmp x0, #TOK_EOF
    b.eq .Lfail
    cmp x0, #TOK_KW_DEF
    b.ne .Lscan_top

    // expect IDENT (function name) then '(' ')'
    add x0, sp, #OFF_LEX
    add x1, sp, #OFF_TOK
    bl _aster_lex__next
    cmp x0, #TOK_IDENT
    b.ne .Lfail

    add x0, sp, #OFF_LEX
    add x1, sp, #OFF_TOK
    bl _aster_lex__next
    cmp x0, #TOK_LPAREN
    b.ne .Lfail

    add x0, sp, #OFF_LEX
    add x1, sp, #OFF_TOK
    bl _aster_lex__next
    cmp x0, #TOK_RPAREN
    b.ne .Lfail

    // optional: "returns" <type>
    add x0, sp, #OFF_LEX
    add x1, sp, #OFF_TOK
    bl _aster_lex__next
    cmp x0, #TOK_KW_RETURNS
    b.ne .Lafter_returns
    // consume type ident
    add x0, sp, #OFF_LEX
    add x1, sp, #OFF_TOK
    bl _aster_lex__next
    cmp x0, #TOK_IDENT
    b.ne .Lfail
    // next token
    add x0, sp, #OFF_LEX
    add x1, sp, #OFF_TOK
    bl _aster_lex__next
.Lafter_returns:
    // expect NEWLINE then INDENT
    cmp x0, #TOK_NEWLINE
    b.ne .Lfail
    add x0, sp, #OFF_LEX
    add x1, sp, #OFF_TOK
    bl _aster_lex__next
    cmp x0, #TOK_INDENT
    b.ne .Lfail

    // scan body for "return" INT
.Lscan_body:
    add x0, sp, #OFF_LEX
    add x1, sp, #OFF_TOK
    bl _aster_lex__next
    cmp x0, #TOK_EOF
    b.eq .Lfail
    cmp x0, #TOK_KW_RETURN
    b.ne .Lscan_body

    // next token must be INT
    add x0, sp, #OFF_LEX
    add x1, sp, #OFF_TOK
    bl _aster_lex__next
    cmp x0, #TOK_INT
    b.ne .Lfail

    // emit minimal LLVM IR main that returns that literal
    ldr x0, [sp, #OFF_OUT]
    adrp x1, ir_header@PAGE
    add x1, x1, ir_header@PAGEOFF
    bl _asterc0__emit_cstr

    ldr x0, [sp, #OFF_OUT]
    adrp x1, ir_main_prefix@PAGE
    add x1, x1, ir_main_prefix@PAGEOFF
    bl _asterc0__emit_cstr
    // parse integer literal (decimal or 0x...) and emit as decimal
    ldr x9, [sp, #OFF_SRC]
    ldr w10, [sp, #OFF_TOK + TOK_START]
    ldr w11, [sp, #OFF_TOK + TOK_END]
    uxtw x10, w10
    uxtw x11, w11
    add x0, x9, x10 // ptr
    sub x1, x11, x10 // len
    bl _asterc0__parse_uint_lit
    mov x1, x0
    ldr x0, [sp, #OFF_OUT]
    bl _asterc0__emit_u64
    // function close
    ldr x0, [sp, #OFF_OUT]
    adrp x1, ir_main_suffix@PAGE
    add x1, x1, ir_main_suffix@PAGEOFF
    bl _asterc0__emit_cstr

    mov x0, #0
    b .Ldone

.Lfail:
    mov x0, #1
.Ldone:
    FRAME_LEAVE FRAME_SIZE
FUNC_END asterc0__compile

// void asterc0__emit_cstr(FILE* out, const char* cstr)
// args: x0=out, x1=cstr
FUNC_BEGIN asterc0__emit_cstr
    FRAME_ENTER 32
    str x0, [sp, #0]
    str x1, [sp, #8]
    mov x0, x1
    bl _strlen
    mov x2, x0
    ldr x0, [sp, #8] // ptr
    mov x1, #1
    ldr x3, [sp, #0] // out
    bl _fwrite
    mov x0, #0
    FRAME_LEAVE 32
FUNC_END asterc0__emit_cstr

// void asterc0__emit_bytes(FILE* out, const void* ptr, usize len)
// args: x0=out, x1=ptr, x2=len
FUNC_BEGIN asterc0__emit_bytes
    FRAME_ENTER 0
    mov x3, x0 // out
    mov x0, x1 // ptr
    mov x1, #1
    // x2 already len as nmemb
    // x3 is FILE*
    bl _fwrite
    mov x0, #0
    FRAME_LEAVE 0
FUNC_END asterc0__emit_bytes

// u64 asterc0__parse_uint_lit(const char* ptr, usize len)
// args: x0=ptr, x1=len
FUNC_BEGIN asterc0__parse_uint_lit
    FRAME_ENTER 0
    mov x2, #0          // acc
    mov x3, x0          // p
    mov x4, x1          // n
    mov x5, #10         // base
    // detect 0x / 0X
    cmp x4, #2
    b.lt .Lparse_uint_loop
    ldrb w6, [x3]
    cmp w6, #'0'
    b.ne .Lparse_uint_loop
    ldrb w7, [x3, #1]
    cmp w7, #'x'
    b.eq .Lparse_uint_hex
    cmp w7, #'X'
    b.ne .Lparse_uint_loop
.Lparse_uint_hex:
    add x3, x3, #2
    sub x4, x4, #2
    mov x5, #16

.Lparse_uint_loop:
    cbz x4, .Lparse_uint_done
    ldrb w6, [x3]
    // digit in w6 -> w7
    mov w7, #0
    // '0'..'9'
    cmp w6, #'0'
    b.lt .Lparse_uint_done
    cmp w6, #'9'
    b.le .Lparse_uint_dec
    // 'a'..'f'
    cmp w6, #'a'
    b.lt .Lparse_uint_check_A
    cmp w6, #'f'
    b.le .Lparse_uint_hex_lc
.Lparse_uint_check_A:
    // 'A'..'F'
    cmp w6, #'A'
    b.lt .Lparse_uint_done
    cmp w6, #'F'
    b.gt .Lparse_uint_done
    sub w7, w6, #'A'
    add w7, w7, #10
    b .Lparse_uint_acc
.Lparse_uint_hex_lc:
    sub w7, w6, #'a'
    add w7, w7, #10
    b .Lparse_uint_acc
.Lparse_uint_dec:
    sub w7, w6, #'0'
.Lparse_uint_acc:
    // acc = acc * base + digit
    mul x2, x2, x5
    uxtw x7, w7
    add x2, x2, x7
    add x3, x3, #1
    sub x4, x4, #1
    b .Lparse_uint_loop

.Lparse_uint_done:
    mov x0, x2
    FRAME_LEAVE 0
FUNC_END asterc0__parse_uint_lit

// void asterc0__emit_u64(FILE* out, u64 val)
// args: x0=out, x1=val
FUNC_BEGIN asterc0__emit_u64
    FRAME_ENTER 64
    str x0, [sp, #0]
    str x1, [sp, #8]

    // buffer end at sp+64
    add x2, sp, #64
    mov x3, x2        // p

    ldr x4, [sp, #8]  // v
    cbnz x4, .Lemit_u64_loop
    sub x3, x3, #1
    mov w5, #'0'
    strb w5, [x3]
    b .Lemit_u64_done

.Lemit_u64_loop:
    mov x5, #10
    udiv x6, x4, x5           // q
    msub x7, x6, x5, x4       // r = v - q*10
    add w7, w7, #'0'
    sub x3, x3, #1
    strb w7, [x3]
    mov x4, x6
    cbnz x4, .Lemit_u64_loop

.Lemit_u64_done:
    sub x2, x2, x3    // len = end - p
    // fwrite(p, 1, len, out)
    mov x0, x3
    mov x1, #1
    // x2 is len
    ldr x3, [sp, #0]
    bl _fwrite

    mov x0, #0
    FRAME_LEAVE 64
FUNC_END asterc0__emit_u64

#elif defined(__x86_64__)

// x86_64 compiler stub (arm64-first).
FUNC_BEGIN asterc0__compile
    FRAME_ENTER 0
    movl $1, %eax
    FRAME_LEAVE 0
FUNC_END asterc0__compile

#else
#error "asterc0: unsupported architecture"
#endif
