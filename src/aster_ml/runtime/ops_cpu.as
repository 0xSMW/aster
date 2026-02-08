# aster_ml.runtime.ops_cpu (v0)
#
# CPU backend parity (minimal):
# - render elementwise kernels to C
# - clang compile to a cached `.dylib` under `.context/ml/cpu_cache`
# - dlopen/dlsym and launch via a stable ABI trampoline
#
# Note: Aster MVP doesn't yet support direct fn-pointer calls from Aster code.
# We route launches through `dispatch_sync_f`, which invokes `work(context)`
# for a `void (*)(void*)` entrypoint.

use core.libc
use aster_ml.codegen.c

# Minimal OS/stdlib externs (declared locally to avoid expanding core.libc).
extern def system(cmd is String) returns i32
extern def fwrite(ptr is String, size is usize, count is usize, fp is File) returns usize

extern def dlopen(path is String, mode is i32) returns MutString
extern def dlsym(handle is MutString, sym is String) returns MutString
extern def dlclose(handle is MutString) returns i32

extern def dispatch_get_global_queue(identifier is i64, flags is u64) returns MutString
extern def dispatch_sync_f(queue is MutString, context is MutString, work is MutString) returns ()

const RTLD_NOW is i32 = 2

const CPU_CACHE_DIR is String = ".context/ml/cpu_cache"
const CPU_CACHE_MKDIR_CMD is String = "mkdir -p .context/ml/cpu_cache"

# Keep flags stable; included in the cache key.
const CPU_CLANG_FLAGS is String = "-O3 -std=c11 -dynamiclib -fPIC"

const CPU_KERNEL_ENTRY_SYM is String = "aster_ml_kernel_entry"

struct CpuKernelCtx
    var out is MutString
    var a is MutString
    var b is MutString
    var n is usize


def file_exists(path is String) returns i32
    var fp is File = fopen(path, "rb")
    if fp is null then
        return 0
    fclose(fp)
    return 1


def file_write_all(path is String, data is String, n is usize) returns i32
    var fp is File = fopen(path, "wb")
    if fp is null then
        return 1
    var wrote is usize = fwrite(data, 1, n, fp)
    fclose(fp)
    if wrote != n then
        return 1
    return 0


def cstr_concat3(a is String, b is String, c is String) returns MutString
    if a is null or b is null or c is null then
        return null
    var la is usize = strlen(a)
    var lb is usize = strlen(b)
    var lc is usize = strlen(c)
    var out is MutString = malloc(la + lb + lc + 1)
    if out is null then
        return null
    if la != 0 then
        memcpy(out, a, la)
    if lb != 0 then
        memcpy(out + la, b, lb)
    if lc != 0 then
        memcpy(out + la + lb, c, lc)
    var bytes is slice of u8 = out
    bytes[la + lb + lc] = 0
    return out


def cstr_concat2(a is String, b is String) returns MutString
    return cstr_concat3(a, b, "")


# -----------------------------
# SHA256 (minimal, for cache keys)
# -----------------------------

const SHA256_H0 is u32 = 0x6a09e667
const SHA256_H1 is u32 = 0xbb67ae85
const SHA256_H2 is u32 = 0x3c6ef372
const SHA256_H3 is u32 = 0xa54ff53a
const SHA256_H4 is u32 = 0x510e527f
const SHA256_H5 is u32 = 0x9b05688c
const SHA256_H6 is u32 = 0x1f83d9ab
const SHA256_H7 is u32 = 0x5be0cd19

const SHA256_K0 is u32 = 0x428a2f98
const SHA256_K1 is u32 = 0x71374491
const SHA256_K2 is u32 = 0xb5c0fbcf
const SHA256_K3 is u32 = 0xe9b5dba5
const SHA256_K4 is u32 = 0x3956c25b
const SHA256_K5 is u32 = 0x59f111f1
const SHA256_K6 is u32 = 0x923f82a4
const SHA256_K7 is u32 = 0xab1c5ed5
const SHA256_K8 is u32 = 0xd807aa98
const SHA256_K9 is u32 = 0x12835b01
const SHA256_K10 is u32 = 0x243185be
const SHA256_K11 is u32 = 0x550c7dc3
const SHA256_K12 is u32 = 0x72be5d74
const SHA256_K13 is u32 = 0x80deb1fe
const SHA256_K14 is u32 = 0x9bdc06a7
const SHA256_K15 is u32 = 0xc19bf174
const SHA256_K16 is u32 = 0xe49b69c1
const SHA256_K17 is u32 = 0xefbe4786
const SHA256_K18 is u32 = 0x0fc19dc6
const SHA256_K19 is u32 = 0x240ca1cc
const SHA256_K20 is u32 = 0x2de92c6f
const SHA256_K21 is u32 = 0x4a7484aa
const SHA256_K22 is u32 = 0x5cb0a9dc
const SHA256_K23 is u32 = 0x76f988da
const SHA256_K24 is u32 = 0x983e5152
const SHA256_K25 is u32 = 0xa831c66d
const SHA256_K26 is u32 = 0xb00327c8
const SHA256_K27 is u32 = 0xbf597fc7
const SHA256_K28 is u32 = 0xc6e00bf3
const SHA256_K29 is u32 = 0xd5a79147
const SHA256_K30 is u32 = 0x06ca6351
const SHA256_K31 is u32 = 0x14292967
const SHA256_K32 is u32 = 0x27b70a85
const SHA256_K33 is u32 = 0x2e1b2138
const SHA256_K34 is u32 = 0x4d2c6dfc
const SHA256_K35 is u32 = 0x53380d13
const SHA256_K36 is u32 = 0x650a7354
const SHA256_K37 is u32 = 0x766a0abb
const SHA256_K38 is u32 = 0x81c2c92e
const SHA256_K39 is u32 = 0x92722c85
const SHA256_K40 is u32 = 0xa2bfe8a1
const SHA256_K41 is u32 = 0xa81a664b
const SHA256_K42 is u32 = 0xc24b8b70
const SHA256_K43 is u32 = 0xc76c51a3
const SHA256_K44 is u32 = 0xd192e819
const SHA256_K45 is u32 = 0xd6990624
const SHA256_K46 is u32 = 0xf40e3585
const SHA256_K47 is u32 = 0x106aa070
const SHA256_K48 is u32 = 0x19a4c116
const SHA256_K49 is u32 = 0x1e376c08
const SHA256_K50 is u32 = 0x2748774c
const SHA256_K51 is u32 = 0x34b0bcb5
const SHA256_K52 is u32 = 0x391c0cb3
const SHA256_K53 is u32 = 0x4ed8aa4a
const SHA256_K54 is u32 = 0x5b9cca4f
const SHA256_K55 is u32 = 0x682e6ff3
const SHA256_K56 is u32 = 0x748f82ee
const SHA256_K57 is u32 = 0x78a5636f
const SHA256_K58 is u32 = 0x84c87814
const SHA256_K59 is u32 = 0x8cc70208
const SHA256_K60 is u32 = 0x90befffa
const SHA256_K61 is u32 = 0xa4506ceb
const SHA256_K62 is u32 = 0xbef9a3f7
const SHA256_K63 is u32 = 0xc67178f2

struct Sha256
    var h0 is u32
    var h1 is u32
    var h2 is u32
    var h3 is u32
    var h4 is u32
    var h5 is u32
    var h6 is u32
    var h7 is u32
    var nbytes is u64
    var block_len is u32
    var block is MutString  # 64 bytes


def sha256_rotr32(x is u32, n is u32) returns u32
    return (x >> n) | (x << (32 - n))


def sha256_ch(x is u32, y is u32, z is u32) returns u32
    # (x & y) ^ (~x & z)
    return (x & y) ^ ((x ^ 0xffffffff) & z)


def sha256_maj(x is u32, y is u32, z is u32) returns u32
    return (x & y) ^ (x & z) ^ (y & z)


def sha256_bsig0(x is u32) returns u32
    return sha256_rotr32(x, 2) ^ sha256_rotr32(x, 13) ^ sha256_rotr32(x, 22)


def sha256_bsig1(x is u32) returns u32
    return sha256_rotr32(x, 6) ^ sha256_rotr32(x, 11) ^ sha256_rotr32(x, 25)


def sha256_ssig0(x is u32) returns u32
    return sha256_rotr32(x, 7) ^ sha256_rotr32(x, 18) ^ (x >> 3)


def sha256_ssig1(x is u32) returns u32
    return sha256_rotr32(x, 17) ^ sha256_rotr32(x, 19) ^ (x >> 10)


def sha256_init(s is mut ref Sha256) returns i32
    (*s).h0 = SHA256_H0
    (*s).h1 = SHA256_H1
    (*s).h2 = SHA256_H2
    (*s).h3 = SHA256_H3
    (*s).h4 = SHA256_H4
    (*s).h5 = SHA256_H5
    (*s).h6 = SHA256_H6
    (*s).h7 = SHA256_H7
    (*s).nbytes = 0
    (*s).block_len = 0
    (*s).block = malloc(64)
    if (*s).block is null then
        return 1
    # zero block
    var b is slice of u8 = (*s).block
    var i is usize = 0
    while i < 64 do
        b[i] = 0
        i = i + 1
    return 0


def sha256_free(s is mut ref Sha256) returns ()
    if (*s).block is not null then
        free((*s).block)
    (*s).block = null
    (*s).block_len = 0
    (*s).nbytes = 0
    return


def sha256_k(i is usize) returns u32
    # Unrolled constants via if-chain (small sizes; called 64x per compress).
    if i == 0 then
        return SHA256_K0
    if i == 1 then
        return SHA256_K1
    if i == 2 then
        return SHA256_K2
    if i == 3 then
        return SHA256_K3
    if i == 4 then
        return SHA256_K4
    if i == 5 then
        return SHA256_K5
    if i == 6 then
        return SHA256_K6
    if i == 7 then
        return SHA256_K7
    if i == 8 then
        return SHA256_K8
    if i == 9 then
        return SHA256_K9
    if i == 10 then
        return SHA256_K10
    if i == 11 then
        return SHA256_K11
    if i == 12 then
        return SHA256_K12
    if i == 13 then
        return SHA256_K13
    if i == 14 then
        return SHA256_K14
    if i == 15 then
        return SHA256_K15
    if i == 16 then
        return SHA256_K16
    if i == 17 then
        return SHA256_K17
    if i == 18 then
        return SHA256_K18
    if i == 19 then
        return SHA256_K19
    if i == 20 then
        return SHA256_K20
    if i == 21 then
        return SHA256_K21
    if i == 22 then
        return SHA256_K22
    if i == 23 then
        return SHA256_K23
    if i == 24 then
        return SHA256_K24
    if i == 25 then
        return SHA256_K25
    if i == 26 then
        return SHA256_K26
    if i == 27 then
        return SHA256_K27
    if i == 28 then
        return SHA256_K28
    if i == 29 then
        return SHA256_K29
    if i == 30 then
        return SHA256_K30
    if i == 31 then
        return SHA256_K31
    if i == 32 then
        return SHA256_K32
    if i == 33 then
        return SHA256_K33
    if i == 34 then
        return SHA256_K34
    if i == 35 then
        return SHA256_K35
    if i == 36 then
        return SHA256_K36
    if i == 37 then
        return SHA256_K37
    if i == 38 then
        return SHA256_K38
    if i == 39 then
        return SHA256_K39
    if i == 40 then
        return SHA256_K40
    if i == 41 then
        return SHA256_K41
    if i == 42 then
        return SHA256_K42
    if i == 43 then
        return SHA256_K43
    if i == 44 then
        return SHA256_K44
    if i == 45 then
        return SHA256_K45
    if i == 46 then
        return SHA256_K46
    if i == 47 then
        return SHA256_K47
    if i == 48 then
        return SHA256_K48
    if i == 49 then
        return SHA256_K49
    if i == 50 then
        return SHA256_K50
    if i == 51 then
        return SHA256_K51
    if i == 52 then
        return SHA256_K52
    if i == 53 then
        return SHA256_K53
    if i == 54 then
        return SHA256_K54
    if i == 55 then
        return SHA256_K55
    if i == 56 then
        return SHA256_K56
    if i == 57 then
        return SHA256_K57
    if i == 58 then
        return SHA256_K58
    if i == 59 then
        return SHA256_K59
    if i == 60 then
        return SHA256_K60
    if i == 61 then
        return SHA256_K61
    if i == 62 then
        return SHA256_K62
    return SHA256_K63


def sha256_compress(s is mut ref Sha256) returns i32
    var wmem is MutString = malloc(64 * 4)
    if wmem is null then
        return 1
    var w is slice of u32 = wmem
    var b is slice of u8 = (*s).block

    # w[0..15] from big-endian bytes.
    var i is usize = 0
    while i < 16 do
        var j is usize = i * 4
        var b0 is u32 = b[j + 0]
        var b1 is u32 = b[j + 1]
        var b2 is u32 = b[j + 2]
        var b3 is u32 = b[j + 3]
        w[i] = (b0 << 24) | (b1 << 16) | (b2 << 8) | (b3)
        i = i + 1

    var t is usize = 16
    while t < 64 do
        var s0 is u32 = sha256_ssig0(w[t - 15])
        var s1 is u32 = sha256_ssig1(w[t - 2])
        w[t] = w[t - 16] + s0 + w[t - 7] + s1
        t = t + 1

    var a is u32 = (*s).h0
    var c is u32 = (*s).h2
    var d is u32 = (*s).h3
    var e is u32 = (*s).h4
    var f is u32 = (*s).h5
    var g is u32 = (*s).h6
    var h is u32 = (*s).h7
    var bb is u32 = (*s).h1

    var r is usize = 0
    while r < 64 do
        var t1 is u32 = h + sha256_bsig1(e) + sha256_ch(e, f, g) + sha256_k(r) + w[r]
        var t2 is u32 = sha256_bsig0(a) + sha256_maj(a, bb, c)
        h = g
        g = f
        f = e
        e = d + t1
        d = c
        c = bb
        bb = a
        a = t1 + t2
        r = r + 1

    (*s).h0 = (*s).h0 + a
    (*s).h1 = (*s).h1 + bb
    (*s).h2 = (*s).h2 + c
    (*s).h3 = (*s).h3 + d
    (*s).h4 = (*s).h4 + e
    (*s).h5 = (*s).h5 + f
    (*s).h6 = (*s).h6 + g
    (*s).h7 = (*s).h7 + h

    free(wmem)
    return 0


def sha256_update(s is mut ref Sha256, data is String, n is usize) returns i32
    if data is null then
        return 1
    var b is slice of u8 = (*s).block
    var i is usize = 0
    while i < n do
        var bl is usize = (*s).block_len
        b[bl] = data[i]
        (*s).block_len = (*s).block_len + 1
        (*s).nbytes = (*s).nbytes + 1
        if (*s).block_len == 64 then
            if sha256_compress(s) != 0 then
                return 1
            (*s).block_len = 0
        i = i + 1
    return 0


def sha256_final(s is mut ref Sha256, out32 is MutString) returns i32
    if out32 is null then
        return 1
    var b is slice of u8 = (*s).block
    var blen is usize = (*s).block_len
    b[blen] = 0x80
    blen = blen + 1

    # pad with zeros until we have 56 bytes in the block
    while blen != 56 do
        if blen == 64 then
            (*s).block_len = 64
            if sha256_compress(s) != 0 then
                return 1
            blen = 0
        b[blen] = 0
        blen = blen + 1

    # append 64-bit big-endian length in bits
    var bit_len is u64 = (*s).nbytes * 8
    var j is usize = 0
    while j < 8 do
        var shift is u64 = j * 8
        var byte is u8 = (bit_len >> shift) & 0xff
        b[56 + (7 - j)] = byte
        j = j + 1

    (*s).block_len = 64
    if sha256_compress(s) != 0 then
        return 1
    (*s).block_len = 0

    # output big-endian digest
    var outb is slice of u8 = out32
    var hs is slice of u32 = malloc(8 * 4)
    if hs is null then
        return 1
    hs[0] = (*s).h0
    hs[1] = (*s).h1
    hs[2] = (*s).h2
    hs[3] = (*s).h3
    hs[4] = (*s).h4
    hs[5] = (*s).h5
    hs[6] = (*s).h6
    hs[7] = (*s).h7

    var wi is usize = 0
    while wi < 8 do
        var v is u32 = hs[wi]
        outb[wi * 4 + 0] = (v >> 24) & 0xff
        outb[wi * 4 + 1] = (v >> 16) & 0xff
        outb[wi * 4 + 2] = (v >> 8) & 0xff
        outb[wi * 4 + 3] = (v) & 0xff
        wi = wi + 1
    free(hs)
    return 0


def sha256_hex_two(a is String, a_len is usize, b is String, b_len is usize) returns MutString
    var st is Sha256
    if sha256_init(&st) != 0 then
        return null

    if sha256_update(&st, a, a_len) != 0 then
        sha256_free(&st)
        return null
    if sha256_update(&st, b, b_len) != 0 then
        sha256_free(&st)
        return null

    var digest is MutString = malloc(32)
    if digest is null then
        sha256_free(&st)
        return null
    if sha256_final(&st, digest) != 0 then
        free(digest)
        sha256_free(&st)
        return null

    var hex is MutString = malloc(65)
    if hex is null then
        free(digest)
        sha256_free(&st)
        return null
    var hexd is String = "0123456789abcdef"
    var db is slice of u8 = digest
    var hb is slice of u8 = hex
    var i is usize = 0
    while i < 32 do
        var v is u8 = db[i]
        hb[i * 2 + 0] = hexd[(v >> 4) & 0x0f]
        hb[i * 2 + 1] = hexd[v & 0x0f]
        i = i + 1
    hb[64] = 0

    free(digest)
    sha256_free(&st)
    return hex


# -----------------------------
# CPU kernel compile + launch
# -----------------------------

def cpu_cache_path(hash_hex is String, suffix is String) returns MutString
    return cstr_concat3(".context/ml/cpu_cache/", hash_hex, suffix)


def cpu_build_clang_cmd(flags is String, c_path is String, dylib_path is String) returns MutString
    var p0 is MutString = cstr_concat3("clang ", flags, " -o ")
    if p0 is null then
        return null
    var p1 is MutString = cstr_concat3(p0, dylib_path, " ")
    free(p0)
    if p1 is null then
        return null
    var p2 is MutString = cstr_concat2(p1, c_path)
    free(p1)
    return p2


def cpu_ewise_f32_run(op is i32, out_ptr is MutString, a_ptr is MutString, b_ptr is MutString, n is usize) returns i32
    if out_ptr is null or a_ptr is null then
        return 1
    var src is String = c_render_ewise_f32(op)
    if src is null then
        return 1

    var src_len is usize = strlen(src)
    var flags_len is usize = strlen(CPU_CLANG_FLAGS)
    var hash_hex is MutString = sha256_hex_two(src, src_len, CPU_CLANG_FLAGS, flags_len)
    if hash_hex is null then
        return 1

    # Ensure cache directory exists (best-effort).
    if system(CPU_CACHE_MKDIR_CMD) != 0 then
        free(hash_hex)
        return 1

    var c_path is MutString = cpu_cache_path(hash_hex, ".c")
    var dylib_path is MutString = cpu_cache_path(hash_hex, ".dylib")
    free(hash_hex)
    if c_path is null or dylib_path is null then
        if c_path is not null then
            free(c_path)
        if dylib_path is not null then
            free(dylib_path)
        return 1

    if file_exists(dylib_path) == 0 then
        if file_write_all(c_path, src, src_len) != 0 then
            free(c_path)
            free(dylib_path)
            return 1
        var cmd is MutString = cpu_build_clang_cmd(CPU_CLANG_FLAGS, c_path, dylib_path)
        if cmd is null then
            free(c_path)
            free(dylib_path)
            return 1
        var rc is i32 = system(cmd)
        free(cmd)
        if rc != 0 then
            free(c_path)
            free(dylib_path)
            return 1

    # Load and launch.
    var h is MutString = dlopen(dylib_path, RTLD_NOW)
    if h is null then
        free(c_path)
        free(dylib_path)
        return 1
    var fn is MutString = dlsym(h, CPU_KERNEL_ENTRY_SYM)
    if fn is null then
        dlclose(h)
        free(c_path)
        free(dylib_path)
        return 1

    var q is MutString = dispatch_get_global_queue(0, 0)
    if q is null then
        dlclose(h)
        free(c_path)
        free(dylib_path)
        return 1

    var ctx_mem is MutString = malloc(32)  # sizeof(CpuKernelCtx) on 64-bit
    if ctx_mem is null then
        dlclose(h)
        free(c_path)
        free(dylib_path)
        return 1
    var ctx is mut ref CpuKernelCtx = ctx_mem
    (*ctx).out = out_ptr
    (*ctx).a = a_ptr
    (*ctx).b = b_ptr
    (*ctx).n = n

    dispatch_sync_f(q, ctx_mem, fn)
    free(ctx_mem)

    dlclose(h)
    free(c_path)
    free(dylib_path)
    return 0


# Public API: elementwise ops over float32 buffers using (base, byte_off) pairs.

def cpu_add_f32(out_base is MutString, out_off is usize, a_base is MutString, a_off is usize, b_base is MutString, b_off is usize, n is usize) returns i32
    return cpu_ewise_f32_run(C_EWISE_ADD_F32, out_base + out_off, a_base + a_off, b_base + b_off, n)


def cpu_mul_f32(out_base is MutString, out_off is usize, a_base is MutString, a_off is usize, b_base is MutString, b_off is usize, n is usize) returns i32
    return cpu_ewise_f32_run(C_EWISE_MUL_F32, out_base + out_off, a_base + a_off, b_base + b_off, n)


def cpu_relu_f32(out_base is MutString, out_off is usize, a_base is MutString, a_off is usize, n is usize) returns i32
    return cpu_ewise_f32_run(C_EWISE_RELU_F32, out_base + out_off, a_base + a_off, null, n)
