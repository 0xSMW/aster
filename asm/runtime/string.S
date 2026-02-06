#include "base.inc"
#if defined(__aarch64__)
#include "abi_arm64.inc"
#elif defined(__x86_64__)
#include "abi_x86_64.inc"
#endif
#include "string.inc"

#if defined(__aarch64__)

FUNC_BEGIN aster_rt__string_from_cstr
    FRAME_ENTER 32
    str x0, [sp, #0]
    str x1, [sp, #8]
    mov x0, x1
    bl _strlen
    mov x5, x0
    str x5, [sp, #16]
    add x0, x5, #1
    bl _malloc
    cbz x0, .Lstr_fail
    mov x6, x0
    str x6, [sp, #24]
    ldr x4, [sp, #8]
    mov x0, x6
    mov x1, x4
    ldr x5, [sp, #16]
    add x2, x5, #1
    bl _memcpy
    ldr x3, [sp, #0]
    ldr x6, [sp, #24]
    str x6, [x3, #STR_PTR]
    str x5, [x3, #STR_LEN]
    str x5, [x3, #STR_CAP]
    mov x0, #0
    b .Lstr_done
.Lstr_fail:
    mov x0, #1
.Lstr_done:
    FRAME_LEAVE 32
FUNC_END aster_rt__string_from_cstr

FUNC_BEGIN aster_rt__string_free
    FRAME_ENTER 0
    mov x1, x0
    ldr x0, [x1, #STR_PTR]
    cbz x0, .Lstr_free_done
    bl _free
    mov x2, #0
    str x2, [x1, #STR_PTR]
    str x2, [x1, #STR_LEN]
    str x2, [x1, #STR_CAP]
.Lstr_free_done:
    mov x0, #0
    FRAME_LEAVE 0
FUNC_END aster_rt__string_free

#else
#if defined(__x86_64__)

FUNC_BEGIN aster_rt__string_from_cstr
    FRAME_ENTER 32
    movq %rdi, 0(%rsp)
    movq %rsi, 8(%rsp)
    movq %rsi, %rdi
    callq _strlen
    movq %rax, 16(%rsp)
    movq %rax, %rdi
    addq $1, %rdi
    callq _malloc
    testq %rax, %rax
    je .Lstr_fail_x86
    movq %rax, 24(%rsp)
    movq 24(%rsp), %rdi
    movq 8(%rsp), %rsi
    movq 16(%rsp), %rdx
    addq $1, %rdx
    callq _memcpy
    movq 0(%rsp), %r8
    movq 24(%rsp), %r9
    movq %r9, STR_PTR(%r8)
    movq 16(%rsp), %r10
    movq %r10, STR_LEN(%r8)
    movq %r10, STR_CAP(%r8)
    xorq %rax, %rax
    jmp .Lstr_done_x86
.Lstr_fail_x86:
    movq $1, %rax
.Lstr_done_x86:
    FRAME_LEAVE 32
FUNC_END aster_rt__string_from_cstr

FUNC_BEGIN aster_rt__string_free
    FRAME_ENTER 0
    movq %rdi, %r8
    movq STR_PTR(%r8), %rdi
    testq %rdi, %rdi
    je .Lstr_free_done_x86
    callq _free
    xorq %r9, %r9
    movq %r9, STR_PTR(%r8)
    movq %r9, STR_LEN(%r8)
    movq %r9, STR_CAP(%r8)
.Lstr_free_done_x86:
    xorq %rax, %rax
    FRAME_LEAVE 0
FUNC_END aster_rt__string_free

#else
#error "string: unsupported architecture"
#endif
#endif
