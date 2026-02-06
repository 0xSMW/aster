#include "base.inc"
#if defined(__aarch64__)
#include "abi_arm64.inc"
#elif defined(__x86_64__)
#include "abi_x86_64.inc"
#endif

.section __TEXT,__const
.p2align 2
src_str:
    .asciz "10\t32"

#if defined(__aarch64__)

FUNC_BEGIN main
    FRAME_ENTER 0

    adrp x0, src_str@PAGE
    add x0, x0, src_str@PAGEOFF
    mov x1, #5
    bl _aster_parse__sum_two_ints
    cmp x0, #42
    b.ne .Lfail

    mov w0, #0
    b .Ldone

.Lfail:
    mov w0, #1

.Ldone:
    FRAME_LEAVE 0
FUNC_END main

#elif defined(__x86_64__)

FUNC_BEGIN main
    FRAME_ENTER 0

    leaq src_str(%rip), %rdi
    movq $5, %rsi
    callq _aster_parse__sum_two_ints
    cmpq $42, %rax
    jne .Lfail

    movl $0, %eax
    jmp .Ldone

.Lfail:
    movl $1, %eax

.Ldone:
    FRAME_LEAVE 0
FUNC_END main

#else
#error "parser_sanity: unsupported architecture"
#endif
