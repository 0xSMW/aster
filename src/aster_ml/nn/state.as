# aster_ml.nn.state (v0)
#
# Phase 7 (minimal): serialization + model IO parity
# - StateDict: tiny string -> TensorF32 map (owned keys + owned tensors).
# - safetensors: minimal header+data load/save for float32 CPU tensors.
# - GGUF: minimal loader for a tiny subset (F32 + Q8_0) sufficient for tests.
# - gzip/tar/zip extract helpers: minimal wrappers around system tools.
#
# Notes:
# - This file provides its own tiny float32 CPU tensor struct (contiguous,
#   ndim<=3) to keep serialization work unblocked while the main Tensor API
#   evolves into a buffer-backed strided descriptor.
# - Correctness-first, minimal surface area.

use core.libc

# ---- libc extras (not yet centralized in core.libc) ----
extern def fwrite(ptr is MutString, size is usize, count is usize, fp is File) returns usize
extern def fflush(fp is File) returns i32
extern def system(cmd is String) returns i32

const SEEK_SET is i32 = 0
const SEEK_END is i32 = 2

const TENSORF32_BYTES is usize = 40  # sizeof(TensorF32) on 64-bit today (v0)

# -----------------------------
# Tiny float32 CPU Tensor (contiguous, v0)
# -----------------------------

struct TensorF32
    # Note: struct field types currently don't accept `slice of T`, so store the
    # raw pointer and cast to `slice of f32` at use sites.
    var data is MutString
    var ndim is usize
    var d0 is usize
    var d1 is usize
    var d2 is usize


def tensor_f32_numel(t is mut ref TensorF32) returns usize
    if (*t).ndim == 0 then
        return 0
    if (*t).ndim == 1 then
        return (*t).d0
    if (*t).ndim == 2 then
        return (*t).d0 * (*t).d1
    return (*t).d0 * (*t).d1 * (*t).d2


def tensor_f32_init(t is mut ref TensorF32, ndim is usize, d0 is usize, d1 is usize, d2 is usize) returns i32
    (*t).ndim = ndim
    (*t).d0 = d0
    (*t).d1 = d1
    (*t).d2 = d2
    var n is usize = tensor_f32_numel(t)
    (*t).data = malloc(n * 4)
    if (*t).data is null then
        return 1
    return 0


def tensor_f32_free(t is mut ref TensorF32) returns ()
    if (*t).data is not null then
        free((*t).data)
    (*t).data = null
    (*t).ndim = 0
    (*t).d0 = 0
    (*t).d1 = 0
    (*t).d2 = 0
    return


# -----------------------------
# Small byte builder
# -----------------------------

struct ByteVec
    var data is MutString  # `slice of u8`
    var len is usize
    var cap is usize


def bytevec_init(v is mut ref ByteVec) returns ()
    (*v).data = null
    (*v).len = 0
    (*v).cap = 0
    return


def bytevec_free(v is mut ref ByteVec) returns ()
    if (*v).data is not null then
        free((*v).data)
    (*v).data = null
    (*v).len = 0
    (*v).cap = 0
    return


def bytevec_reserve(v is mut ref ByteVec, want is usize) returns i32
    if want <= (*v).cap then
        return 0
    var new_cap is usize = (*v).cap
    if new_cap < 64 then
        new_cap = 64
    while new_cap < want do
        new_cap = new_cap * 2
    var new_data is MutString = malloc(new_cap)
    if new_data is null then
        return 1
    if (*v).data is not null and (*v).len != 0 then
        memcpy(new_data, (*v).data, (*v).len)
        free((*v).data)
    (*v).data = new_data
    (*v).cap = new_cap
    return 0


def bytevec_push_u8(v is mut ref ByteVec, c is u8) returns i32
    if bytevec_reserve(v, (*v).len + 1) != 0 then
        return 1
    var xs is slice of u8 = (*v).data
    xs[(*v).len] = c
    (*v).len = (*v).len + 1
    return 0


def bytevec_append_bytes(v is mut ref ByteVec, p is MutString, n is usize) returns i32
    if n == 0 then
        return 0
    if bytevec_reserve(v, (*v).len + n) != 0 then
        return 1
    memcpy((*v).data + (*v).len, p, n)
    (*v).len = (*v).len + n
    return 0


def bytevec_append_cstr(v is mut ref ByteVec, s is String) returns i32
    if s is null then
        return 1
    var n is usize = strlen(s)
    return bytevec_append_bytes(v, s, n)


def bytevec_take_cstr(v is mut ref ByteVec) returns MutString
    # NUL-terminate and return owned string (caller takes ownership).
    if bytevec_reserve(v, (*v).len + 1) != 0 then
        return null
    var xs is slice of u8 = (*v).data
    xs[(*v).len] = 0
    var out is MutString = (*v).data
    (*v).data = null
    (*v).len = 0
    (*v).cap = 0
    return out


# -----------------------------
# String helpers
# -----------------------------

def str_eq(a is String, b is String) returns i32
    if a is null or b is null then
        return 0
    var pa is String = a
    var pb is String = b
    while pa[0] != 0 or pb[0] != 0 do
        if pa[0] != pb[0] then
            return 0
        pa = pa + 1
        pb = pb + 1
    return 1


def str_dup(s is String) returns MutString
    if s is null then
        return null
    var n is usize = strlen(s)
    var p is MutString = malloc(n + 1)
    if p is null then
        return null
    if n != 0 then
        memcpy(p, s, n)
    var xs is slice of u8 = p
    xs[n] = 0
    return p


def str_dup_n(s is MutString, n is usize) returns MutString
    var p is MutString = malloc(n + 1)
    if p is null then
        return null
    if n != 0 then
        memcpy(p, s, n)
    var xs is slice of u8 = p
    xs[n] = 0
    return p


def str_concat2(a is String, b is String) returns MutString
    if a is null or b is null then
        return null
    var na is usize = strlen(a)
    var nb is usize = strlen(b)
    var p is MutString = malloc(na + nb + 1)
    if p is null then
        return null
    if na != 0 then
        memcpy(p, a, na)
    if nb != 0 then
        memcpy(p + na, b, nb)
    var xs is slice of u8 = p
    xs[na + nb] = 0
    return p


def str_concat3(a is String, b is String, c is String) returns MutString
    var ab is MutString = str_concat2(a, b)
    if ab is null then
        return null
    var abc is MutString = str_concat2(ab, c)
    free(ab)
    return abc


def json_append_escaped(v is mut ref ByteVec, s is String) returns i32
    # Minimal JSON string escaping (supports \" and \\ only).
    if s is null then
        return 1
    var p is String = s
    while p[0] != 0 do
        var c is u8 = p[0]
        if c == '\"' then
            if bytevec_push_u8(v, '\\') != 0 then
                return 1
            if bytevec_push_u8(v, '\"') != 0 then
                return 1
        else if c == '\\' then
            if bytevec_push_u8(v, '\\') != 0 then
                return 1
            if bytevec_push_u8(v, '\\') != 0 then
                return 1
        else
            if c < 32 then
                return 1
            if bytevec_push_u8(v, c) != 0 then
                return 1
        p = p + 1
    return 0


def append_u64_dec(v is mut ref ByteVec, x is u64) returns i32
    if x == 0 then
        return bytevec_push_u8(v, '0')
    var tmp is MutString = malloc(32)
    if tmp is null then
        return 1
    var tb is slice of u8 = tmp
    var n is usize = 0
    var y is u64 = x
    while y != 0 do
        # Avoid `%` since it isn't part of the strict Aster1 operator set (and
        # older backends may lower it incorrectly). Use `d = y - (y/10)*10`.
        var q is u64 = y / 10
        var d is u64 = y - (q * 10)
        tb[n] = '0' + d
        n = n + 1
        y = q
    # reverse
    while n > 0 do
        n = n - 1
        if bytevec_push_u8(v, tb[n]) != 0 then
            free(tmp)
            return 1
    free(tmp)
    return 0


# -----------------------------
# StateDict: string -> TensorF32
# -----------------------------

def hash_str(s is String) returns u64
    # FNV-1a 64-bit
    var h is u64 = 1469598103934665603
    if s is null then
        return 1
    var p is String = s
    while p[0] != 0 do
        h = h ^ p[0]
        h = h * 1099511628211
        p = p + 1
    if h == 0 then
        return 1
    return h


struct StateDict
    var tab_hash is MutString  # `slice of u64` (0 means empty)
    var tab_key is MutString   # `slice of MutString` (owned NUL-terminated)
    var tab_val is MutString   # `slice of MutString` (TensorF32*)
    var cap is usize
    var len is usize


def state_dict_init(sd is mut ref StateDict) returns i32
    (*sd).cap = 16
    (*sd).len = 0
    (*sd).tab_hash = calloc((*sd).cap, 8)
    if (*sd).tab_hash is null then
        return 1
    (*sd).tab_key = calloc((*sd).cap, 8)
    if (*sd).tab_key is null then
        free((*sd).tab_hash)
        (*sd).tab_hash = null
        return 1
    (*sd).tab_val = calloc((*sd).cap, 8)
    if (*sd).tab_val is null then
        free((*sd).tab_hash)
        free((*sd).tab_key)
        (*sd).tab_hash = null
        (*sd).tab_key = null
        return 1
    return 0


def state_dict_free(sd is mut ref StateDict) returns ()
    if (*sd).tab_hash is null then
        return
    var hs is slice of u64 = (*sd).tab_hash
    var ks is slice of MutString = (*sd).tab_key
    var vs is slice of MutString = (*sd).tab_val
    var i is usize = 0
    while i < (*sd).cap do
        if hs[i] != 0 then
            if ks[i] is not null then
                free(ks[i])
            if vs[i] is not null then
                var t is mut ref TensorF32 = vs[i]
                tensor_f32_free(t)
                free(vs[i])
        i = i + 1
    free((*sd).tab_hash)
    free((*sd).tab_key)
    free((*sd).tab_val)
    (*sd).tab_hash = null
    (*sd).tab_key = null
    (*sd).tab_val = null
    (*sd).cap = 0
    (*sd).len = 0
    return


def state_dict_find_slot(sd is mut ref StateDict, key is String, h is u64, found is mut ref i32) returns usize
    var hs is slice of u64 = (*sd).tab_hash
    var ks is slice of MutString = (*sd).tab_key
    var mask is usize = (*sd).cap - 1
    var idx is usize = h
    idx = idx & mask
    while hs[idx] != 0 do
        if hs[idx] == h and str_eq(ks[idx], key) != 0 then
            *found = 1
            return idx
        idx = (idx + 1) & mask
    *found = 0
    return idx


def state_dict_grow(sd is mut ref StateDict) returns i32
    var old_cap is usize = (*sd).cap
    var new_cap is usize = old_cap * 2
    var new_hash is MutString = calloc(new_cap, 8)
    if new_hash is null then
        return 1
    var new_key is MutString = calloc(new_cap, 8)
    if new_key is null then
        free(new_hash)
        return 1
    var new_val is MutString = calloc(new_cap, 8)
    if new_val is null then
        free(new_hash)
        free(new_key)
        return 1

    var oldh is slice of u64 = (*sd).tab_hash
    var oldk is slice of MutString = (*sd).tab_key
    var oldv is slice of MutString = (*sd).tab_val
    var nh is slice of u64 = new_hash
    var nk is slice of MutString = new_key
    var nv is slice of MutString = new_val

    var mask is usize = new_cap - 1
    var i is usize = 0
    while i < old_cap do
        var h is u64 = oldh[i]
        if h != 0 then
            var idx is usize = h
            idx = idx & mask
            while nh[idx] != 0 do
                idx = (idx + 1) & mask
            nh[idx] = h
            nk[idx] = oldk[i]
            nv[idx] = oldv[i]
        i = i + 1

    free((*sd).tab_hash)
    free((*sd).tab_key)
    free((*sd).tab_val)
    (*sd).tab_hash = new_hash
    (*sd).tab_key = new_key
    (*sd).tab_val = new_val
    (*sd).cap = new_cap
    return 0


def state_dict_put_take(sd is mut ref StateDict, key_owned is MutString, t_owned is MutString) returns i32
    if key_owned is null or t_owned is null then
        if key_owned is not null then
            free(key_owned)
        if t_owned is not null then
            var tt is mut ref TensorF32 = t_owned
            tensor_f32_free(tt)
            free(t_owned)
        return 1

    # Grow at ~70% load.
    if ((*sd).len + 1) * 10 >= (*sd).cap * 7 then
        if state_dict_grow(sd) != 0 then
            free(key_owned)
            var t0 is mut ref TensorF32 = t_owned
            tensor_f32_free(t0)
            free(t_owned)
            return 1

    var h is u64 = hash_str(key_owned)
    var found is i32 = 0
    var idx is usize = state_dict_find_slot(sd, key_owned, h, &found)

    var hs is slice of u64 = (*sd).tab_hash
    var ks is slice of MutString = (*sd).tab_key
    var vs is slice of MutString = (*sd).tab_val
    if found != 0 then
        # replace
        if ks[idx] is not null then
            free(ks[idx])
        if vs[idx] is not null then
            var t_old is mut ref TensorF32 = vs[idx]
            tensor_f32_free(t_old)
            free(vs[idx])
        ks[idx] = key_owned
        vs[idx] = t_owned
        hs[idx] = h
        return 0

    hs[idx] = h
    ks[idx] = key_owned
    vs[idx] = t_owned
    (*sd).len = (*sd).len + 1
    return 0


def state_dict_put_copy(sd is mut ref StateDict, key is String, t is mut ref TensorF32) returns i32
    # Copy key + tensor payload into owned storage.
    if key is null or t is null then
        return 1
    var key_owned is MutString = str_dup(key)
    if key_owned is null then
        return 1

    var tp is MutString = malloc(TENSORF32_BYTES)
    if tp is null then
        free(key_owned)
        return 1
    var tt is mut ref TensorF32 = tp
    if tensor_f32_init(tt, (*t).ndim, (*t).d0, (*t).d1, (*t).d2) != 0 then
        free(tp)
        free(key_owned)
        return 1
    var nbytes is usize = tensor_f32_numel(t) * 4
    if nbytes != 0 then
        memcpy((*tt).data, (*t).data, nbytes)
    return state_dict_put_take(sd, key_owned, tp)


def state_dict_get(sd is mut ref StateDict, key is String) returns MutString
    if (*sd).tab_hash is null then
        return null
    var h is u64 = hash_str(key)
    var found is i32 = 0
    var idx is usize = state_dict_find_slot(sd, key, h, &found)
    if found == 0 then
        return null
    var vs is slice of MutString = (*sd).tab_val
    return vs[idx]


def state_dict_len(sd is mut ref StateDict) returns usize
    return (*sd).len


# -----------------------------
# File helpers
# -----------------------------

def read_file(path is String, out_buf is mut ref MutString, out_len is mut ref usize) returns i32
    *out_buf = null
    *out_len = 0
    var fp is File = fopen(path, "rb")
    if fp is null then
        return 1
    if fseek(fp, 0, SEEK_END) != 0 then
        fclose(fp)
        return 1
    var sz is isize = ftell(fp)
    if sz < 0 then
        fclose(fp)
        return 1
    if fseek(fp, 0, SEEK_SET) != 0 then
        fclose(fp)
        return 1
    var n is usize = sz
    var buf is MutString = malloc(n)
    if buf is null then
        fclose(fp)
        return 1
    var got is usize = fread(buf, 1, n, fp)
    fclose(fp)
    if got != n then
        free(buf)
        return 1
    *out_buf = buf
    *out_len = n
    return 0


def write_u64_le(fp is File, x is u64) returns i32
    var tmp is MutString = malloc(8)
    if tmp is null then
        return 1
    var b is slice of u8 = tmp
    b[0] = x & 0xff
    b[1] = (x >> 8) & 0xff
    b[2] = (x >> 16) & 0xff
    b[3] = (x >> 24) & 0xff
    b[4] = (x >> 32) & 0xff
    b[5] = (x >> 40) & 0xff
    b[6] = (x >> 48) & 0xff
    b[7] = (x >> 56) & 0xff
    var n is usize = fwrite(tmp, 1, 8, fp)
    free(tmp)
    if n != 8 then
        return 1
    return 0


def read_u32_le(p is MutString) returns u32
    var b is slice of u8 = p
    var x is u32 = 0
    x = x | b[0]
    x = x | (b[1] << 8)
    x = x | (b[2] << 16)
    x = x | (b[3] << 24)
    return x


def read_u64_le(p is MutString) returns u64
    var b is slice of u8 = p
    var x is u64 = 0
    x = x | b[0]
    x = x | (b[1] << 8)
    x = x | (b[2] << 16)
    x = x | (b[3] << 24)
    x = x | (b[4] << 32)
    x = x | (b[5] << 40)
    x = x | (b[6] << 48)
    x = x | (b[7] << 56)
    return x


# -----------------------------
# safetensors (minimal subset)
# -----------------------------

def safetensors_save_f32(path is String, sd is mut ref StateDict) returns i32
    if path is null then
        return 1
    if (*sd).tab_hash is null then
        return 1

    # Build header JSON.
    var hdr is ByteVec
    bytevec_init(&hdr)
    if bytevec_push_u8(&hdr, '{') != 0 then
        bytevec_free(&hdr)
        return 1

    var hs is slice of u64 = (*sd).tab_hash
    var ks is slice of MutString = (*sd).tab_key
    var vs is slice of MutString = (*sd).tab_val
    var first is i32 = 1
    var off is u64 = 0

    var i is usize = 0
    while i < (*sd).cap do
        if hs[i] != 0 then
            var tp is MutString = vs[i]
            if tp is null then
                bytevec_free(&hdr)
                return 1
            var t is mut ref TensorF32 = tp
            var nbytes is u64 = tensor_f32_numel(t) * 4

            if first == 0 then
                if bytevec_push_u8(&hdr, ',') != 0 then
                    bytevec_free(&hdr)
                    return 1
            else
                first = 0

            # "<name>":{...}
            if bytevec_push_u8(&hdr, '\"') != 0 then
                bytevec_free(&hdr)
                return 1
            if json_append_escaped(&hdr, ks[i]) != 0 then
                bytevec_free(&hdr)
                return 1
            if bytevec_append_cstr(&hdr, "\":{\"dtype\":\"F32\",\"shape\":[") != 0 then
                bytevec_free(&hdr)
                return 1

            if (*t).ndim == 1 then
                if append_u64_dec(&hdr, (*t).d0) != 0 then
                    bytevec_free(&hdr)
                    return 1
            else if (*t).ndim == 2 then
                if append_u64_dec(&hdr, (*t).d0) != 0 then
                    bytevec_free(&hdr)
                    return 1
                if bytevec_push_u8(&hdr, ',') != 0 then
                    bytevec_free(&hdr)
                    return 1
                if append_u64_dec(&hdr, (*t).d1) != 0 then
                    bytevec_free(&hdr)
                    return 1
            else if (*t).ndim == 3 then
                if append_u64_dec(&hdr, (*t).d0) != 0 then
                    bytevec_free(&hdr)
                    return 1
                if bytevec_push_u8(&hdr, ',') != 0 then
                    bytevec_free(&hdr)
                    return 1
                if append_u64_dec(&hdr, (*t).d1) != 0 then
                    bytevec_free(&hdr)
                    return 1
                if bytevec_push_u8(&hdr, ',') != 0 then
                    bytevec_free(&hdr)
                    return 1
                if append_u64_dec(&hdr, (*t).d2) != 0 then
                    bytevec_free(&hdr)
                    return 1
            else
                bytevec_free(&hdr)
                return 1

            if bytevec_append_cstr(&hdr, "],\"data_offsets\":[") != 0 then
                bytevec_free(&hdr)
                return 1
            if append_u64_dec(&hdr, off) != 0 then
                bytevec_free(&hdr)
                return 1
            if bytevec_push_u8(&hdr, ',') != 0 then
                bytevec_free(&hdr)
                return 1
            if append_u64_dec(&hdr, off + nbytes) != 0 then
                bytevec_free(&hdr)
                return 1
            if bytevec_append_cstr(&hdr, "]}") != 0 then
                bytevec_free(&hdr)
                return 1

            off = off + nbytes
        i = i + 1

    if bytevec_push_u8(&hdr, '}') != 0 then
        bytevec_free(&hdr)
        return 1

    var fp is File = fopen(path, "wb")
    if fp is null then
        bytevec_free(&hdr)
        return 1

    if write_u64_le(fp, hdr.len) != 0 then
        fclose(fp)
        bytevec_free(&hdr)
        return 1
    if fwrite(hdr.data, 1, hdr.len, fp) != hdr.len then
        fclose(fp)
        bytevec_free(&hdr)
        return 1

    # Write tensor data in the same iteration order used to build offsets.
    var j is usize = 0
    while j < (*sd).cap do
        if hs[j] != 0 then
            var tpp is MutString = vs[j]
            var tt is mut ref TensorF32 = tpp
            var nb is usize = tensor_f32_numel(tt) * 4
            if nb != 0 then
                if fwrite((*tt).data, 1, nb, fp) != nb then
                    fclose(fp)
                    bytevec_free(&hdr)
                    return 1
        j = j + 1

    fflush(fp)
    fclose(fp)
    bytevec_free(&hdr)
    return 0


# ---- minimal JSON parsing for safetensors header ----

def json_ws(p is mut ref String) returns ()
    while (*p)[0] == ' ' or (*p)[0] == '\n' or (*p)[0] == '\r' or (*p)[0] == '\t' do
        *p = *p + 1
    return


def json_expect(p is mut ref String, c is u8) returns i32
    json_ws(p)
    if (*p)[0] != c then
        return 1
    *p = *p + 1
    return 0


def json_parse_string(p is mut ref String) returns MutString
    json_ws(p)
    if (*p)[0] != '\"' then
        return null
    *p = *p + 1
    var out is ByteVec
    bytevec_init(&out)
    while (*p)[0] != 0 do
        var c is u8 = (*p)[0]
        if c == '\"' then
            *p = *p + 1
            return bytevec_take_cstr(&out)
        if c == '\\' then
            *p = *p + 1
            var esc is u8 = (*p)[0]
            if esc == 0 then
                bytevec_free(&out)
                return null
            # minimal: support \" and \\ only
            if esc == '\"' then
                if bytevec_push_u8(&out, '\"') != 0 then
                    bytevec_free(&out)
                    return null
            else if esc == '\\' then
                if bytevec_push_u8(&out, '\\') != 0 then
                    bytevec_free(&out)
                    return null
            else
                bytevec_free(&out)
                return null
            *p = *p + 1
            continue
        if bytevec_push_u8(&out, c) != 0 then
            bytevec_free(&out)
            return null
        *p = *p + 1
    bytevec_free(&out)
    return null


def json_parse_u64(p is mut ref String) returns u64
    # Caller must ensure the next non-whitespace character is a digit.
    json_ws(p)
    var s is String = *p
    var x is u64 = 0
    while s[0] >= '0' and s[0] <= '9' do
        x = x * 10 + (s[0] - '0')
        s = s + 1
    *p = s
    return x


def json_skip_value(p is mut ref String) returns i32
    # Minimal skip: supports object/array/string/number literals.
    json_ws(p)
    var c is u8 = (*p)[0]
    if c == '{' then
        *p = *p + 1
        json_ws(p)
        if (*p)[0] == '}' then
            *p = *p + 1
            return 0
        while 1 do
            var k is MutString = json_parse_string(p)
            if k is null then
                return 1
            free(k)
            if json_expect(p, ':') != 0 then
                return 1
            if json_skip_value(p) != 0 then
                return 1
            json_ws(p)
            if (*p)[0] == '}' then
                *p = *p + 1
                return 0
            if json_expect(p, ',') != 0 then
                return 1
        return 1
    if c == '[' then
        *p = *p + 1
        json_ws(p)
        if (*p)[0] == ']' then
            *p = *p + 1
            return 0
        while 1 do
            if json_skip_value(p) != 0 then
                return 1
            json_ws(p)
            if (*p)[0] == ']' then
                *p = *p + 1
                return 0
            if json_expect(p, ',') != 0 then
                return 1
        return 1
    if c == '\"' then
        var s is MutString = json_parse_string(p)
        if s is null then
            return 1
        free(s)
        return 0
    # number
    json_ws(p)
    if (*p)[0] < '0' or (*p)[0] > '9' then
        return 1
    json_parse_u64(p)
    return 0


def safetensors_load_f32(path is String, out is mut ref StateDict) returns i32
    if path is null then
        return 2
    var buf is MutString = null
    var n is usize = 0
    if read_file(path, &buf, &n) != 0 then
        return 3
    if n < 8 then
        free(buf)
        return 4
    var header_len is u64 = read_u64_le(buf)
    if 8 + header_len > n then
        free(buf)
        return 5

    var hcopy is MutString = malloc(header_len + 1)
    if hcopy is null then
        free(buf)
        return 6
    memcpy(hcopy, buf + 8, header_len)
    var hs is slice of u8 = hcopy
    hs[header_len] = 0

    var data_base is MutString = buf + 8 + header_len
    var data_len is usize = n - (8 + header_len)

    var p is String = hcopy
    if json_expect(&p, '{') != 0 then
        free(hcopy)
        free(buf)
        return 7
    json_ws(&p)
    if p[0] == '}' then
        free(hcopy)
        free(buf)
        return 0

    var done_obj is i32 = 0
    while done_obj == 0 do
        var name is MutString = json_parse_string(&p)
        if name is null then
            free(hcopy)
            free(buf)
            return 8
        if json_expect(&p, ':') != 0 then
            free(name)
            free(hcopy)
            free(buf)
            return 9

        if str_eq(name, "__metadata__") != 0 then
            free(name)
            if json_skip_value(&p) != 0 then
                free(hcopy)
                free(buf)
                return 10
        else
            # Parse tensor record object.
            if json_expect(&p, '{') != 0 then
                free(name)
                free(hcopy)
                free(buf)
                return 11

            var dtype_ok is i32 = 0
            var ndim is usize = 0
            var d0 is u64 = 1
            var d1 is u64 = 1
            var d2 is u64 = 1
            var off0 is u64 = 0
            var off1 is u64 = 0
            json_ws(&p)
            if p[0] == '}' then
                free(name)
                free(hcopy)
                free(buf)
                return 12

            var done_rec is i32 = 0
            while done_rec == 0 do
                var field is MutString = json_parse_string(&p)
                if field is null then
                    free(name)
                    free(hcopy)
                    free(buf)
                    return 13
                if json_expect(&p, ':') != 0 then
                    free(field)
                    free(name)
                    free(hcopy)
                    free(buf)
                    return 14

                if str_eq(field, "dtype") != 0 then
                    var dt is MutString = json_parse_string(&p)
                    if dt is null then
                        free(field)
                        free(name)
                        free(hcopy)
                        free(buf)
                        return 15
                    if str_eq(dt, "F32") != 0 then
                        dtype_ok = 1
                    free(dt)
                else if str_eq(field, "shape") != 0 then
                    if json_expect(&p, '[') != 0 then
                        free(field)
                        free(name)
                        free(hcopy)
                        free(buf)
                        return 16
                    json_ws(&p)
                    ndim = 0
                    if p[0] == ']' then
                        # scalar not supported in v0
                        free(field)
                        free(name)
                        free(hcopy)
                        free(buf)
                        return 17
                    var done_shape is i32 = 0
                    while done_shape == 0 do
                        json_ws(&p)
                        if p[0] < '0' or p[0] > '9' then
                            free(field)
                            free(name)
                            free(hcopy)
                            free(buf)
                            return 18
                        var dv is u64 = json_parse_u64(&p)
                        if ndim == 0 then
                            d0 = dv
                        else if ndim == 1 then
                            d1 = dv
                        else if ndim == 2 then
                            d2 = dv
                        else
                            free(field)
                            free(name)
                            free(hcopy)
                            free(buf)
                            return 19
                        ndim = ndim + 1
                        json_ws(&p)
                        if p[0] == ',' then
                            p = p + 1
                        else if p[0] == ']' then
                            p = p + 1
                            done_shape = 1
                        else
                            free(field)
                            free(name)
                            free(hcopy)
                            free(buf)
                            return 20
                    # end shape
                else if str_eq(field, "data_offsets") != 0 then
                    if json_expect(&p, '[') != 0 then
                        free(field)
                        free(name)
                        free(hcopy)
                        free(buf)
                        return 21
                    json_ws(&p)
                    if p[0] < '0' or p[0] > '9' then
                        free(field)
                        free(name)
                        free(hcopy)
                        free(buf)
                        return 22
                    off0 = json_parse_u64(&p)
                    if json_expect(&p, ',') != 0 then
                        free(field)
                        free(name)
                        free(hcopy)
                        free(buf)
                        return 23
                    json_ws(&p)
                    if p[0] < '0' or p[0] > '9' then
                        free(field)
                        free(name)
                        free(hcopy)
                        free(buf)
                        return 24
                    off1 = json_parse_u64(&p)
                    if json_expect(&p, ']') != 0 then
                        free(field)
                        free(name)
                        free(hcopy)
                        free(buf)
                        return 25
                else
                    # skip unknown field
                    if json_skip_value(&p) != 0 then
                        free(field)
                        free(name)
                        free(hcopy)
                        free(buf)
                        return 26
                free(field)

                json_ws(&p)
                if p[0] == ',' then
                    p = p + 1
                else if p[0] == '}' then
                    p = p + 1
                    done_rec = 1
                else
                    free(name)
                    free(hcopy)
                    free(buf)
                    return 27

            if dtype_ok == 0 or ndim == 0 then
                free(name)
                free(hcopy)
                free(buf)
                return 28

            var want_bytes is u64 = d0 * 4
            if ndim == 2 then
                want_bytes = d0 * d1 * 4
            else if ndim == 3 then
                want_bytes = d0 * d1 * d2 * 4
            else if ndim != 1 then
                free(name)
                free(hcopy)
                free(buf)
                return 29
            if off1 < off0 then
                free(name)
                free(hcopy)
                free(buf)
                return 30
            if off1 - off0 != want_bytes then
                free(name)
                free(hcopy)
                free(buf)
                return 31
            if off1 > data_len then
                free(name)
                free(hcopy)
                free(buf)
                return 32

            var tp is MutString = malloc(TENSORF32_BYTES)
            if tp is null then
                free(name)
                free(hcopy)
                free(buf)
                return 33
            var tt is mut ref TensorF32 = tp
            if tensor_f32_init(tt, ndim, d0, d1, d2) != 0 then
                free(tp)
                free(name)
                free(hcopy)
                free(buf)
                return 34
            if want_bytes != 0 then
                memcpy((*tt).data, data_base + off0, want_bytes)
            if state_dict_put_take(out, name, tp) != 0 then
                free(hcopy)
                free(buf)
                return 35

        json_ws(&p)
        if p[0] == ',' then
            p = p + 1
        else if p[0] == '}' then
            done_obj = 1
        else
            free(hcopy)
            free(buf)
            return 36

    free(hcopy)
    free(buf)
    return 0


# -----------------------------
# GGUF (tiny subset)
# -----------------------------

const GGUF_MAGIC0 is u8 = 'G'
const GGUF_MAGIC1 is u8 = 'G'
const GGUF_MAGIC2 is u8 = 'U'
const GGUF_MAGIC3 is u8 = 'F'

# gguf value types (subset)
const GGUF_TYPE_UINT32 is u32 = 4
const GGUF_TYPE_STRING is u32 = 8
const GGUF_TYPE_ARRAY is u32 = 9
const GGUF_TYPE_UINT64 is u32 = 10

# ggml tensor types (subset)
const GGML_TYPE_F32 is u32 = 0
const GGML_TYPE_Q8_0 is u32 = 8

def align_up(x is u64, a is u64) returns u64
    if a == 0 then
        return x
    # Avoid bitwise-not (`~`) since the Aster1 operator set is intentionally tiny.
    return ((x + a - 1) / a) * a


def f16_to_f32(h is u16) returns f32
    # IEEE-754 half -> float conversion via bit manipulation.
    var sign is u32 = (h & 0x8000)
    sign = sign << 16
    var exp is u32 = (h >> 10) & 0x1f
    var mant is u32 = h & 0x03ff
    var bits is u32 = 0
    if exp == 0 then
        if mant == 0 then
            bits = sign
        else
            # subnormal
            var e is i32 = -14
            var m is u32 = mant
            while (m & 0x0400) == 0 do
                m = m << 1
                e = e - 1
            m = m & 0x03ff
            var exp32 is u32 = (e + 127)
            bits = sign | (exp32 << 23) | (m << 13)
    else if exp == 31 then
        bits = sign | 0x7f800000 | (mant << 13)
    else
        var exp32 is u32 = (exp - 15 + 127)
        bits = sign | (exp32 << 23) | (mant << 13)

    # bitcast u32 -> f32
    var out is f32 = 0.0
    memcpy(&out, &bits, 4)
    return out


def gguf_skip_string(p is mut ref MutString, end is MutString) returns i32
    if *p + 8 > end then
        return 1
    var n is u64 = read_u64_le(*p)
    *p = *p + 8
    if *p + n > end then
        return 1
    *p = *p + n
    return 0


def gguf_skip_value(p is mut ref MutString, end is MutString, ty is u32) returns i32
    if ty == GGUF_TYPE_UINT32 then
        if *p + 4 > end then
            return 1
        *p = *p + 4
        return 0
    if ty == GGUF_TYPE_UINT64 then
        if *p + 8 > end then
            return 1
        *p = *p + 8
        return 0
    if ty == GGUF_TYPE_STRING then
        return gguf_skip_string(p, end)
    if ty == GGUF_TYPE_ARRAY then
        if *p + 4 + 8 > end then
            return 1
        var elem_ty is u32 = read_u32_le(*p)
        *p = *p + 4
        var n is u64 = read_u64_le(*p)
        *p = *p + 8
        # skip elements
        var i is u64 = 0
        while i < n do
            if gguf_skip_value(p, end, elem_ty) != 0 then
                return 1
            i = i + 1
        return 0
    return 1


def gguf_load_f32(path is String, out is mut ref StateDict) returns i32
    var buf is MutString = null
    var n is usize = 0
    if read_file(path, &buf, &n) != 0 then
        return 1
    if n < 32 then
        free(buf)
        return 1
    var end is MutString = buf + n

    var p is MutString = buf
    var b is slice of u8 = p
    if b[0] != GGUF_MAGIC0 or b[1] != GGUF_MAGIC1 or b[2] != GGUF_MAGIC2 or b[3] != GGUF_MAGIC3 then
        free(buf)
        return 1
    p = p + 4
    var version is u32 = read_u32_le(p)
    p = p + 4
    if version < 2 or version > 3 then
        free(buf)
        return 1
    var n_tensors is u64 = read_u64_le(p)
    p = p + 8
    var n_kv is u64 = read_u64_le(p)
    p = p + 8

    var alignment is u32 = 32
    # kv pairs
    var ki is u64 = 0
    while ki < n_kv do
        # key: gguf string (u64 len + bytes)
        if p + 8 > end then
            free(buf)
            return 1
        var klen is u64 = read_u64_le(p)
        p = p + 8
        if p + klen > end then
            free(buf)
            return 1
        var kptr is MutString = p
        p = p + klen
        if p + 4 > end then
            free(buf)
            return 1
        var vty is u32 = read_u32_le(p)
        p = p + 4

        # detect general.alignment (uint32)
        if klen == 17 then
            # "general.alignment"
            var ok is i32 = 1
            var s is String = kptr
            if s[0] != 'g' then
                ok = 0
            if ok != 0 and s[1] != 'e' then
                ok = 0
            if ok != 0 and s[2] != 'n' then
                ok = 0
            if ok != 0 and s[3] != 'e' then
                ok = 0
            if ok != 0 and s[4] != 'r' then
                ok = 0
            if ok != 0 and s[5] != 'a' then
                ok = 0
            if ok != 0 and s[6] != 'l' then
                ok = 0
            if ok != 0 and s[7] != '.' then
                ok = 0
            if ok != 0 and s[8] != 'a' then
                ok = 0
            if ok != 0 and s[9] != 'l' then
                ok = 0
            if ok != 0 and s[10] != 'i' then
                ok = 0
            if ok != 0 and s[11] != 'g' then
                ok = 0
            if ok != 0 and s[12] != 'n' then
                ok = 0
            if ok != 0 and s[13] != 'm' then
                ok = 0
            if ok != 0 and s[14] != 'e' then
                ok = 0
            if ok != 0 and s[15] != 'n' then
                ok = 0
            if ok != 0 and s[16] != 't' then
                ok = 0
            if ok != 0 and vty == GGUF_TYPE_UINT32 then
                if p + 4 > end then
                    free(buf)
                    return 1
                alignment = read_u32_le(p)
                p = p + 4
            else
                if gguf_skip_value(&p, end, vty) != 0 then
                    free(buf)
                    return 1
        else
            if gguf_skip_value(&p, end, vty) != 0 then
                free(buf)
                return 1
        ki = ki + 1

    # tensor infos
    if n_tensors > 1024 then
        free(buf)
        return 1
    var nt is usize = n_tensors
    var names_mem is MutString = malloc(nt * 8)
    var ndims_mem is MutString = malloc(nt * 8)
    var d0_mem is MutString = malloc(nt * 8)
    var d1_mem is MutString = malloc(nt * 8)
    var d2_mem is MutString = malloc(nt * 8)
    var ty_mem is MutString = malloc(nt * 8)
    var off_mem is MutString = malloc(nt * 8)
    if names_mem is null or ndims_mem is null or d0_mem is null or d1_mem is null or d2_mem is null or ty_mem is null or off_mem is null then
        if names_mem is not null then
            free(names_mem)
        if ndims_mem is not null then
            free(ndims_mem)
        if d0_mem is not null then
            free(d0_mem)
        if d1_mem is not null then
            free(d1_mem)
        if d2_mem is not null then
            free(d2_mem)
        if ty_mem is not null then
            free(ty_mem)
        if off_mem is not null then
            free(off_mem)
        free(buf)
        return 1
    var names is slice of MutString = names_mem
    var ndims is slice of u64 = ndims_mem
    var d0s is slice of u64 = d0_mem
    var d1s is slice of u64 = d1_mem
    var d2s is slice of u64 = d2_mem
    var tys is slice of u64 = ty_mem
    var offs is slice of u64 = off_mem

    var ti is usize = 0
    while ti < nt do
        # tensor name: gguf string (u64 len + bytes)
        if p + 8 > end then
            free(buf)
            return 1
        var nlen is u64 = read_u64_le(p)
        p = p + 8
        if p + nlen > end then
            free(buf)
            return 1
        var nm is MutString = str_dup_n(p, nlen)
        if nm is null then
            free(buf)
            return 1
        p = p + nlen
        if p + 4 > end then
            free(nm)
            free(buf)
            return 1
        var ndim is u32 = read_u32_le(p)
        p = p + 4
        if ndim == 0 or ndim > 3 then
            free(nm)
            free(buf)
            return 1
        if p + (ndim * 8) > end then
            free(nm)
            free(buf)
            return 1
        var d0 is u64 = read_u64_le(p)
        p = p + 8
        var d1 is u64 = 1
        var d2 is u64 = 1
        if ndim >= 2 then
            d1 = read_u64_le(p)
            p = p + 8
        if ndim == 3 then
            d2 = read_u64_le(p)
            p = p + 8
        if p + 4 + 8 > end then
            free(nm)
            free(buf)
            return 1
        var ttype is u32 = read_u32_le(p)
        p = p + 4
        var toff is u64 = read_u64_le(p)
        p = p + 8

        names[ti] = nm
        ndims[ti] = ndim
        d0s[ti] = d0
        d1s[ti] = d1
        d2s[ti] = d2
        tys[ti] = ttype
        offs[ti] = toff
        ti = ti + 1

    var data_start is u64 = align_up(p - buf, alignment)
    if data_start > n then
        free(buf)
        return 1

    # Load tensors
    var xi is usize = 0
    while xi < nt do
        var name is MutString = names[xi]
        var ndim0 is usize = ndims[xi]
        var d0 is u64 = d0s[xi]
        var d1 is u64 = d1s[xi]
        var d2 is u64 = d2s[xi]
        var ty is u32 = tys[xi]
        var toff is u64 = offs[xi]
        var numel is u64 = d0
        if ndim0 == 2 then
            numel = d0 * d1
        else if ndim0 == 3 then
            numel = d0 * d1 * d2

        var tp is MutString = malloc(TENSORF32_BYTES)
        if tp is null then
            free(buf)
            return 1
        var tt is mut ref TensorF32 = tp
        if tensor_f32_init(tt, ndim0, d0, d1, d2) != 0 then
            free(tp)
            free(buf)
            return 1
        var outp is slice of f32 = (*tt).data

        var data_ptr is MutString = buf + data_start + toff
        if ty == GGML_TYPE_F32 then
            var want is u64 = numel * 4
            if data_start + toff + want > n then
                tensor_f32_free(tt)
                free(tp)
                free(buf)
                return 1
            memcpy((*tt).data, data_ptr, want)
        else if ty == GGML_TYPE_Q8_0 then
            # Q8_0: blocks of 32 values: f16 scale + 32 int8
            if (numel & 31) != 0 then
                tensor_f32_free(tt)
                free(tp)
                free(buf)
                return 1
            var nblocks is u64 = numel >> 5
            var need is u64 = nblocks * 34
            if data_start + toff + need > n then
                tensor_f32_free(tt)
                free(tp)
                free(buf)
                return 1
            var bi is u64 = 0
            var outi is usize = 0
            while bi < nblocks do
                var blk is MutString = data_ptr + bi * 34
                var bb is slice of u8 = blk
                var hscale is u16 = bb[0] | (bb[1] << 8)
                var scale is f32 = f16_to_f32(hscale)
                var qi is usize = 0
                while qi < 32 do
                    var ub is u8 = bb[2 + qi]
                    var sv is i32 = ub
                    if ub >= 128 then
                        sv = sv - 256
                    outp[outi] = scale * sv
                    outi = outi + 1
                    qi = qi + 1
                bi = bi + 1
        else
            tensor_f32_free(tt)
            free(tp)
            free(buf)
            return 1

        # Insert (take ownership of name + tensor).
        if state_dict_put_take(out, name, tp) != 0 then
            free(buf)
            return 1
        xi = xi + 1

    free(names_mem)
    free(ndims_mem)
    free(d0_mem)
    free(d1_mem)
    free(d2_mem)
    free(ty_mem)
    free(off_mem)
    free(buf)
    return 0


# -----------------------------
# Minimal extraction helpers (wrappers around system tools)
# -----------------------------

def extract_gzip(gz_path is String, out_path is String) returns i32
    # Uses `/bin/sh -c` via system(); paths must be "simple" (no spaces/quotes).
    var cmd is MutString = str_concat3("gzip -dc ", gz_path, " > ")
    if cmd is null then
        return 1
    var cmd2 is MutString = str_concat2(cmd, out_path)
    free(cmd)
    if cmd2 is null then
        return 1
    var rc is i32 = system(cmd2)
    free(cmd2)
    if rc != 0 then
        return 1
    return 0


def extract_tar(tar_path is String, out_dir is String) returns i32
    # Uses system `tar`; paths must be "simple" (no spaces/quotes).
    var cmd is MutString = str_concat3("tar -xf ", tar_path, " -C ")
    if cmd is null then
        return 1
    var cmd2 is MutString = str_concat2(cmd, out_dir)
    free(cmd)
    if cmd2 is null then
        return 1
    var rc is i32 = system(cmd2)
    free(cmd2)
    if rc != 0 then
        return 1
    return 0


def extract_zip(zip_path is String, out_dir is String) returns i32
    # Uses system `unzip`; paths must be "simple" (no spaces/quotes).
    var cmd is MutString = str_concat3("unzip -q ", zip_path, " -d ")
    if cmd is null then
        return 1
    var cmd2 is MutString = str_concat2(cmd, out_dir)
    free(cmd)
    if cmd2 is null then
        return 1
    var rc is i32 = system(cmd2)
    free(cmd2)
    if rc != 0 then
        return 1
    return 0
