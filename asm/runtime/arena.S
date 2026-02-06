#include "base.inc"
#if defined(__aarch64__)
#include "abi_arm64.inc"
#elif defined(__x86_64__)
#include "abi_x86_64.inc"
#endif
#include "arena.inc"

#if defined(__aarch64__)

FUNC_BEGIN aster_rt__arena_init
    FRAME_ENTER 16
    str x0, [sp, #0]
    str x1, [sp, #8]
    mov x0, x1
    bl _malloc
    cbz x0, .Larena_init_fail
    ldr x2, [sp, #0]
    ldr x3, [sp, #8]
    str x0, [x2, #ARENA_PTR]
    str x3, [x2, #ARENA_CAP]
    mov x4, #0
    str x4, [x2, #ARENA_OFF]
    mov x0, #0
    b .Larena_init_done
.Larena_init_fail:
    mov x0, #1
.Larena_init_done:
    FRAME_LEAVE 16
FUNC_END aster_rt__arena_init

FUNC_BEGIN aster_rt__arena_alloc
    FRAME_ENTER 0
    mov x3, x0
    ldr x4, [x3, #ARENA_OFF]
    ldr x5, [x3, #ARENA_CAP]
    ldr x6, [x3, #ARENA_PTR]
    sub x7, x2, #1
    add x4, x4, x7
    mvn x7, x7
    and x4, x4, x7
    add x8, x4, x1
    cmp x8, x5
    b.hi .Larena_alloc_fail
    str x8, [x3, #ARENA_OFF]
    add x0, x6, x4
    b .Larena_alloc_done
.Larena_alloc_fail:
    mov x0, #0
.Larena_alloc_done:
    FRAME_LEAVE 0
FUNC_END aster_rt__arena_alloc

FUNC_BEGIN aster_rt__arena_reset
    FRAME_ENTER 0
    mov x1, #0
    str x1, [x0, #ARENA_OFF]
    mov x0, #0
    FRAME_LEAVE 0
FUNC_END aster_rt__arena_reset

FUNC_BEGIN aster_rt__arena_free
    FRAME_ENTER 0
    mov x1, x0
    ldr x0, [x1, #ARENA_PTR]
    cbz x0, .Larena_free_done
    bl _free
    mov x2, #0
    str x2, [x1, #ARENA_PTR]
    str x2, [x1, #ARENA_CAP]
    str x2, [x1, #ARENA_OFF]
.Larena_free_done:
    mov x0, #0
    FRAME_LEAVE 0
FUNC_END aster_rt__arena_free

#else
#if defined(__x86_64__)

FUNC_BEGIN aster_rt__arena_init
    FRAME_ENTER 16
    movq %rdi, 0(%rsp)
    movq %rsi, 8(%rsp)
    movq %rsi, %rdi
    callq _malloc
    testq %rax, %rax
    je .Larena_init_fail_x86
    movq 0(%rsp), %r8
    movq 8(%rsp), %r9
    movq %rax, ARENA_PTR(%r8)
    movq %r9, ARENA_CAP(%r8)
    xorq %r10, %r10
    movq %r10, ARENA_OFF(%r8)
    xorq %rax, %rax
    jmp .Larena_init_done_x86
.Larena_init_fail_x86:
    movq $1, %rax
.Larena_init_done_x86:
    FRAME_LEAVE 16
FUNC_END aster_rt__arena_init

FUNC_BEGIN aster_rt__arena_alloc
    FRAME_ENTER 0
    movq %rdi, %r8
    movq ARENA_OFF(%r8), %r9
    movq ARENA_CAP(%r8), %r10
    movq ARENA_PTR(%r8), %r11
    movq %rdx, %rcx
    subq $1, %rcx
    addq %rcx, %r9
    movq %rcx, %rax
    notq %rax
    andq %rax, %r9
    movq %r9, %rax
    addq %rsi, %rax
    cmpq %r10, %rax
    ja .Larena_alloc_fail_x86
    movq %rax, ARENA_OFF(%r8)
    addq %r11, %r9
    movq %r9, %rax
    jmp .Larena_alloc_done_x86
.Larena_alloc_fail_x86:
    xorq %rax, %rax
.Larena_alloc_done_x86:
    FRAME_LEAVE 0
FUNC_END aster_rt__arena_alloc

FUNC_BEGIN aster_rt__arena_reset
    FRAME_ENTER 0
    xorq %rax, %rax
    movq %rax, ARENA_OFF(%rdi)
    xorq %rax, %rax
    FRAME_LEAVE 0
FUNC_END aster_rt__arena_reset

FUNC_BEGIN aster_rt__arena_free
    FRAME_ENTER 0
    movq %rdi, %r8
    movq ARENA_PTR(%r8), %rdi
    testq %rdi, %rdi
    je .Larena_free_done_x86
    callq _free
    xorq %r9, %r9
    movq %r9, ARENA_PTR(%r8)
    movq %r9, ARENA_CAP(%r8)
    movq %r9, ARENA_OFF(%r8)
.Larena_free_done_x86:
    xorq %rax, %rax
    FRAME_LEAVE 0
FUNC_END aster_rt__arena_free

#else
#error "arena: unsupported architecture"
#endif
#endif
