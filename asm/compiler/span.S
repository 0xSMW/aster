#include "base.inc"
#if defined(__aarch64__)
#include "abi_arm64.inc"
#elif defined(__x86_64__)
#include "abi_x86_64.inc"
#endif
#include "vec.inc"
#include "span.inc"

#if defined(__aarch64__)

FUNC_BEGIN aster_span__span_init
    FRAME_ENTER 0
    mov x4, x0
    str w1, [x4, #SPAN_FILE]
    str w2, [x4, #SPAN_LO]
    str w3, [x4, #SPAN_HI]
    mov x0, #0
    FRAME_LEAVE 0
FUNC_END aster_span__span_init

FUNC_BEGIN aster_span__sourcemap_init
    FRAME_ENTER 0
    mov x1, #FILE_ENTRY_SIZE
    mov x2, #4
    bl _aster_rt__vec_init
    FRAME_LEAVE 0
FUNC_END aster_span__sourcemap_init

FUNC_BEGIN aster_span__sourcemap_add
    FRAME_ENTER 64
    mov x5, x0
    ldr x6, [x5, #VEC_LEN]
    mov x7, x6
    str x7, [sp, #32]

    // build FileEntry on stack
    add x8, sp, #0
    str x1, [x8, #FILE_PATH_PTR]
    str x2, [x8, #FILE_PATH_LEN]
    str x3, [x8, #FILE_SRC_PTR]
    str x4, [x8, #FILE_SRC_LEN]

    mov x0, x5
    mov x1, x8
    bl _aster_rt__vec_push
    cbnz x0, .Lsourcemap_add_fail
    ldr x0, [sp, #32]
    b .Lsourcemap_add_done
.Lsourcemap_add_fail:
    mov x0, #0
    mvn x0, x0
.Lsourcemap_add_done:
    FRAME_LEAVE 64
FUNC_END aster_span__sourcemap_add

FUNC_BEGIN aster_span__sourcemap_line_col
    FRAME_ENTER 0
    mov x5, x0
    mov x6, x1
    mov x7, x2
    mov x8, x3
    mov x9, x4

    ldr x10, [x5, #VEC_LEN]
    cmp x6, x10
    b.hs .Llinecol_fail

    ldr x11, [x5, #VEC_PTR]
    mov x12, #FILE_ENTRY_SIZE
    mul x13, x6, x12
    add x11, x11, x13

    ldr x14, [x11, #FILE_SRC_PTR]
    ldr x15, [x11, #FILE_SRC_LEN]
    cmp x7, x15
    b.ls .Llinecol_offset_ok
    mov x7, x15
.Llinecol_offset_ok:

    mov x16, #1
    mov x17, #1
    mov x18, #0

.Llinecol_loop:
    cmp x18, x7
    b.hs .Llinecol_done
    ldrb w19, [x14, x18]
    cmp w19, #10
    b.ne .Llinecol_not_nl
    add x16, x16, #1
    mov x17, #1
    b .Llinecol_step
.Llinecol_not_nl:
    add x17, x17, #1
.Llinecol_step:
    add x18, x18, #1
    b .Llinecol_loop

.Llinecol_done:
    str x16, [x8]
    str x17, [x9]
    mov x0, #0
    b .Llinecol_exit

.Llinecol_fail:
    mov x0, #1

.Llinecol_exit:
    FRAME_LEAVE 0
FUNC_END aster_span__sourcemap_line_col

#else
#if defined(__x86_64__)

FUNC_BEGIN aster_span__span_init
    FRAME_ENTER 0
    movq %rdi, %r8
    movl %esi, SPAN_FILE(%r8)
    movl %edx, SPAN_LO(%r8)
    movl %ecx, SPAN_HI(%r8)
    xorq %rax, %rax
    FRAME_LEAVE 0
FUNC_END aster_span__span_init

FUNC_BEGIN aster_span__sourcemap_init
    FRAME_ENTER 0
    movq $FILE_ENTRY_SIZE, %rsi
    movq $4, %rdx
    callq _aster_rt__vec_init
    FRAME_LEAVE 0
FUNC_END aster_span__sourcemap_init

FUNC_BEGIN aster_span__sourcemap_add
    FRAME_ENTER 64
    movq %r8, %r11
    movq %rdi, %r8
    movq VEC_LEN(%r8), %r9
    movq %r9, 32(%rsp)

    leaq 0(%rsp), %r10
    movq %rsi, FILE_PATH_PTR(%r10)
    movq %rdx, FILE_PATH_LEN(%r10)
    movq %rcx, FILE_SRC_PTR(%r10)
    movq %r11, FILE_SRC_LEN(%r10)

    movq %r8, %rdi
    movq %r10, %rsi
    callq _aster_rt__vec_push
    testq %rax, %rax
    jne .Lsourcemap_add_fail_x86
    movq 32(%rsp), %rax
    jmp .Lsourcemap_add_done_x86
.Lsourcemap_add_fail_x86:
    movq $-1, %rax
.Lsourcemap_add_done_x86:
    FRAME_LEAVE 64
FUNC_END aster_span__sourcemap_add

FUNC_BEGIN aster_span__sourcemap_line_col
    FRAME_ENTER 16
    movq %rcx, 0(%rsp)
    movq %r8, 8(%rsp)
    movq %rdi, %r9
    movq %rsi, %r10
    movq %rdx, %r11

    movq VEC_LEN(%r9), %rax
    cmpq %r10, %rax
    jbe .Llinecol_fail_x86

    movq VEC_PTR(%r9), %rdi
    movq $FILE_ENTRY_SIZE, %rcx
    imulq %r10, %rcx
    addq %rcx, %rdi

    movq FILE_SRC_PTR(%rdi), %r8
    movq FILE_SRC_LEN(%rdi), %r9
    cmpq %r9, %r11
    jbe .Llinecol_offset_ok_x86
    movq %r9, %r11
.Llinecol_offset_ok_x86:

    movq $1, %rsi
    movq $1, %rdx
    xorq %rcx, %rcx
.Llinecol_loop_x86:
    cmpq %r11, %rcx
    jae .Llinecol_done_x86
    movzbl (%r8,%rcx,1), %eax
    cmpb $10, %al
    jne .Llinecol_not_nl_x86
    addq $1, %rsi
    movq $1, %rdx
    jmp .Llinecol_step_x86
.Llinecol_not_nl_x86:
    addq $1, %rdx
.Llinecol_step_x86:
    addq $1, %rcx
    jmp .Llinecol_loop_x86

.Llinecol_done_x86:
    movq 0(%rsp), %rdi
    movq %rsi, (%rdi)
    movq 8(%rsp), %rdi
    movq %rdx, (%rdi)
    xorq %rax, %rax
    jmp .Llinecol_exit_x86

.Llinecol_fail_x86:
    movq $1, %rax

.Llinecol_exit_x86:
    FRAME_LEAVE 16
FUNC_END aster_span__sourcemap_line_col

#else
#error "span: unsupported architecture"
#endif
#endif
