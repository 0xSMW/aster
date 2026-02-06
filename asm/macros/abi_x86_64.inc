#ifndef ASTER_ABI_X86_64_INC
#define ASTER_ABI_X86_64_INC

#ifndef ARG0
#define ARG0 %rdi
#define ARG1 %rsi
#define ARG2 %rdx
#define ARG3 %rcx
#define ARG4 %r8
#define ARG5 %r9
#define RET0 %rax
#define FP %rbp
#define SP %rsp
#endif

.macro FRAME_ENTER locals=0
    pushq %rbp
    movq %rsp, %rbp
    .if \locals > 0
    subq $\locals, %rsp
    .endif
.endm

.macro FRAME_LEAVE locals=0
    .if \locals > 0
    addq $\locals, %rsp
    .endif
    popq %rbp
    ret
.endm

.macro CALL name
    callq _\name
.endm

.macro RET
    ret
.endm

#endif
