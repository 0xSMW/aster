#include "base.inc"
#if defined(__aarch64__)
#include "abi_arm64.inc"
#elif defined(__x86_64__)
#include "abi_x86_64.inc"
#endif
#include "vec.inc"
#include "span.inc"
#include "diagnostics.inc"

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

#else
#error "diagnostics: unsupported architecture"
#endif
#endif
