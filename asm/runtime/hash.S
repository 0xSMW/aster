#include "base.inc"
#if defined(__aarch64__)
#include "abi_arm64.inc"
#elif defined(__x86_64__)
#include "abi_x86_64.inc"
#endif
#include "hash.inc"

#if defined(__aarch64__)

FUNC_BEGIN aster_rt__map_init
    FRAME_ENTER 32
    str x0, [sp, #0]
    str x1, [sp, #8]
    mov x3, x0
    mov x4, x1
    str x4, [x3, #MAP_CAP]
    mov x5, #0
    str x5, [x3, #MAP_LEN]
    cbz x4, .Lmap_init_zero
    lsl x0, x4, #3
    bl _malloc
    cbz x0, .Lmap_init_fail
    mov x6, x0
    lsl x0, x4, #3
    bl _malloc
    cbz x0, .Lmap_init_fail_free
    mov x7, x0
    mov x0, x6
    mov x1, #0
    lsl x2, x4, #3
    bl _memset
    ldr x3, [sp, #0]
    str x6, [x3, #MAP_KEYS]
    str x7, [x3, #MAP_VALS]
    mov x0, #0
    b .Lmap_init_done
.Lmap_init_fail_free:
    mov x0, x6
    bl _free
.Lmap_init_fail:
    mov x0, #1
    b .Lmap_init_done
.Lmap_init_zero:
    ldr x3, [sp, #0]
    mov x0, #0
    str x0, [x3, #MAP_KEYS]
    str x0, [x3, #MAP_VALS]
.Lmap_init_done:
    FRAME_LEAVE 32
FUNC_END aster_rt__map_init

FUNC_BEGIN aster_rt__map_free
    FRAME_ENTER 0
    mov x1, x0
    ldr x0, [x1, #MAP_KEYS]
    cbz x0, .Lmap_free_vals
    bl _free
.Lmap_free_vals:
    ldr x0, [x1, #MAP_VALS]
    cbz x0, .Lmap_free_done
    bl _free
.Lmap_free_done:
    mov x2, #0
    str x2, [x1, #MAP_KEYS]
    str x2, [x1, #MAP_VALS]
    str x2, [x1, #MAP_CAP]
    str x2, [x1, #MAP_LEN]
    mov x0, #0
    FRAME_LEAVE 0
FUNC_END aster_rt__map_free

FUNC_BEGIN aster_rt__map_put
    FRAME_ENTER 0
    mov x3, x0
    mov x4, x1
    mov x5, x2
    cbz x4, .Lmap_put_badkey
    ldr x6, [x3, #MAP_CAP]
    cbz x6, .Lmap_put_full
    sub x7, x6, #1
    and x8, x4, x7
    ldr x9, [x3, #MAP_KEYS]
    ldr x10, [x3, #MAP_VALS]
    mov x11, #0
.Lmap_put_loop:
    lsl x12, x8, #3
    ldr x13, [x9, x12]
    cbz x13, .Lmap_put_insert
    cmp x13, x4
    b.eq .Lmap_put_insert
    add x8, x8, #1
    and x8, x8, x7
    add x11, x11, #1
    cmp x11, x6
    b.lo .Lmap_put_loop
    b .Lmap_put_full
.Lmap_put_insert:
    cbnz x13, .Lmap_put_update
    ldr x14, [x3, #MAP_LEN]
    add x14, x14, #1
    str x14, [x3, #MAP_LEN]
.Lmap_put_update:
    str x4, [x9, x12]
    str x5, [x10, x12]
    mov x0, #0
    b .Lmap_put_done
.Lmap_put_full:
    mov x0, #1
    b .Lmap_put_done
.Lmap_put_badkey:
    mov x0, #2
.Lmap_put_done:
    FRAME_LEAVE 0
FUNC_END aster_rt__map_put

FUNC_BEGIN aster_rt__map_get
    FRAME_ENTER 0
    mov x3, x0
    mov x4, x1
    mov x5, x2
    cbz x4, .Lmap_get_notfound
    ldr x6, [x3, #MAP_CAP]
    cbz x6, .Lmap_get_notfound
    sub x7, x6, #1
    and x8, x4, x7
    ldr x9, [x3, #MAP_KEYS]
    ldr x10, [x3, #MAP_VALS]
    mov x11, #0
.Lmap_get_loop:
    lsl x12, x8, #3
    ldr x13, [x9, x12]
    cbz x13, .Lmap_get_notfound
    cmp x13, x4
    b.eq .Lmap_get_found
    add x8, x8, #1
    and x8, x8, x7
    add x11, x11, #1
    cmp x11, x6
    b.lo .Lmap_get_loop
    b .Lmap_get_notfound
.Lmap_get_found:
    ldr x14, [x10, x12]
    str x14, [x5]
    mov x0, #1
    b .Lmap_get_done
.Lmap_get_notfound:
    mov x0, #0
.Lmap_get_done:
    FRAME_LEAVE 0
FUNC_END aster_rt__map_get

#else
#if defined(__x86_64__)

FUNC_BEGIN aster_rt__map_init
    FRAME_ENTER 32
    movq %rdi, 0(%rsp)
    movq %rsi, 8(%rsp)
    movq %rdi, %r8
    movq %rsi, %r9
    movq %r9, MAP_CAP(%r8)
    xorq %r10, %r10
    movq %r10, MAP_LEN(%r8)
    testq %r9, %r9
    je .Lmap_init_zero_x86
    movq %r9, %rdi
    shlq $3, %rdi
    callq _malloc
    testq %rax, %rax
    je .Lmap_init_fail_x86
    movq %rax, %r11
    movq %r9, %rdi
    shlq $3, %rdi
    callq _malloc
    testq %rax, %rax
    je .Lmap_init_fail_free_x86
    movq %rax, %r12
    movq %r11, %rdi
    xorq %rsi, %rsi
    movq %r9, %rdx
    shlq $3, %rdx
    callq _memset
    movq 0(%rsp), %r8
    movq %r11, MAP_KEYS(%r8)
    movq %r12, MAP_VALS(%r8)
    xorq %rax, %rax
    jmp .Lmap_init_done_x86
.Lmap_init_fail_free_x86:
    movq %r11, %rdi
    callq _free
.Lmap_init_fail_x86:
    movq $1, %rax
    jmp .Lmap_init_done_x86
.Lmap_init_zero_x86:
    movq 0(%rsp), %r8
    xorq %rax, %rax
    movq %rax, MAP_KEYS(%r8)
    movq %rax, MAP_VALS(%r8)
.Lmap_init_done_x86:
    FRAME_LEAVE 32
FUNC_END aster_rt__map_init

FUNC_BEGIN aster_rt__map_free
    FRAME_ENTER 0
    movq %rdi, %r8
    movq MAP_KEYS(%r8), %rdi
    testq %rdi, %rdi
    je .Lmap_free_vals_x86
    callq _free
.Lmap_free_vals_x86:
    movq MAP_VALS(%r8), %rdi
    testq %rdi, %rdi
    je .Lmap_free_done_x86
    callq _free
.Lmap_free_done_x86:
    xorq %rax, %rax
    movq %rax, MAP_KEYS(%r8)
    movq %rax, MAP_VALS(%r8)
    movq %rax, MAP_CAP(%r8)
    movq %rax, MAP_LEN(%r8)
    xorq %rax, %rax
    FRAME_LEAVE 0
FUNC_END aster_rt__map_free

FUNC_BEGIN aster_rt__map_put
    FRAME_ENTER 0
    movq %rdi, %r8
    movq %rsi, %r9
    movq %rdx, %r10
    testq %r9, %r9
    je .Lmap_put_badkey_x86
    movq MAP_CAP(%r8), %r11
    testq %r11, %r11
    je .Lmap_put_full_x86
    movq %r11, %r12
    subq $1, %r12
    movq %r9, %r13
    andq %r12, %r13
    movq MAP_KEYS(%r8), %r14
    movq MAP_VALS(%r8), %r15
    xorq %rax, %rax
.Lmap_put_loop_x86:
    movq %r13, %rcx
    shlq $3, %rcx
    movq (%r14,%rcx,1), %rdx
    testq %rdx, %rdx
    je .Lmap_put_insert_x86
    cmpq %rdx, %r9
    je .Lmap_put_insert_x86
    addq $1, %r13
    andq %r12, %r13
    addq $1, %rax
    cmpq %r11, %rax
    jb .Lmap_put_loop_x86
    jmp .Lmap_put_full_x86
.Lmap_put_insert_x86:
    testq %rdx, %rdx
    jne .Lmap_put_update_x86
    movq MAP_LEN(%r8), %rsi
    addq $1, %rsi
    movq %rsi, MAP_LEN(%r8)
.Lmap_put_update_x86:
    movq %r9, (%r14,%rcx,1)
    movq %r10, (%r15,%rcx,1)
    xorq %rax, %rax
    jmp .Lmap_put_done_x86
.Lmap_put_full_x86:
    movq $1, %rax
    jmp .Lmap_put_done_x86
.Lmap_put_badkey_x86:
    movq $2, %rax
.Lmap_put_done_x86:
    FRAME_LEAVE 0
FUNC_END aster_rt__map_put

FUNC_BEGIN aster_rt__map_get
    FRAME_ENTER 0
    movq %rdi, %r8
    movq %rsi, %r9
    movq %rdx, %r10
    testq %r9, %r9
    je .Lmap_get_notfound_x86
    movq MAP_CAP(%r8), %r11
    testq %r11, %r11
    je .Lmap_get_notfound_x86
    movq %r11, %r12
    subq $1, %r12
    movq %r9, %r13
    andq %r12, %r13
    movq MAP_KEYS(%r8), %r14
    movq MAP_VALS(%r8), %r15
    xorq %rax, %rax
.Lmap_get_loop_x86:
    movq %r13, %rcx
    shlq $3, %rcx
    movq (%r14,%rcx,1), %rdx
    testq %rdx, %rdx
    je .Lmap_get_notfound_x86
    cmpq %rdx, %r9
    je .Lmap_get_found_x86
    addq $1, %r13
    andq %r12, %r13
    addq $1, %rax
    cmpq %r11, %rax
    jb .Lmap_get_loop_x86
    jmp .Lmap_get_notfound_x86
.Lmap_get_found_x86:
    movq (%r15,%rcx,1), %rsi
    movq %rsi, (%r10)
    movq $1, %rax
    jmp .Lmap_get_done_x86
.Lmap_get_notfound_x86:
    xorq %rax, %rax
.Lmap_get_done_x86:
    FRAME_LEAVE 0
FUNC_END aster_rt__map_get

#else
#error "hash: unsupported architecture"
#endif
#endif
