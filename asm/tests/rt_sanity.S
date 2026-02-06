#include "base.inc"
#include "abi_arm64.inc"
#include "arena.inc"
#include "vec.inc"
#include "string.inc"
#include "hash.inc"

#if defined(__aarch64__)

.equ OFF_ARENA, 0
.equ OFF_VEC, 32
.equ OFF_STR, 64
.equ OFF_MAP, 96
.equ OFF_TMP, 128
.equ FRAME_SIZE, 256

.section __TEXT,__const
.p2align 2
cstr_hello:
    .asciz "hello"

FUNC_BEGIN main
    FRAME_ENTER FRAME_SIZE

    // arena init
    add x0, sp, #OFF_ARENA
    mov x1, #256
    bl _aster_rt__arena_init
    cbnz x0, .Lfail1

    // arena alloc
    add x0, sp, #OFF_ARENA
    mov x1, #16
    mov x2, #8
    bl _aster_rt__arena_alloc
    cbz x0, .Lfail2

    // vec init
    add x0, sp, #OFF_VEC
    mov x1, #8
    mov x2, #0
    bl _aster_rt__vec_init
    cbnz x0, .Lfail3

    // vec push 42
    mov x3, #42
    str x3, [sp, #OFF_TMP]
    add x0, sp, #OFF_VEC
    add x1, sp, #OFF_TMP
    bl _aster_rt__vec_push
    cbnz x0, .Lfail4

    ldr x4, [sp, #OFF_VEC + VEC_LEN]
    cmp x4, #1
    bne .Lfail5

    ldr x5, [sp, #OFF_VEC + VEC_PTR]
    ldr x6, [x5]
    cmp x6, #42
    bne .Lfail6

    // string from cstr
    add x0, sp, #OFF_STR
    adrp x1, cstr_hello@PAGE
    add x1, x1, cstr_hello@PAGEOFF
    bl _aster_rt__string_from_cstr
    cbnz x0, .Lfail7

    ldr x7, [sp, #OFF_STR + STR_LEN]
    cmp x7, #5
    bne .Lfail8

    ldr x8, [sp, #OFF_STR + STR_PTR]
    ldrb w9, [x8]
    cmp w9, #'h'
    bne .Lfail9

    // map init
    add x0, sp, #OFF_MAP
    mov x1, #8
    bl _aster_rt__map_init
    cbnz x0, .Lfail10

    // map put/get
    add x0, sp, #OFF_MAP
    mov x1, #7
    mov x2, #99
    bl _aster_rt__map_put
    cmp x0, #0
    bne .Lfail11

    add x0, sp, #OFF_MAP
    mov x1, #7
    add x2, sp, #OFF_TMP
    bl _aster_rt__map_get
    cmp x0, #1
    bne .Lfail12

    ldr x10, [sp, #OFF_TMP]
    cmp x10, #99
    bne .Lfail13

    mov w0, #0
    b .Ldone

.Lfail1:
    mov w0, #1
    b .Ldone
.Lfail2:
    mov w0, #2
    b .Ldone
.Lfail3:
    mov w0, #3
    b .Ldone
.Lfail4:
    mov w0, #4
    b .Ldone
.Lfail5:
    mov w0, #5
    b .Ldone
.Lfail6:
    mov w0, #6
    b .Ldone
.Lfail7:
    mov w0, #7
    b .Ldone
.Lfail8:
    mov w0, #8
    b .Ldone
.Lfail9:
    mov w0, #9
    b .Ldone
.Lfail10:
    mov w0, #10
    b .Ldone
.Lfail11:
    mov w0, #11
    b .Ldone
.Lfail12:
    mov w0, #12
    b .Ldone
.Lfail13:
    mov w0, #13

.Ldone:
    FRAME_LEAVE FRAME_SIZE
FUNC_END main

#else
#error "rt_sanity: unsupported architecture"
#endif
