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
dash_O2:
    .asciz "-O2"
dash_O0:
    .asciz "-O0"
dash_g:
    .asciz "-g"
dash_fno_omit_fp:
    .asciz "-fno-omit-frame-pointer"
dash_mcpu_native:
    .asciz "-mcpu=native"
dash_march_native:
    .asciz "-march=native"
dash_mtune_native:
    .asciz "-mtune=native"
dash_ffast_math:
    .asciz "-ffast-math"
dash_Wno_override_module:
    .asciz "-Wno-override-module"
dash_Wl_framework_accel:
    .asciz "-Wl,-framework,Accelerate"
dash_Wl_framework_net:
    .asciz "-Wl,-framework,Security,-framework,CoreFoundation"
env_debug:
    .asciz "ASTER_DEBUG"
env_olevel:
    .asciz "ASTER_OLEVEL"
env_native:
    .asciz "ASTER_NATIVE"
env_fast_math:
    .asciz "ASTER_FAST_MATH"
env_link_accel:
    .asciz "ASTER_LINK_ACCELERATE"
env_link_obj:
    .asciz "ASTER_LINK_OBJ"
env_timing:
    .asciz "ASTER_TIMING"
dotS:
    .asciz ".ll"
timing_prefix:
    .asciz "ASTER_TIMING "
timing_key_asterc:
    .asciz "asterc_ns="
timing_key_clang:
    .asciz " clang_ns="
timing_key_total:
    .asciz " total_ns="
timing_nl:
    .asciz "\n"

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
.equ OFF_ARGV_ARR, 80  // 16 pointers = 128 bytes
.equ OFF_TS, 208       // struct timespec (16 bytes)
.equ OFF_T0, 224       // u64
.equ OFF_T1, 232       // u64
.equ OFF_T2, 240       // u64
.equ OFF_TIMING, 248   // u64 flag
.equ FRAME_SIZE, 256

// int main(int argc, char **argv)
FUNC_BEGIN main
    FRAME_ENTER FRAME_SIZE

    // argc must be 3
    cmp x0, #3
    b.eq .Largs_ok

    // write usage to stderr
    adrp x1, usage_msg@PAGE
    add x1, x1, usage_msg@PAGEOFF
    // Preserve message pointer across libc calls (x1 is caller-saved).
    mov x19, x1
    mov x0, x1
    bl _strlen
    mov x2, x0
    mov x0, #2
    mov x1, x19
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

    // preprocess modules (Aster1 `use` include-style) into a single unit
    ldr x0, [sp, #OFF_IN_PATH]  // input path (for root discovery)
    ldr x1, [sp, #OFF_SRC_BUF]  // entry src
    ldr x2, [sp, #OFF_SRC_LEN]  // entry len
    bl _asterc1__unit_from_entry
    cbz x0, .Lerr_compile
    // stash AsterUnit* in OFF_IN_FP (no longer needed after fclose)
    str x0, [sp, #OFF_IN_FP]
    // overwrite src buf/len with unit buf/len for the rest of the pipeline
    ldr x1, [x0, #0]  // unit->src
    ldr x2, [x0, #8]  // unit->len
    str x1, [sp, #OFF_SRC_BUF]
    str x2, [sp, #OFF_SRC_LEN]

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

    // Optional deterministic build cache (ASTER_CACHE=1).
    // On hit, copy cached binary + ll into place and exit 0.
    ldr x0, [sp, #OFF_IN_FP]     // AsterUnit*
    ldr x1, [sp, #OFF_OUT_PATH]  // out path
    ldr x2, [sp, #OFF_ASM_PATH]  // ll path
    bl _asterc1__cache_try
    cbz x0, .Lcache_miss_a64
    mov w0, #0
    b .Ldone
.Lcache_miss_a64:

    // fopen(asm_path, "w")
    ldr x0, [sp, #OFF_ASM_PATH]
    adrp x1, mode_w@PAGE
    add x1, x1, mode_w@PAGEOFF
    bl _fopen
    cbz x0, .Lerr_read
    str x0, [sp, #OFF_OUT_FP] // out FILE*

    // Optional timing breakdown: compiler vs clang.
    // Enabled via env var ASTER_TIMING=1.
    mov x0, #0
    str x0, [sp, #OFF_TIMING]
    adrp x0, env_timing@PAGE
    add x0, x0, env_timing@PAGEOFF
    bl _getenv
    cbz x0, .Ltiming_off
    ldrb w1, [x0]
    cbz w1, .Ltiming_off
    cmp w1, #'0'
    b.eq .Ltiming_off
    mov x1, #1
    str x1, [sp, #OFF_TIMING]
    // t0 = now_ns()
    mov x0, #6 // CLOCK_MONOTONIC on macOS
    add x1, sp, #OFF_TS
    bl _clock_gettime
    ldr x2, [sp, #OFF_TS]
    ldr x3, [sp, #OFF_TS + 8]
    movz x4, #0xCA00
    movk x4, #0x3B9A, lsl #16
    mul x2, x2, x4
    add x0, x2, x3
    str x0, [sp, #OFF_T0]
.Ltiming_off:

    // compile
    ldr x0, [sp, #OFF_SRC_BUF]
    ldr x1, [sp, #OFF_SRC_LEN]
    ldr x2, [sp, #OFF_OUT_FP]
    bl _asterc1__compile_real
    cbnz x0, .Lerr_compile

    // fclose(out)
    ldr x0, [sp, #OFF_OUT_FP]
    bl _fclose

    // t1 = now_ns()
    ldr x0, [sp, #OFF_TIMING]
    cbz x0, .Lno_t1
    mov x0, #6 // CLOCK_MONOTONIC on macOS
    add x1, sp, #OFF_TS
    bl _clock_gettime
    ldr x2, [sp, #OFF_TS]
    ldr x3, [sp, #OFF_TS + 8]
    movz x4, #0xCA00
    movk x4, #0x3B9A, lsl #16
    mul x2, x2, x4
    add x0, x2, x3
    str x0, [sp, #OFF_T1]
.Lno_t1:

    // spawn clang: clang <opt> -Wno-override-module <asm> -o <out>
    // Select optimization level (default -O3; ASTER_OLEVEL=0|2|3; ASTER_DEBUG forces -O0).
    adrp x0, env_debug@PAGE
    add x0, x0, env_debug@PAGEOFF
    bl _getenv
    cbz x0, .Lcheck_olevel_a64
    ldrb w1, [x0]
    cbz w1, .Lcheck_olevel_a64
    cmp w1, #'0'
    b.eq .Lcheck_olevel_a64
    adrp x15, dash_O0@PAGE
    add x15, x15, dash_O0@PAGEOFF
    b .Lopt_selected_a64
.Lcheck_olevel_a64:
    adrp x0, env_olevel@PAGE
    add x0, x0, env_olevel@PAGEOFF
    bl _getenv
    cbz x0, .Lopt_default_a64
    ldrb w1, [x0]
    cbz w1, .Lopt_default_a64
    cmp w1, #'0'
    b.eq .Lopt_O0_a64
    cmp w1, #'2'
    b.eq .Lopt_O2_a64
    cmp w1, #'3'
    b.eq .Lopt_O3_a64
.Lopt_default_a64:
    adrp x15, dash_O3@PAGE
    add x15, x15, dash_O3@PAGEOFF
    b .Lopt_selected_a64
.Lopt_O0_a64:
    adrp x15, dash_O0@PAGE
    add x15, x15, dash_O0@PAGEOFF
    b .Lopt_selected_a64
.Lopt_O2_a64:
    adrp x15, dash_O2@PAGE
    add x15, x15, dash_O2@PAGEOFF
    b .Lopt_selected_a64
.Lopt_O3_a64:
    adrp x15, dash_O3@PAGE
    add x15, x15, dash_O3@PAGEOFF
.Lopt_selected_a64:
    add x13, sp, #OFF_ARGV_ARR
    adrp x14, clang_str@PAGE
    add x14, x14, clang_str@PAGEOFF
    str x14, [x13, #0]
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
    // Build optional clang link args (objects/frameworks) after the fixed 6 args.
    // argv[6...] are appended here, terminated by NULL.
    add x22, x13, #48 // &argv[6]

    // Optional: tune codegen for the local CPU (ASTER_NATIVE=1).
    adrp x0, env_native@PAGE
    add x0, x0, env_native@PAGEOFF
    bl _getenv
    cbz x0, .Lmaybe_fast_math_a64
    ldrb w1, [x0]
    cbz w1, .Lmaybe_fast_math_a64
    cmp w1, #'0'
    b.eq .Lmaybe_fast_math_a64
    adrp x2, dash_mcpu_native@PAGE
    add x2, x2, dash_mcpu_native@PAGEOFF
    str x2, [x22]
    add x22, x22, #8
.Lmaybe_fast_math_a64:

    // Optional: enable fast-math reassociation (ASTER_FAST_MATH=1).
    adrp x0, env_fast_math@PAGE
    add x0, x0, env_fast_math@PAGEOFF
    bl _getenv
    cbz x0, .Lmaybe_debug_a64
    ldrb w1, [x0]
    cbz w1, .Lmaybe_debug_a64
    cmp w1, #'0'
    b.eq .Lmaybe_debug_a64
    adrp x2, dash_ffast_math@PAGE
    add x2, x2, dash_ffast_math@PAGEOFF
    str x2, [x22]
    add x22, x22, #8
.Lmaybe_debug_a64:

    // Optional: emit debug info + keep frame pointers (ASTER_DEBUG=1).
    adrp x0, env_debug@PAGE
    add x0, x0, env_debug@PAGEOFF
    bl _getenv
    cbz x0, .Lmaybe_link_obj
    ldrb w1, [x0]
    cbz w1, .Lmaybe_link_obj
    cmp w1, #'0'
    b.eq .Lmaybe_link_obj
    adrp x2, dash_g@PAGE
    add x2, x2, dash_g@PAGEOFF
    str x2, [x22]
    add x22, x22, #8
    adrp x2, dash_fno_omit_fp@PAGE
    add x2, x2, dash_fno_omit_fp@PAGEOFF
    str x2, [x22]
    add x22, x22, #8
.Lmaybe_link_obj:

    // Optional: link an extra object file (for benchmark/runtime helpers).
    // Enabled via env var ASTER_LINK_OBJ=<path-to-.o>.
    adrp x0, env_link_obj@PAGE
    add x0, x0, env_link_obj@PAGEOFF
    bl _getenv
    cbz x0, .Lmaybe_net_obj
    ldrb w1, [x0]
    cbz w1, .Lmaybe_net_obj
    cmp w1, #'0'
    b.ne .Ladd_obj
    ldrb w2, [x0, #1]
    cbz w2, .Lmaybe_net_obj
.Ladd_obj:
    str x0, [x22]
    add x22, x22, #8

.Lmaybe_net_obj:
    // Auto: link TLS helper when the unit imports core.net/core.http.
    ldr x9, [sp, #OFF_IN_FP]     // AsterUnit*
    ldr w10, [x9, #56]           // u->flags
    tbz w10, #0, .Lmaybe_accel   // UNIT_FLAG_NET
    ldr x11, [x9, #64]           // u->net_obj_abs
    cbz x11, .Lmaybe_accel
    str x11, [x22]
    add x22, x22, #8

.Lmaybe_accel:
    // Optional: link Accelerate for BLAS (`-Wl,-framework,Accelerate`).
    // Enabled via env var ASTER_LINK_ACCELERATE=1.
    adrp x0, env_link_accel@PAGE
    add x0, x0, env_link_accel@PAGEOFF
    bl _getenv
    cbz x0, .Lmaybe_net_fw
    ldrb w1, [x0]
    cmp w1, #'0'
    b.eq .Lmaybe_net_fw
    adrp x2, dash_Wl_framework_accel@PAGE
    add x2, x2, dash_Wl_framework_accel@PAGEOFF
    str x2, [x22]
    add x22, x22, #8

.Lmaybe_net_fw:
    // Auto: link Security/CoreFoundation when UNIT_FLAG_NET is set.
    ldr x9, [sp, #OFF_IN_FP]     // AsterUnit*
    ldr w10, [x9, #56]           // u->flags
    tbz w10, #0, .Largv_done
    adrp x2, dash_Wl_framework_net@PAGE
    add x2, x2, dash_Wl_framework_net@PAGEOFF
    str x2, [x22]
    add x22, x22, #8

.Largv_done:
    str xzr, [x22] // NULL terminator
    // restore argv base (caller-saved across libc calls)
    add x13, sp, #OFF_ARGV_ARR

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
    // Cache the successful output (best-effort).
    ldr x0, [sp, #OFF_IN_FP]     // AsterUnit*
    ldr x1, [sp, #OFF_OUT_PATH]  // out path
    ldr x2, [sp, #OFF_ASM_PATH]  // ll path
    bl _asterc1__cache_store

    // t2 = now_ns() and emit breakdown if enabled.
    ldr x0, [sp, #OFF_TIMING]
    cbz x0, .Lret_ok
    mov x0, #6 // CLOCK_MONOTONIC on macOS
    add x1, sp, #OFF_TS
    bl _clock_gettime
    ldr x2, [sp, #OFF_TS]
    ldr x3, [sp, #OFF_TS + 8]
    movz x4, #0xCA00
    movk x4, #0x3B9A, lsl #16
    mul x2, x2, x4
    add x0, x2, x3
    str x0, [sp, #OFF_T2]

    ldr x2, [sp, #OFF_T0] // t0
    ldr x3, [sp, #OFF_T1] // t1
    ldr x4, [sp, #OFF_T2] // t2
    sub x5, x3, x2        // asterc_ns
    sub x6, x4, x3        // clang_ns
    sub x7, x4, x2        // total_ns
    mov x0, #2            // fd
    mov x1, x5            // asterc_ns
    mov x2, x6            // clang_ns
    mov x3, x7            // total_ns
    bl _asterc__write_timing_line

.Lret_ok:
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
    // Preserve message pointer across libc calls (x1 is caller-saved).
    mov x19, x1
    mov x0, x1
    bl _strlen
    mov x2, x0
    mov x0, #2
    mov x1, x19
    bl _write
    mov w0, #1

.Ldone:
    FRAME_LEAVE FRAME_SIZE
FUNC_END main

// void asterc__write_timing_line(int fd, u64 asterc_ns, u64 clang_ns, u64 total_ns)
// args: x0=fd, x1=asterc_ns, x2=clang_ns, x3=total_ns
FUNC_BEGIN asterc__write_timing_line
    FRAME_ENTER 48
    str x0, [sp, #0]
    str x1, [sp, #8]
    str x2, [sp, #16]
    str x3, [sp, #24]

    ldr x0, [sp, #0]
    adrp x1, timing_prefix@PAGE
    add x1, x1, timing_prefix@PAGEOFF
    bl _asterc__write_cstr

    ldr x0, [sp, #0]
    adrp x1, timing_key_asterc@PAGE
    add x1, x1, timing_key_asterc@PAGEOFF
    bl _asterc__write_cstr
    ldr x0, [sp, #0]
    ldr x1, [sp, #8]
    bl _asterc__write_u64

    ldr x0, [sp, #0]
    adrp x1, timing_key_clang@PAGE
    add x1, x1, timing_key_clang@PAGEOFF
    bl _asterc__write_cstr
    ldr x0, [sp, #0]
    ldr x1, [sp, #16]
    bl _asterc__write_u64

    ldr x0, [sp, #0]
    adrp x1, timing_key_total@PAGE
    add x1, x1, timing_key_total@PAGEOFF
    bl _asterc__write_cstr
    ldr x0, [sp, #0]
    ldr x1, [sp, #24]
    bl _asterc__write_u64

    ldr x0, [sp, #0]
    adrp x1, timing_nl@PAGE
    add x1, x1, timing_nl@PAGEOFF
    bl _asterc__write_cstr

    FRAME_LEAVE 48
FUNC_END asterc__write_timing_line

// void asterc__write_cstr(int fd, const char* s)
// args: x0=fd, x1=s
FUNC_BEGIN asterc__write_cstr
    FRAME_ENTER 32
    str x0, [sp, #0]
    str x1, [sp, #8]
    mov x0, x1
    bl _strlen
    mov x2, x0
    ldr x0, [sp, #0]
    ldr x1, [sp, #8]
    bl _write
    FRAME_LEAVE 32
FUNC_END asterc__write_cstr

// void asterc__write_u64(int fd, u64 v)
// args: x0=fd, x1=v
FUNC_BEGIN asterc__write_u64
    FRAME_ENTER 64
    str x0, [sp, #0]
    str x1, [sp, #8]

    add x2, sp, #64   // buf_end
    ldr x0, [sp, #8]  // v
    mov x1, x2
    bl _asterc__u64_to_dec
    // returns x0=start, x1=len
    mov x2, x1
    mov x1, x0
    ldr x0, [sp, #0]
    bl _write

    FRAME_LEAVE 64
FUNC_END asterc__write_u64

// (start,len) asterc__u64_to_dec(u64 v, char* buf_end)
// args: x0=v, x1=buf_end (one past end)
// ret: x0=start ptr, x1=len
FUNC_BEGIN asterc__u64_to_dec
    FRAME_ENTER 0
    mov x2, x0 // v
    mov x3, x1 // p
    mov x8, x1 // end
    cbnz x2, .Lu64_loop
    sub x3, x3, #1
    mov w4, #'0'
    strb w4, [x3]
    mov x0, x3
    mov x1, #1
    FRAME_LEAVE 0

.Lu64_loop:
    mov x5, #10
.Lu64_step:
    udiv x6, x2, x5        // q = v / 10
    msub x7, x6, x5, x2    // r = v - q*10
    sub x3, x3, #1
    add w7, w7, #'0'
    strb w7, [x3]
    mov x2, x6
    cbnz x2, .Lu64_step
    mov x0, x3
    sub x1, x8, x3
    FRAME_LEAVE 0
FUNC_END asterc__u64_to_dec

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
.equ OFF_ARGV_ARR, 80  // 16 pointers = 128 bytes
.equ OFF_TS, 208       // struct timespec (16 bytes)
.equ OFF_T0, 224       // u64
.equ OFF_T1, 232       // u64
.equ OFF_T2, 240       // u64
.equ OFF_TIMING, 248   // u64 flag
.equ FRAME_SIZE, 256

FUNC_BEGIN main
    FRAME_ENTER FRAME_SIZE

    // argc must be 3
    cmpq $3, %rdi
    je .Largs_ok_x86

    // write usage to stderr
    leaq usage_msg(%rip), %rsi
    // Preserve message pointer across libc calls (%rsi is caller-saved).
    movq %rsi, OFF_STATUS(%rsp)
    movq %rsi, %rdi
    callq _strlen
    movq %rax, %rdx
    movq $2, %rdi
    movq OFF_STATUS(%rsp), %rsi
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

    // preprocess modules (Aster1 `use` include-style) into a single unit
    movq OFF_IN_PATH(%rsp), %rdi  // input path (for root discovery)
    movq OFF_SRC_BUF(%rsp), %rsi  // entry src
    movq OFF_SRC_LEN(%rsp), %rdx  // entry len
    callq _asterc1__unit_from_entry
    testq %rax, %rax
    je .Lerr_compile_x86
    // stash AsterUnit* in OFF_IN_FP (no longer needed after fclose)
    movq %rax, OFF_IN_FP(%rsp)
    // overwrite src buf/len with unit buf/len for the rest of the pipeline
    movq 0(%rax), %rcx   // unit->src
    movq 8(%rax), %rdx   // unit->len
    movq %rcx, OFF_SRC_BUF(%rsp)
    movq %rdx, OFF_SRC_LEN(%rsp)

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

    // Optional deterministic build cache (ASTER_CACHE=1).
    // On hit, copy cached binary + ll into place and exit 0.
    movq OFF_IN_FP(%rsp), %rdi    // AsterUnit*
    movq OFF_OUT_PATH(%rsp), %rsi // out path
    movq OFF_LL_PATH(%rsp), %rdx  // ll path
    callq _asterc1__cache_try
    testq %rax, %rax
    je .Lcache_miss_x86
    movl $0, %eax
    jmp .Ldone_x86
.Lcache_miss_x86:

    // fopen(ll_path, "w")
    movq OFF_LL_PATH(%rsp), %rdi
    leaq mode_w(%rip), %rsi
    callq _fopen
    testq %rax, %rax
    je .Lerr_read_x86
    movq %rax, OFF_OUT_FP(%rsp)

    // Optional timing breakdown: compiler vs clang.
    // Enabled via env var ASTER_TIMING=1.
    movq $0, OFF_TIMING(%rsp)
    leaq env_timing(%rip), %rdi
    callq _getenv
    testq %rax, %rax
    je .Ltiming_off_x86
    movzbl (%rax), %ecx
    testb %cl, %cl
    je .Ltiming_off_x86
    cmpb $'0', %cl
    je .Ltiming_off_x86
    movq $1, OFF_TIMING(%rsp)
    // t0 = now_ns()
    movl $6, %edi // CLOCK_MONOTONIC on macOS
    leaq OFF_TS(%rsp), %rsi
    callq _clock_gettime
    movq OFF_TS(%rsp), %rax
    imulq $1000000000, %rax, %rax
    addq OFF_TS + 8(%rsp), %rax
    movq %rax, OFF_T0(%rsp)
.Ltiming_off_x86:

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

    // t1 = now_ns()
    movq OFF_TIMING(%rsp), %rax
    testq %rax, %rax
    je .Lno_t1_x86
    movl $6, %edi // CLOCK_MONOTONIC on macOS
    leaq OFF_TS(%rsp), %rsi
    callq _clock_gettime
    movq OFF_TS(%rsp), %rax
    imulq $1000000000, %rax, %rax
    addq OFF_TS + 8(%rsp), %rax
    movq %rax, OFF_T1(%rsp)
.Lno_t1_x86:

    // Select optimization level (default -O3; ASTER_OLEVEL=0|2|3; ASTER_DEBUG forces -O0).
    leaq env_debug(%rip), %rdi
    callq _getenv
    testq %rax, %rax
    je .Lcheck_olevel_x86
    movzbl (%rax), %ecx
    testb %cl, %cl
    je .Lcheck_olevel_x86
    cmpb $'0', %cl
    je .Lcheck_olevel_x86
    leaq dash_O0(%rip), %rax
    jmp .Lopt_selected_x86
.Lcheck_olevel_x86:
    leaq env_olevel(%rip), %rdi
    callq _getenv
    testq %rax, %rax
    je .Lopt_default_x86
    movzbl (%rax), %ecx
    testb %cl, %cl
    je .Lopt_default_x86
    cmpb $'0', %cl
    je .Lopt_O0_x86
    cmpb $'2', %cl
    je .Lopt_O2_x86
    cmpb $'3', %cl
    je .Lopt_O3_x86
.Lopt_default_x86:
    leaq dash_O3(%rip), %rax
    jmp .Lopt_selected_x86
.Lopt_O0_x86:
    leaq dash_O0(%rip), %rax
    jmp .Lopt_selected_x86
.Lopt_O2_x86:
    leaq dash_O2(%rip), %rax
    jmp .Lopt_selected_x86
.Lopt_O3_x86:
    leaq dash_O3(%rip), %rax
.Lopt_selected_x86:

    // argv array for clang: clang <opt> -Wno-override-module <ll> -o <out> [extra link flags]
    leaq OFF_ARGV_ARR(%rsp), %r8
    leaq clang_str(%rip), %rcx
    movq %rcx, 0(%r8)
    movq %rax, 8(%r8)
    leaq dash_Wno_override_module(%rip), %rax
    movq %rax, 16(%r8)
    movq OFF_LL_PATH(%rsp), %rax
    movq %rax, 24(%r8)
    leaq dash_o(%rip), %rax
    movq %rax, 32(%r8)
    movq OFF_OUT_PATH(%rsp), %rax
    movq %rax, 40(%r8)
    // Build optional clang link args (objects/frameworks) after the fixed 6 args.
    // argv[6...] are appended here, terminated by NULL.
    leaq 48(%r8), %r10 // &argv[6]
    movq %r10, OFF_STATUS(%rsp) // temp insertion ptr (overwritten later by waitpid status)

    // Optional: tune codegen for the local CPU (ASTER_NATIVE=1).
    leaq env_native(%rip), %rdi
    callq _getenv
    testq %rax, %rax
    je .Lmaybe_fast_math_x86
    movzbl (%rax), %ecx
    testb %cl, %cl
    je .Lmaybe_fast_math_x86
    cmpb $'0', %cl
    je .Lmaybe_fast_math_x86
    leaq dash_march_native(%rip), %rax
    movq OFF_STATUS(%rsp), %r10
    movq %rax, 0(%r10)
    addq $8, %r10
    leaq dash_mtune_native(%rip), %rax
    movq %rax, 0(%r10)
    addq $8, %r10
    movq %r10, OFF_STATUS(%rsp)
.Lmaybe_fast_math_x86:

    // Optional: enable fast-math reassociation (ASTER_FAST_MATH=1).
    leaq env_fast_math(%rip), %rdi
    callq _getenv
    testq %rax, %rax
    je .Lmaybe_debug_x86
    movzbl (%rax), %ecx
    testb %cl, %cl
    je .Lmaybe_debug_x86
    cmpb $'0', %cl
    je .Lmaybe_debug_x86
    leaq dash_ffast_math(%rip), %rax
    movq OFF_STATUS(%rsp), %r10
    movq %rax, 0(%r10)
    addq $8, %r10
    movq %r10, OFF_STATUS(%rsp)
.Lmaybe_debug_x86:

    // Optional: emit debug info + keep frame pointers (ASTER_DEBUG=1).
    leaq env_debug(%rip), %rdi
    callq _getenv
    testq %rax, %rax
    je .Lmaybe_link_obj_x86
    movzbl (%rax), %ecx
    testb %cl, %cl
    je .Lmaybe_link_obj_x86
    cmpb $'0', %cl
    je .Lmaybe_link_obj_x86
    leaq dash_g(%rip), %rax
    movq OFF_STATUS(%rsp), %r10
    movq %rax, 0(%r10)
    addq $8, %r10
    leaq dash_fno_omit_fp(%rip), %rax
    movq %rax, 0(%r10)
    addq $8, %r10
    movq %r10, OFF_STATUS(%rsp)
.Lmaybe_link_obj_x86:

    // Optional: link an extra object file (for benchmark/runtime helpers).
    // Enabled via env var ASTER_LINK_OBJ=<path-to-.o>.
    leaq env_link_obj(%rip), %rdi
    callq _getenv
    testq %rax, %rax
    je .Lmaybe_net_obj_x86
    movzbl (%rax), %ecx
    testb %cl, %cl
    je .Lmaybe_net_obj_x86
    cmpb $'0', %cl
    jne .Ladd_obj_x86
    cmpb $0, 1(%rax)
    je .Lmaybe_net_obj_x86
.Ladd_obj_x86:
    movq OFF_STATUS(%rsp), %r10
    movq %rax, 0(%r10)
    addq $8, %r10
    movq %r10, OFF_STATUS(%rsp)

.Lmaybe_net_obj_x86:
    // Auto: link TLS helper when the unit imports core.net/core.http.
    movq OFF_IN_FP(%rsp), %r11 // AsterUnit*
    movl 56(%r11), %ecx        // u->flags
    testl $1, %ecx             // UNIT_FLAG_NET
    je .Lmaybe_accel_x86
    movq 64(%r11), %rax        // u->net_obj_abs
    testq %rax, %rax
    je .Lmaybe_accel_x86
    movq OFF_STATUS(%rsp), %r10
    movq %rax, 0(%r10)
    addq $8, %r10
    movq %r10, OFF_STATUS(%rsp)

.Lmaybe_accel_x86:
    // Optional: link Accelerate for BLAS (`-Wl,-framework,Accelerate`).
    // Enabled via env var ASTER_LINK_ACCELERATE=1.
    leaq env_link_accel(%rip), %rdi
    callq _getenv
    testq %rax, %rax
    je .Lmaybe_net_fw_x86
    movzbl (%rax), %eax
    cmpb $'0', %al
    je .Lmaybe_net_fw_x86
    leaq dash_Wl_framework_accel(%rip), %rax
    movq OFF_STATUS(%rsp), %r10
    movq %rax, 0(%r10)
    addq $8, %r10
    movq %r10, OFF_STATUS(%rsp)

.Lmaybe_net_fw_x86:
    // Auto: link Security/CoreFoundation when UNIT_FLAG_NET is set.
    movq OFF_IN_FP(%rsp), %r11 // AsterUnit*
    movl 56(%r11), %ecx        // u->flags
    testl $1, %ecx
    je .Largv_done_x86
    leaq dash_Wl_framework_net(%rip), %rax
    movq OFF_STATUS(%rsp), %r10
    movq %rax, 0(%r10)
    addq $8, %r10
    movq %r10, OFF_STATUS(%rsp)

.Largv_done_x86:
    movq OFF_STATUS(%rsp), %r10
    movq $0, 0(%r10) // NULL terminator
    // restore argv base (caller-saved across libc calls)
    leaq OFF_ARGV_ARR(%rsp), %r8

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

    // Cache the successful output (best-effort).
    movq OFF_IN_FP(%rsp), %rdi    // AsterUnit*
    movq OFF_OUT_PATH(%rsp), %rsi // out path
    movq OFF_LL_PATH(%rsp), %rdx  // ll path
    callq _asterc1__cache_store

    // t2 = now_ns() and emit breakdown if enabled.
    movq OFF_TIMING(%rsp), %rax
    testq %rax, %rax
    je .Lret_ok_x86
    movl $6, %edi // CLOCK_MONOTONIC on macOS
    leaq OFF_TS(%rsp), %rsi
    callq _clock_gettime
    movq OFF_TS(%rsp), %rax
    imulq $1000000000, %rax, %rax
    addq OFF_TS + 8(%rsp), %rax
    movq %rax, OFF_T2(%rsp)

    movq OFF_T0(%rsp), %r9
    movq OFF_T1(%rsp), %r10
    movq OFF_T2(%rsp), %r11
    movq %r10, %rdx
    subq %r9, %rdx   // asterc_ns
    movq %r11, %rcx
    subq %r10, %rcx  // clang_ns
    movq %r11, %r8
    subq %r9, %r8    // total_ns
    movq %rdx, %rsi  // asterc_ns
    movq %rcx, %rdx  // clang_ns
    movq %r8, %rcx   // total_ns
    movl $2, %edi    // fd
    callq _asterc__write_timing_line
.Lret_ok_x86:

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
    // Preserve message pointer across libc calls (%rsi is caller-saved).
    movq %rsi, OFF_STATUS(%rsp)
    movq %rsi, %rdi
    callq _strlen
    movq %rax, %rdx
    movq $2, %rdi
    movq OFF_STATUS(%rsp), %rsi
    callq _write
    movl $1, %eax

.Ldone_x86:
    FRAME_LEAVE FRAME_SIZE
FUNC_END main

// void asterc__write_timing_line(int fd, u64 asterc_ns, u64 clang_ns, u64 total_ns)
// args: rdi=fd, rsi=asterc_ns, rdx=clang_ns, rcx=total_ns
FUNC_BEGIN asterc__write_timing_line
    FRAME_ENTER 64
    movq %rdi, 0(%rsp)
    movq %rsi, 8(%rsp)
    movq %rdx, 16(%rsp)
    movq %rcx, 24(%rsp)

    movl 0(%rsp), %edi
    leaq timing_prefix(%rip), %rsi
    callq _asterc__write_cstr

    movl 0(%rsp), %edi
    leaq timing_key_asterc(%rip), %rsi
    callq _asterc__write_cstr
    movl 0(%rsp), %edi
    movq 8(%rsp), %rsi
    callq _asterc__write_u64

    movl 0(%rsp), %edi
    leaq timing_key_clang(%rip), %rsi
    callq _asterc__write_cstr
    movl 0(%rsp), %edi
    movq 16(%rsp), %rsi
    callq _asterc__write_u64

    movl 0(%rsp), %edi
    leaq timing_key_total(%rip), %rsi
    callq _asterc__write_cstr
    movl 0(%rsp), %edi
    movq 24(%rsp), %rsi
    callq _asterc__write_u64

    movl 0(%rsp), %edi
    leaq timing_nl(%rip), %rsi
    callq _asterc__write_cstr

    FRAME_LEAVE 64
FUNC_END asterc__write_timing_line

// void asterc__write_cstr(int fd, const char* s)
// args: rdi=fd, rsi=s
FUNC_BEGIN asterc__write_cstr
    FRAME_ENTER 32
    movq %rdi, 0(%rsp)
    movq %rsi, 8(%rsp)
    movq %rsi, %rdi
    callq _strlen
    movq %rax, %rdx
    movl 0(%rsp), %edi
    movq 8(%rsp), %rsi
    callq _write
    FRAME_LEAVE 32
FUNC_END asterc__write_cstr

// void asterc__write_u64(int fd, u64 v)
// args: rdi=fd, rsi=v
FUNC_BEGIN asterc__write_u64
    FRAME_ENTER 64
    movq %rdi, 0(%rsp)
    movq %rsi, 8(%rsp)

    leaq 64(%rsp), %rdx     # buf_end
    movq 8(%rsp), %rdi      # v
    movq %rdx, %rsi         # buf_end
    callq _asterc__u64_to_dec
    # returns rax=start, rdx=len
    movq %rax, %rsi
    movl 0(%rsp), %edi
    callq _write

    FRAME_LEAVE 64
FUNC_END asterc__write_u64

// (start,len) asterc__u64_to_dec(u64 v, char* buf_end)
// args: rdi=v, rsi=buf_end (one past end)
// ret: rax=start ptr, rdx=len
FUNC_BEGIN asterc__u64_to_dec
    FRAME_ENTER 0
    movq %rdi, %rax  # v
    movq %rsi, %r8   # p
    movq %rsi, %r9   # end
    testq %rax, %rax
    jnz .Lu64_loop_x86
    decq %r8
    movb $'0', (%r8)
    movq %r8, %rax
    movq $1, %rdx
    FRAME_LEAVE 0

.Lu64_loop_x86:
    movq $10, %rcx
.Lu64_step_x86:
    xorq %rdx, %rdx
    divq %rcx           # rax=quot, rdx=rem
    decq %r8
    addb $'0', %dl
    movb %dl, (%r8)
    testq %rax, %rax
    jnz .Lu64_step_x86
    movq %r8, %rax
    movq %r9, %rdx
    subq %r8, %rdx
    FRAME_LEAVE 0
FUNC_END asterc__u64_to_dec

#else
#error "asterc: unsupported architecture"
#endif
