#include "base.inc"
#if defined(__aarch64__)
#include "abi_arm64.inc"
#elif defined(__x86_64__)
#include "abi_x86_64.inc"
#endif
#include "vec.inc"
#include "span.inc"
#include "diagnostics.inc"

.section __TEXT,__cstring,cstring_literals
.p2align 2
diag_fmt:
    .asciz "%.*s:%llu:%llu: %.*s\n"
unk_path:
    .asciz "?"

// Render diagnostics to stderr.
// uint64_t aster_diag__render(Diags* diags, SourceMap* sm)
.equ R_OFF_DIAGS, 0
.equ R_OFF_SM, 8
.equ R_OFF_PTR, 16
.equ R_OFF_LEN, 24
.equ R_OFF_IDX, 32
.equ R_OFF_LINE, 40
.equ R_OFF_COL, 48
.equ R_OFF_FILEID, 56
.equ R_OFF_MSG_PTR, 64
.equ R_OFF_MSG_LEN, 72
.equ R_FRAME_SIZE, 96

#if defined(__aarch64__)

FUNC_BEGIN aster_diag__init
    FRAME_ENTER 0
    mov x1, #DIAG_SIZE
    mov x2, #8
    bl _aster_rt__vec_init
    FRAME_LEAVE 0
FUNC_END aster_diag__init

FUNC_BEGIN aster_diag__push
    FRAME_ENTER 64
    mov x6, x0
    mov x7, x1
    mov x8, x2
    mov x9, x3
    mov x10, x4
    mov x11, x5

    add x15, sp, #0
    str w7, [x15, #DIAG_LEVEL]
    str w8, [x15, #DIAG_CODE]

    ldr w16, [x9, #SPAN_FILE]
    ldr w17, [x9, #SPAN_LO]
    ldr w18, [x9, #SPAN_HI]
    str w16, [x15, #DIAG_SPAN + SPAN_FILE]
    str w17, [x15, #DIAG_SPAN + SPAN_LO]
    str w18, [x15, #DIAG_SPAN + SPAN_HI]

    str x10, [x15, #DIAG_MSG_PTR]
    str x11, [x15, #DIAG_MSG_LEN]

    mov x0, x6
    mov x1, x15
    bl _aster_rt__vec_push
    FRAME_LEAVE 64
FUNC_END aster_diag__push

FUNC_BEGIN aster_diag__count
    FRAME_ENTER 0
    ldr x0, [x0, #VEC_LEN]
    FRAME_LEAVE 0
FUNC_END aster_diag__count

FUNC_BEGIN aster_diag__render
    FRAME_ENTER R_FRAME_SIZE
    str x0, [sp, #R_OFF_DIAGS]
    str x1, [sp, #R_OFF_SM]

    ldr x2, [x0, #VEC_PTR]
    ldr x3, [x0, #VEC_LEN]
    str x2, [sp, #R_OFF_PTR]
    str x3, [sp, #R_OFF_LEN]
    mov x4, #0
    str x4, [sp, #R_OFF_IDX]

.Lrender_loop:
    ldr x4, [sp, #R_OFF_IDX]
    ldr x3, [sp, #R_OFF_LEN]
    cmp x4, x3
    b.hs .Lrender_done

    // diagp = ptr + idx*DIAG_SIZE
    ldr x2, [sp, #R_OFF_PTR]
    mov x5, #DIAG_SIZE
    mul x6, x4, x5
    add x6, x2, x6

    // msg ptr/len
    ldr x7, [x6, #DIAG_MSG_PTR]
    ldr x8, [x6, #DIAG_MSG_LEN]
    str x7, [sp, #R_OFF_MSG_PTR]
    str x8, [sp, #R_OFF_MSG_LEN]

    // defaults
    str xzr, [sp, #R_OFF_LINE]
    str xzr, [sp, #R_OFF_COL]
    adrp x10, unk_path@PAGE
    add x10, x10, unk_path@PAGEOFF
    mov x11, #1 // path len

    // sourcemap lookup + line/col
    ldr x9, [sp, #R_OFF_SM]
    cbz x9, .Lrender_have_loc
    ldr w12, [x6, #DIAG_SPAN + SPAN_FILE]
    uxtw x12, w12
    str x12, [sp, #R_OFF_FILEID]
    ldr x13, [x9, #VEC_LEN]
    cmp x12, x13
    b.hs .Lrender_have_loc
    ldr w14, [x6, #DIAG_SPAN + SPAN_LO]
    uxtw x14, w14

    // aster_span__sourcemap_line_col(sm, fileid, off, &line, &col)
    mov x0, x9
    mov x1, x12
    mov x2, x14
    add x3, sp, #R_OFF_LINE
    add x4, sp, #R_OFF_COL
    bl _aster_span__sourcemap_line_col

    // caller-saved regs may be clobbered by the call; reload
    ldr x9, [sp, #R_OFF_SM]
    ldr x12, [sp, #R_OFF_FILEID]

    // file entry -> path
    ldr x15, [x9, #VEC_PTR]
    mov x16, #FILE_ENTRY_SIZE
    mul x17, x12, x16
    add x15, x15, x17
    ldr x10, [x15, #FILE_PATH_PTR]
    ldr x11, [x15, #FILE_PATH_LEN]

.Lrender_have_loc:
    // dprintf(2, fmt, path_len, path_ptr, line, col, msg_len, msg_ptr)
    //
    // Darwin arm64 varargs are passed on the stack (clang does not populate x2-x7).
    // Store 6 x 8-byte varargs at the call stack top.
    ldr x4, [sp, #R_OFF_LINE]
    ldr x5, [sp, #R_OFF_COL]
    ldr x6, [sp, #R_OFF_MSG_LEN]
    ldr x7, [sp, #R_OFF_MSG_PTR]
    sub sp, sp, #48
    str x11, [sp, #0]   // path_len (int)
    str x10, [sp, #8]   // path_ptr
    str x4, [sp, #16]   // line
    str x5, [sp, #24]   // col
    str x6, [sp, #32]   // msg_len (int)
    str x7, [sp, #40]   // msg_ptr
    mov x0, #2
    adrp x1, diag_fmt@PAGE
    add x1, x1, diag_fmt@PAGEOFF
    bl _dprintf
    add sp, sp, #48

    // idx++
    ldr x4, [sp, #R_OFF_IDX]
    add x4, x4, #1
    str x4, [sp, #R_OFF_IDX]
    b .Lrender_loop

.Lrender_done:
    mov x0, #0
    FRAME_LEAVE R_FRAME_SIZE
FUNC_END aster_diag__render

#else
#if defined(__x86_64__)

FUNC_BEGIN aster_diag__init
    FRAME_ENTER 0
    movq $DIAG_SIZE, %rsi
    movq $8, %rdx
    callq _aster_rt__vec_init
    FRAME_LEAVE 0
FUNC_END aster_diag__init

FUNC_BEGIN aster_diag__push
    FRAME_ENTER 64
    movq %rdi, %r10
    movl %esi, DIAG_LEVEL(%rsp)
    movl %edx, DIAG_CODE(%rsp)

    movl SPAN_FILE(%rcx), %eax
    movl %eax, DIAG_SPAN + SPAN_FILE(%rsp)
    movl SPAN_LO(%rcx), %eax
    movl %eax, DIAG_SPAN + SPAN_LO(%rsp)
    movl SPAN_HI(%rcx), %eax
    movl %eax, DIAG_SPAN + SPAN_HI(%rsp)

    movq %r8, DIAG_MSG_PTR(%rsp)
    movq %r9, DIAG_MSG_LEN(%rsp)

    movq %r10, %rdi
    leaq 0(%rsp), %rsi
    callq _aster_rt__vec_push
    FRAME_LEAVE 64
FUNC_END aster_diag__push

FUNC_BEGIN aster_diag__count
    FRAME_ENTER 0
    movq VEC_LEN(%rdi), %rax
    FRAME_LEAVE 0
FUNC_END aster_diag__count

FUNC_BEGIN aster_diag__render
    FRAME_ENTER R_FRAME_SIZE
    movq %rdi, R_OFF_DIAGS(%rsp)
    movq %rsi, R_OFF_SM(%rsp)

    movq VEC_PTR(%rdi), %rax
    movq %rax, R_OFF_PTR(%rsp)
    movq VEC_LEN(%rdi), %rax
    movq %rax, R_OFF_LEN(%rsp)
    xorq %rax, %rax
    movq %rax, R_OFF_IDX(%rsp)

.Lrender_loop_x86:
    movq R_OFF_IDX(%rsp), %rax
    cmpq R_OFF_LEN(%rsp), %rax
    jae .Lrender_done_x86

    movq R_OFF_PTR(%rsp), %rcx
    movq $DIAG_SIZE, %rdx
    imulq %rdx, %rax
    leaq (%rcx,%rax,1), %r8

    movq DIAG_MSG_PTR(%r8), %rax
    movq %rax, R_OFF_MSG_PTR(%rsp)
    movq DIAG_MSG_LEN(%r8), %rax
    movq %rax, R_OFF_MSG_LEN(%rsp)

    movq $0, R_OFF_LINE(%rsp)
    movq $0, R_OFF_COL(%rsp)

    leaq unk_path(%rip), %r10
    movq $1, %r11

    movq R_OFF_SM(%rsp), %rdi
    testq %rdi, %rdi
    je .Lrender_have_loc_x86

    movl DIAG_SPAN + SPAN_FILE(%r8), %eax
    movq %rax, R_OFF_FILEID(%rsp)
    movq VEC_LEN(%rdi), %rcx
    cmpq %rcx, %rax
    jae .Lrender_have_loc_x86

    movl DIAG_SPAN + SPAN_LO(%r8), %edx
    movq %rax, %rsi
    leaq R_OFF_LINE(%rsp), %rcx
    leaq R_OFF_COL(%rsp), %r8
    callq _aster_span__sourcemap_line_col

    // caller-saved regs may be clobbered by the call; reload
    movq R_OFF_SM(%rsp), %rdi

    movq VEC_PTR(%rdi), %rcx
    movq R_OFF_FILEID(%rsp), %rax
    movq $FILE_ENTRY_SIZE, %rdx
    imulq %rdx, %rax
    addq %rax, %rcx
    movq FILE_PATH_PTR(%rcx), %r10
    movq FILE_PATH_LEN(%rcx), %r11

.Lrender_have_loc_x86:
    movq R_OFF_LINE(%rsp), %r8
    movq R_OFF_COL(%rsp), %r9

    movq $2, %rdi
    leaq diag_fmt(%rip), %rsi
    movq %r11, %rdx
    movq %r10, %rcx

    movq R_OFF_MSG_LEN(%rsp), %rax
    movq R_OFF_MSG_PTR(%rsp), %r10
    subq $16, %rsp
    movq %rax, 0(%rsp)
    movq %r10, 8(%rsp)
    xor %eax, %eax
    callq _dprintf
    addq $16, %rsp

    movq R_OFF_IDX(%rsp), %rax
    addq $1, %rax
    movq %rax, R_OFF_IDX(%rsp)
    jmp .Lrender_loop_x86

.Lrender_done_x86:
    xorq %rax, %rax
    FRAME_LEAVE R_FRAME_SIZE
FUNC_END aster_diag__render

#else
#error "diagnostics: unsupported architecture"
#endif
#endif
