#include "base.inc"
#if defined(__aarch64__)
#include "abi_arm64.inc"
#elif defined(__x86_64__)
#include "abi_x86_64.inc"
#endif
#include "vec.inc"

#if defined(__aarch64__)

FUNC_BEGIN aster_rt__vec_init
    FRAME_ENTER 32
    str x0, [sp, #0]
    str x1, [sp, #8]
    str x2, [sp, #16]
    mov x3, x0
    mov x4, x1
    mov x5, x2
    str x4, [x3, #VEC_ELEM]
    mov x6, #0
    str x6, [x3, #VEC_LEN]
    str x5, [x3, #VEC_CAP]
    cbz x5, .Lvec_init_zero
    mul x0, x5, x4
    bl _malloc
    cbz x0, .Lvec_init_fail
    ldr x3, [sp, #0]
    str x0, [x3, #VEC_PTR]
    mov x0, #0
    b .Lvec_init_done
.Lvec_init_zero:
    ldr x3, [sp, #0]
    mov x0, #0
    str x0, [x3, #VEC_PTR]
    b .Lvec_init_done
.Lvec_init_fail:
    mov x0, #1
.Lvec_init_done:
    FRAME_LEAVE 32
FUNC_END aster_rt__vec_init

FUNC_BEGIN aster_rt__vec_free
    FRAME_ENTER 0
    mov x1, x0
    ldr x0, [x1, #VEC_PTR]
    cbz x0, .Lvec_free_done
    bl _free
    mov x2, #0
    str x2, [x1, #VEC_PTR]
    str x2, [x1, #VEC_LEN]
    str x2, [x1, #VEC_CAP]
.Lvec_free_done:
    mov x0, #0
    FRAME_LEAVE 0
FUNC_END aster_rt__vec_free

FUNC_BEGIN aster_rt__vec_reserve
    FRAME_ENTER 32
    str x0, [sp, #0]
    str x1, [sp, #8]
    mov x3, x0
    mov x4, x1
    ldr x5, [x3, #VEC_CAP]
    cmp x5, x4
    b.hs .Lvec_reserve_ok
    ldr x6, [x3, #VEC_ELEM]
    mul x7, x4, x6
    ldr x0, [x3, #VEC_PTR]
    cbz x0, .Lvec_reserve_malloc
    mov x1, x7
    bl _realloc
    cbz x0, .Lvec_reserve_fail
    ldr x3, [sp, #0]
    ldr x4, [sp, #8]
    str x0, [x3, #VEC_PTR]
    str x4, [x3, #VEC_CAP]
    mov x0, #0
    b .Lvec_reserve_done
.Lvec_reserve_malloc:
    mov x0, x7
    bl _malloc
    cbz x0, .Lvec_reserve_fail
    ldr x3, [sp, #0]
    ldr x4, [sp, #8]
    str x0, [x3, #VEC_PTR]
    str x4, [x3, #VEC_CAP]
    mov x0, #0
    b .Lvec_reserve_done
.Lvec_reserve_ok:
    mov x0, #0
    b .Lvec_reserve_done
.Lvec_reserve_fail:
    mov x0, #1
.Lvec_reserve_done:
    FRAME_LEAVE 32
FUNC_END aster_rt__vec_reserve

FUNC_BEGIN aster_rt__vec_push
    FRAME_ENTER 32
    str x0, [sp, #0]
    str x1, [sp, #8]
    mov x3, x0
    mov x4, x1
    ldr x5, [x3, #VEC_LEN]
    ldr x6, [x3, #VEC_CAP]
    cmp x5, x6
    b.ne .Lvec_push_has_cap
    cbz x6, .Lvec_push_init_cap
    lsl x7, x6, #1
    b .Lvec_push_grow
.Lvec_push_init_cap:
    mov x7, #8
.Lvec_push_grow:
    mov x0, x3
    mov x1, x7
    bl _aster_rt__vec_reserve
    cbnz x0, .Lvec_push_fail
    ldr x3, [sp, #0]
.Lvec_push_has_cap:
    ldr x8, [x3, #VEC_PTR]
    ldr x9, [x3, #VEC_ELEM]
    mul x10, x5, x9
    add x8, x8, x10
    mov x0, x8
    ldr x1, [sp, #8]
    mov x2, x9
    bl _memcpy
    ldr x3, [sp, #0]
    add x5, x5, #1
    str x5, [x3, #VEC_LEN]
    mov x0, #0
    b .Lvec_push_done
.Lvec_push_fail:
    mov x0, #1
.Lvec_push_done:
    FRAME_LEAVE 32
FUNC_END aster_rt__vec_push

#else
#if defined(__x86_64__)

FUNC_BEGIN aster_rt__vec_init
    FRAME_ENTER 32
    movq %rdi, 0(%rsp)
    movq %rsi, 8(%rsp)
    movq %rdx, 16(%rsp)

    movq %rdi, %r8
    movq %rsi, %r9
    movq %rdx, %r10
    movq %r9, VEC_ELEM(%r8)
    xorq %r11, %r11
    movq %r11, VEC_LEN(%r8)
    movq %r10, VEC_CAP(%r8)
    testq %r10, %r10
    je .Lvec_init_zero_x86
    movq %r10, %rdi
    imulq %r9, %rdi
    callq _malloc
    testq %rax, %rax
    je .Lvec_init_fail_x86
    movq 0(%rsp), %r8
    movq %rax, VEC_PTR(%r8)
    xorq %rax, %rax
    jmp .Lvec_init_done_x86
.Lvec_init_zero_x86:
    movq 0(%rsp), %r8
    xorq %rax, %rax
    movq %rax, VEC_PTR(%r8)
    jmp .Lvec_init_done_x86
.Lvec_init_fail_x86:
    movq $1, %rax
.Lvec_init_done_x86:
    FRAME_LEAVE 32
FUNC_END aster_rt__vec_init

FUNC_BEGIN aster_rt__vec_free
    FRAME_ENTER 0
    movq %rdi, %r8
    movq VEC_PTR(%r8), %rdi
    testq %rdi, %rdi
    je .Lvec_free_done_x86
    callq _free
    xorq %r9, %r9
    movq %r9, VEC_PTR(%r8)
    movq %r9, VEC_LEN(%r8)
    movq %r9, VEC_CAP(%r8)
.Lvec_free_done_x86:
    xorq %rax, %rax
    FRAME_LEAVE 0
FUNC_END aster_rt__vec_free

FUNC_BEGIN aster_rt__vec_reserve
    FRAME_ENTER 32
    movq %rdi, 0(%rsp)
    movq %rsi, 8(%rsp)
    movq %rdi, %r8
    movq %rsi, %r9
    movq VEC_CAP(%r8), %r10
    cmpq %r10, %r9
    ja .Lvec_reserve_grow_x86
    xorq %rax, %rax
    jmp .Lvec_reserve_done_x86
.Lvec_reserve_grow_x86:
    movq VEC_ELEM(%r8), %r11
    movq %r9, %rax
    imulq %r11, %rax
    movq VEC_PTR(%r8), %rcx
    testq %rcx, %rcx
    je .Lvec_reserve_malloc_x86
    movq %rcx, %rdi
    movq %rax, %rsi
    callq _realloc
    testq %rax, %rax
    je .Lvec_reserve_fail_x86
    movq 0(%rsp), %r8
    movq 8(%rsp), %r9
    movq %rax, VEC_PTR(%r8)
    movq %r9, VEC_CAP(%r8)
    xorq %rax, %rax
    jmp .Lvec_reserve_done_x86
.Lvec_reserve_malloc_x86:
    movq %rax, %rdi
    callq _malloc
    testq %rax, %rax
    je .Lvec_reserve_fail_x86
    movq 0(%rsp), %r8
    movq 8(%rsp), %r9
    movq %rax, VEC_PTR(%r8)
    movq %r9, VEC_CAP(%r8)
    xorq %rax, %rax
    jmp .Lvec_reserve_done_x86
.Lvec_reserve_fail_x86:
    movq $1, %rax
.Lvec_reserve_done_x86:
    FRAME_LEAVE 32
FUNC_END aster_rt__vec_reserve

FUNC_BEGIN aster_rt__vec_push
    FRAME_ENTER 32
    movq %rdi, 0(%rsp)
    movq %rsi, 8(%rsp)
    movq %rdi, %r8
    movq %rsi, %r9
    movq VEC_LEN(%r8), %r10
    movq VEC_CAP(%r8), %r11
    cmpq %r10, %r11
    jne .Lvec_push_has_cap_x86
    testq %r11, %r11
    jne .Lvec_push_double_x86
    movq $8, %rax
    jmp .Lvec_push_grow_x86
.Lvec_push_double_x86:
    leaq (,%r11,2), %rax
.Lvec_push_grow_x86:
    movq %r8, %rdi
    movq %rax, %rsi
    callq _aster_rt__vec_reserve
    testq %rax, %rax
    jne .Lvec_push_fail_x86
    movq 0(%rsp), %r8
.Lvec_push_has_cap_x86:
    movq VEC_PTR(%r8), %rcx
    movq VEC_ELEM(%r8), %rdx
    movq %r10, %rax
    imulq %rdx, %rax
    addq %rax, %rcx
    movq %rcx, %rdi
    movq 8(%rsp), %rsi
    callq _memcpy
    movq 0(%rsp), %r8
    addq $1, %r10
    movq %r10, VEC_LEN(%r8)
    xorq %rax, %rax
    jmp .Lvec_push_done_x86
.Lvec_push_fail_x86:
    movq $1, %rax
.Lvec_push_done_x86:
    FRAME_LEAVE 32
FUNC_END aster_rt__vec_push

#else
#error "vec: unsupported architecture"
#endif
#endif
