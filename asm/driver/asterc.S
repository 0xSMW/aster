#include "base.inc"
#if defined(__aarch64__)
#include "abi_arm64.inc"
#elif defined(__x86_64__)
#include "abi_x86_64.inc"
#endif

.section __TEXT,__cstring,cstring_literals
.p2align 2
usage_msg:
    .asciz "usage: asterc <input.as> <output>\n"
err_open_msg:
    .asciz "asterc: failed to open input\n"
err_read_msg:
    .asciz "asterc: failed to read input\n"
err_compile_msg:
    .asciz "asterc: compile failed\n"
err_spawn_msg:
    .asciz "asterc: failed to run clang\n"
mode_rb:
    .asciz "rb"
mode_w:
    .asciz "w"
clang_str:
    .asciz "clang"
dash_o:
    .asciz "-o"
dash_O3:
    .asciz "-O3"
dash_Wno_override_module:
    .asciz "-Wno-override-module"
dash_Wl_framework_accel:
    .asciz "-Wl,-framework,Accelerate"
env_link_accel:
    .asciz "ASTER_LINK_ACCELERATE"
env_link_obj:
    .asciz "ASTER_LINK_OBJ"
dotS:
    .asciz ".ll"

#if defined(__aarch64__)

.equ OFF_IN_PATH, 0
.equ OFF_OUT_PATH, 8
.equ OFF_ASM_PATH, 16
.equ OFF_SRC_BUF, 24
.equ OFF_SRC_LEN, 32
.equ OFF_OUT_LEN, 40
.equ OFF_IN_FP, 48
.equ OFF_OUT_FP, 56
.equ OFF_PID, 64
.equ OFF_STATUS, 72
.equ OFF_ARGV_ARR, 80  // 8 pointers = 64 bytes
.equ FRAME_SIZE, 144

// int main(int argc, char **argv)
FUNC_BEGIN main
    FRAME_ENTER FRAME_SIZE

    // argc must be 3
    cmp x0, #3
    b.eq .Largs_ok

    // write usage to stderr
    adrp x1, usage_msg@PAGE
    add x1, x1, usage_msg@PAGEOFF
    mov x0, x1
    bl _strlen
    mov x2, x0
    mov x0, #2
    bl _write
    mov w0, #2
    b .Ldone

.Largs_ok:
    // argv[1], argv[2]
    ldr x2, [x1, #8]
    ldr x3, [x1, #16]
    str x2, [sp, #OFF_IN_PATH]
    str x3, [sp, #OFF_OUT_PATH]

    // fopen(input, "rb")
    mov x0, x2
    adrp x1, mode_rb@PAGE
    add x1, x1, mode_rb@PAGEOFF
    bl _fopen
    cbz x0, .Lerr_open
    str x0, [sp, #OFF_IN_FP] // FILE*

    // fseek(fp, 0, SEEK_END)
    ldr x0, [sp, #OFF_IN_FP]
    mov x1, #0
    mov x2, #2
    bl _fseek
    // ftell(fp)
    ldr x0, [sp, #OFF_IN_FP]
    bl _ftell
    // len in x0 (isize)
    cmp x0, #0
    b.le .Lerr_read
    str x0, [sp, #OFF_SRC_LEN]

    // fseek(fp, 0, SEEK_SET)
    ldr x0, [sp, #OFF_IN_FP]
    mov x1, #0
    mov x2, #0
    bl _fseek

    // malloc(len+1)
    ldr x5, [sp, #OFF_SRC_LEN]
    add x0, x5, #1
    bl _malloc
    cbz x0, .Lerr_read
    str x0, [sp, #OFF_SRC_BUF]
    // buf in stack

    // fread(buf, 1, len, fp)
    ldr x0, [sp, #OFF_SRC_BUF]
    mov x1, #1
    ldr x2, [sp, #OFF_SRC_LEN]
    ldr x3, [sp, #OFF_IN_FP]
    bl _fread
    // nul terminate
    ldr x6, [sp, #OFF_SRC_BUF]
    ldr x5, [sp, #OFF_SRC_LEN]
    add x7, x6, x5
    strb wzr, [x7]

    // fclose(fp)
    ldr x0, [sp, #OFF_IN_FP]
    bl _fclose

    // build ir path: out + ".ll"
    ldr x0, [sp, #OFF_OUT_PATH]
    bl _strlen
    str x0, [sp, #OFF_OUT_LEN]
    ldr x8, [sp, #OFF_OUT_LEN]
    add x0, x8, #4 // + ".ll" + nul
    bl _malloc
    cbz x0, .Lerr_read
    str x0, [sp, #OFF_ASM_PATH]

    // memcpy(asm_buf, out_path, out_len)
    ldr x0, [sp, #OFF_ASM_PATH]
    ldr x1, [sp, #OFF_OUT_PATH]
    ldr x2, [sp, #OFF_OUT_LEN]
    bl _memcpy
    // append ".ll"
    ldr x9, [sp, #OFF_ASM_PATH]
    ldr x8, [sp, #OFF_OUT_LEN]
    add x10, x9, x8
    mov w11, #'.'
    strb w11, [x10]
    mov w11, #'l'
    strb w11, [x10, #1]
    strb w11, [x10, #2]
    strb wzr, [x10, #3]

    // fopen(asm_path, "w")
    ldr x0, [sp, #OFF_ASM_PATH]
    adrp x1, mode_w@PAGE
    add x1, x1, mode_w@PAGEOFF
    bl _fopen
    cbz x0, .Lerr_read
    str x0, [sp, #OFF_OUT_FP] // out FILE*

    // compile
    ldr x0, [sp, #OFF_SRC_BUF]
    ldr x1, [sp, #OFF_SRC_LEN]
    ldr x2, [sp, #OFF_OUT_FP]
    bl _asterc1__compile_real
    cbnz x0, .Lerr_compile

    // fclose(out)
    ldr x0, [sp, #OFF_OUT_FP]
    bl _fclose

    // spawn clang: clang -O3 -Wno-override-module <asm> -o <out>
    add x13, sp, #OFF_ARGV_ARR
    adrp x14, clang_str@PAGE
    add x14, x14, clang_str@PAGEOFF
    str x14, [x13, #0]
    adrp x15, dash_O3@PAGE
    add x15, x15, dash_O3@PAGEOFF
    str x15, [x13, #8]
    adrp x16, dash_Wno_override_module@PAGE
    add x16, x16, dash_Wno_override_module@PAGEOFF
    str x16, [x13, #16]
    ldr x17, [sp, #OFF_ASM_PATH]
    str x17, [x13, #24]
    adrp x18, dash_o@PAGE
    add x18, x18, dash_o@PAGEOFF
    str x18, [x13, #32]
    ldr x19, [sp, #OFF_OUT_PATH]
    str x19, [x13, #40]
    // default: no extra linker flags
    str xzr, [x13, #48]
    str xzr, [x13, #56]

    // Optional: link an extra object file (for benchmark/runtime helpers).
    // Enabled via env var ASTER_LINK_OBJ=<path-to-.o>.
    adrp x0, env_link_obj@PAGE
    add x0, x0, env_link_obj@PAGEOFF
    bl _getenv
    // restore argv base (caller-saved across libc calls)
    add x13, sp, #OFF_ARGV_ARR
    cbz x0, .Lcheck_accel
    ldrb w1, [x0]
    cbz w1, .Lcheck_accel
    cmp w1, #'0'
    b.ne .Lhave_obj
    ldrb w2, [x0, #1]
    cbz w2, .Lcheck_accel
.Lhave_obj:
    str x0, [x13, #48]
    b .Lno_accel

.Lcheck_accel:
    // Optional: link Accelerate for BLAS (`-Wl,-framework,Accelerate`).
    // Enabled via env var ASTER_LINK_ACCELERATE=1.
    adrp x0, env_link_accel@PAGE
    add x0, x0, env_link_accel@PAGEOFF
    bl _getenv
    // restore argv base (caller-saved across libc calls)
    add x13, sp, #OFF_ARGV_ARR
    cbz x0, .Lno_accel
    ldrb w1, [x0]
    cmp w1, #'0'
    b.eq .Lno_accel
    adrp x2, dash_Wl_framework_accel@PAGE
    add x2, x2, dash_Wl_framework_accel@PAGEOFF
    str x2, [x13, #48]
.Lno_accel:

    // environ
    adrp x20, _environ@GOTPAGE
    ldr x20, [x20, _environ@GOTPAGEOFF]
    ldr x5, [x20]

    // posix_spawnp(&pid, "clang", 0, 0, argv, environ)
    add x0, sp, #OFF_PID
    adrp x1, clang_str@PAGE
    add x1, x1, clang_str@PAGEOFF
    mov x2, #0
    mov x3, #0
    mov x4, x13
    // x5 already environ
    bl _posix_spawnp
    cbnz w0, .Lerr_spawn

    // waitpid(pid, &status, 0)
    ldr w0, [sp, #OFF_PID]
    add x1, sp, #OFF_STATUS
    mov w2, #0
    bl _waitpid

    ldr w3, [sp, #OFF_STATUS]
    cbz w3, .Lok
    b .Lerr_spawn

.Lok:
    mov w0, #0
    b .Ldone

.Lerr_open:
    adrp x1, err_open_msg@PAGE
    add x1, x1, err_open_msg@PAGEOFF
    b .Lwrite_err
.Lerr_read:
    adrp x1, err_read_msg@PAGE
    add x1, x1, err_read_msg@PAGEOFF
    b .Lwrite_err
.Lerr_compile:
    adrp x1, err_compile_msg@PAGE
    add x1, x1, err_compile_msg@PAGEOFF
    b .Lwrite_err
.Lerr_spawn:
    adrp x1, err_spawn_msg@PAGE
    add x1, x1, err_spawn_msg@PAGEOFF
.Lwrite_err:
    mov x0, x1
    bl _strlen
    mov x2, x0
    mov x0, #2
    // x1 already msg
    bl _write
    mov w0, #1

.Ldone:
    FRAME_LEAVE FRAME_SIZE
FUNC_END main

#elif defined(__x86_64__)

// x86_64 driver (mirrors arm64): asterc <input.as> <output>
.equ OFF_IN_PATH, 0
.equ OFF_OUT_PATH, 8
.equ OFF_LL_PATH, 16
.equ OFF_SRC_BUF, 24
.equ OFF_SRC_LEN, 32
.equ OFF_OUT_LEN, 40
.equ OFF_IN_FP, 48
.equ OFF_OUT_FP, 56
.equ OFF_PID, 64
.equ OFF_STATUS, 72
.equ OFF_ARGV_ARR, 80  // 8 pointers = 64 bytes
.equ FRAME_SIZE, 144

FUNC_BEGIN main
    FRAME_ENTER FRAME_SIZE

    // argc must be 3
    cmpq $3, %rdi
    je .Largs_ok_x86

    // write usage to stderr
    leaq usage_msg(%rip), %rsi
    movq %rsi, %rdi
    callq _strlen
    movq %rax, %rdx
    movq $2, %rdi
    // %rsi already usage_msg
    callq _write
    movl $2, %eax
    jmp .Ldone_x86

.Largs_ok_x86:
    // argv[1], argv[2]
    movq 8(%rsi), %rax
    movq 16(%rsi), %rcx
    movq %rax, OFF_IN_PATH(%rsp)
    movq %rcx, OFF_OUT_PATH(%rsp)

    // fopen(input, "rb")
    movq %rax, %rdi
    leaq mode_rb(%rip), %rsi
    callq _fopen
    testq %rax, %rax
    je .Lerr_open_x86
    movq %rax, OFF_IN_FP(%rsp)

    // fseek(fp, 0, SEEK_END)
    movq OFF_IN_FP(%rsp), %rdi
    movq $0, %rsi
    movq $2, %rdx
    callq _fseek
    // ftell(fp)
    movq OFF_IN_FP(%rsp), %rdi
    callq _ftell
    cmpq $0, %rax
    jle .Lerr_read_x86
    movq %rax, OFF_SRC_LEN(%rsp)

    // fseek(fp, 0, SEEK_SET)
    movq OFF_IN_FP(%rsp), %rdi
    movq $0, %rsi
    movq $0, %rdx
    callq _fseek

    // malloc(len+1)
    movq OFF_SRC_LEN(%rsp), %rdi
    addq $1, %rdi
    callq _malloc
    testq %rax, %rax
    je .Lerr_read_x86
    movq %rax, OFF_SRC_BUF(%rsp)

    // fread(buf, 1, len, fp)
    movq OFF_SRC_BUF(%rsp), %rdi
    movq $1, %rsi
    movq OFF_SRC_LEN(%rsp), %rdx
    movq OFF_IN_FP(%rsp), %rcx
    callq _fread

    // nul terminate at buf[len]
    movq OFF_SRC_BUF(%rsp), %rdi
    movq OFF_SRC_LEN(%rsp), %rcx
    movb $0, (%rdi,%rcx,1)

    // fclose(fp)
    movq OFF_IN_FP(%rsp), %rdi
    callq _fclose

    // build ir path: out + ".ll"
    movq OFF_OUT_PATH(%rsp), %rdi
    callq _strlen
    movq %rax, OFF_OUT_LEN(%rsp)
    movq %rax, %rdi
    addq $4, %rdi
    callq _malloc
    testq %rax, %rax
    je .Lerr_read_x86
    movq %rax, OFF_LL_PATH(%rsp)

    // memcpy(ll_path, out_path, out_len)
    movq OFF_LL_PATH(%rsp), %rdi
    movq OFF_OUT_PATH(%rsp), %rsi
    movq OFF_OUT_LEN(%rsp), %rdx
    callq _memcpy
    // append ".ll"
    movq OFF_LL_PATH(%rsp), %rdi
    movq OFF_OUT_LEN(%rsp), %rcx
    leaq (%rdi,%rcx,1), %rdi
    movb $'.', 0(%rdi)
    movb $'l', 1(%rdi)
    movb $'l', 2(%rdi)
    movb $0, 3(%rdi)

    // fopen(ll_path, "w")
    movq OFF_LL_PATH(%rsp), %rdi
    leaq mode_w(%rip), %rsi
    callq _fopen
    testq %rax, %rax
    je .Lerr_read_x86
    movq %rax, OFF_OUT_FP(%rsp)

    // compile
    movq OFF_SRC_BUF(%rsp), %rdi
    movq OFF_SRC_LEN(%rsp), %rsi
    movq OFF_OUT_FP(%rsp), %rdx
    callq _asterc1__compile_real
    testq %rax, %rax
    jne .Lerr_compile_x86

    // fclose(out)
    movq OFF_OUT_FP(%rsp), %rdi
    callq _fclose

    // argv array for clang: clang -O3 -Wno-override-module <ll> -o <out> [extra link flags]
    leaq OFF_ARGV_ARR(%rsp), %r8
    leaq clang_str(%rip), %rax
    movq %rax, 0(%r8)
    leaq dash_O3(%rip), %rax
    movq %rax, 8(%r8)
    leaq dash_Wno_override_module(%rip), %rax
    movq %rax, 16(%r8)
    movq OFF_LL_PATH(%rsp), %rax
    movq %rax, 24(%r8)
    leaq dash_o(%rip), %rax
    movq %rax, 32(%r8)
    movq OFF_OUT_PATH(%rsp), %rax
    movq %rax, 40(%r8)
    // default: no extra linker flags
    movq $0, 48(%r8)
    movq $0, 56(%r8)

    // Optional: link an extra object file (for benchmark/runtime helpers).
    // Enabled via env var ASTER_LINK_OBJ=<path-to-.o>.
    leaq env_link_obj(%rip), %rdi
    callq _getenv
    // restore argv base (caller-saved across libc calls)
    leaq OFF_ARGV_ARR(%rsp), %r8
    testq %rax, %rax
    je .Lcheck_accel_x86
    movzbl (%rax), %ecx
    testb %cl, %cl
    je .Lcheck_accel_x86
    cmpb $'0', %cl
    jne .Lhave_obj_x86
    cmpb $0, 1(%rax)
    je .Lcheck_accel_x86
.Lhave_obj_x86:
    movq %rax, 48(%r8)
    jmp .Lno_accel_x86

.Lcheck_accel_x86:
    // Optional: link Accelerate for BLAS (`-Wl,-framework,Accelerate`).
    // Enabled via env var ASTER_LINK_ACCELERATE=1.
    leaq env_link_accel(%rip), %rdi
    callq _getenv
    // restore argv base (caller-saved across libc calls)
    leaq OFF_ARGV_ARR(%rsp), %r8
    testq %rax, %rax
    je .Lno_accel_x86
    movzbl (%rax), %eax
    cmpb $'0', %al
    je .Lno_accel_x86
    leaq dash_Wl_framework_accel(%rip), %rax
    movq %rax, 48(%r8)
.Lno_accel_x86:

    // environ
    movq _environ@GOTPCREL(%rip), %rax
    movq (%rax), %r9

    // posix_spawnp(&pid, "clang", 0, 0, argv, environ)
    leaq OFF_PID(%rsp), %rdi
    leaq clang_str(%rip), %rsi
    xorq %rdx, %rdx
    xorq %rcx, %rcx
    // %r8 argv already
    // %r9 environ already
    callq _posix_spawnp
    testl %eax, %eax
    jne .Lerr_spawn_x86

    // waitpid(pid, &status, 0)
    movl OFF_PID(%rsp), %edi
    leaq OFF_STATUS(%rsp), %rsi
    movl $0, %edx
    callq _waitpid

    movl OFF_STATUS(%rsp), %eax
    testl %eax, %eax
    jne .Lerr_spawn_x86

    movl $0, %eax
    jmp .Ldone_x86

.Lerr_open_x86:
    leaq err_open_msg(%rip), %rsi
    jmp .Lwrite_err_x86
.Lerr_read_x86:
    leaq err_read_msg(%rip), %rsi
    jmp .Lwrite_err_x86
.Lerr_compile_x86:
    leaq err_compile_msg(%rip), %rsi
    jmp .Lwrite_err_x86
.Lerr_spawn_x86:
    leaq err_spawn_msg(%rip), %rsi
.Lwrite_err_x86:
    movq %rsi, %rdi
    callq _strlen
    movq %rax, %rdx
    movq $2, %rdi
    // %rsi already msg
    callq _write
    movl $1, %eax

.Ldone_x86:
    FRAME_LEAVE FRAME_SIZE
FUNC_END main

#else
#error "asterc: unsupported architecture"
#endif
