#include "base.inc"
#include "abi_arm64.inc"

#if defined(__aarch64__)

.equ STAT_MODE_OFF, 4
.equ STAT_SIZE_OFF, 96

.section __TEXT,__const
.p2align 2
fmt_str:
    .asciz "files=%llu dirs=%llu bytes=%llu\n"
usage_str:
    .asciz "usage: fswalk <path> (set FS_BENCH_LIST)\n"
list_env_str:
    .asciz "FS_BENCH_LIST"
mode_str:
    .asciz "r"

FUNC_BEGIN main
    FRAME_ENTER 256
    stp x19, x20, [sp, #0]
    stp x21, x22, [sp, #16]
    stp x23, x24, [sp, #32]

    cmp x0, #2
    b.lo .Lusage

    ldr x19, [x1, #8] // argv[1]

    adrp x0, list_env_str@PAGE
    add x0, x0, list_env_str@PAGEOFF
    bl _getenv
    cbz x0, .Lusage
    mov x20, x0

    adrp x1, mode_str@PAGE
    add x1, x1, mode_str@PAGEOFF
    mov x0, x20
    bl _fopen
    cbz x0, .Lfail
    str x0, [sp, #88] // fp

    mov x21, #0
    str x21, [sp, #48] // files
    str x21, [sp, #56] // dirs
    str x21, [sp, #64] // bytes
    str x21, [sp, #72] // lineptr
    str x21, [sp, #80] // cap

.Lloop:
    add x0, sp, #72
    add x1, sp, #80
    ldr x2, [sp, #88]
    bl _getline
    cmp x0, #0
    ble .Ldone_loop

    ldr x3, [sp, #72]
    mov x4, x0

.Ltrim:
    cmp x4, #0
    beq .Lafter_trim
    sub x5, x4, #1
    ldrb w6, [x3, x5]
    cmp w6, #10
    beq .Ltrim_dec
    cmp w6, #13
    bne .Lafter_trim
.Ltrim_dec:
    sub x4, x4, #1
    strb wzr, [x3, x4]
    b .Ltrim

.Lafter_trim:
    cmp x4, #0
    beq .Lloop

    mov x0, x3
    add x1, sp, #96
    bl _lstat
    cmp w0, #0
    bne .Lloop

    ldr w7, [sp, #96 + STAT_MODE_OFF]
    and w7, w7, #0xF000
    cmp w7, #0x4000
    beq .Lcount_dir
    cmp w7, #0x8000
    bne .Lloop

    ldr x8, [sp, #48]
    add x8, x8, #1
    str x8, [sp, #48]

    ldr x9, [sp, #96 + STAT_SIZE_OFF]
    ldr x10, [sp, #64]
    add x10, x10, x9
    str x10, [sp, #64]
    b .Lloop

.Lcount_dir:
    ldr x8, [sp, #56]
    add x8, x8, #1
    str x8, [sp, #56]
    b .Lloop

.Ldone_loop:
    ldr x0, [sp, #72]
    cbz x0, .Lclose
    bl _free

.Lclose:
    ldr x0, [sp, #88]
    cbz x0, .Lprint
    bl _fclose

.Lprint:
    adrp x0, fmt_str@PAGE
    add x0, x0, fmt_str@PAGEOFF
    ldr x1, [sp, #48]
    ldr x2, [sp, #56]
    ldr x3, [sp, #64]
    bl _printf

    mov w0, #0
    b .Ldone

.Lusage:
    adrp x0, usage_str@PAGE
    add x0, x0, usage_str@PAGEOFF
    bl _printf
    mov w0, #1
    b .Ldone

.Lfail:
    mov w0, #2

.Ldone:
    ldp x19, x20, [sp, #0]
    ldp x21, x22, [sp, #16]
    ldp x23, x24, [sp, #32]
    FRAME_LEAVE 256
FUNC_END main

#else
#error "aster fswalk: unsupported architecture"
#endif
