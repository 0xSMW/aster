# aster_ml.tensor_io (v0)
#
# Tensor construction helpers that touch the outside world (disk/network).
#
# Policy: the Aster compiler/toolchain must not rely on Python. This module
# uses the native `core.http` client for HTTPS downloads (no shelling out).

use core.libc
use core.http
use aster_ml.tensor

extern def realloc(ptr is MutString, n is usize) returns MutString

const SEEK_SET is i32 = 0
const SEEK_END is i32 = 2


def cstr_starts_with(s is String, prefix is String) returns i32
    if s is null or prefix is null then
        return 0
    var i is usize = 0
    var pb is slice of u8 = prefix
    var sb is slice of u8 = s
    while pb[i] != 0 do
        if sb[i] != pb[i] then
            return 0
        i = i + 1
    return 1


def cstr_dup_range(s is String, start is usize, end is usize) returns MutString
    if s is null then
        return null
    if end < start then
        return null
    var n is usize = end - start
    var out is MutString = malloc(n + 1)
    if out is null then
        return null
    if n != 0 then
        memcpy(out, s + start, n)
    var b is slice of u8 = out
    b[n] = 0
    return out


def tensor_load_raw_f32(out is mut ref Tensor, path is String) returns i32
    # Load a raw little-endian float32 blob from disk as a 1D owning tensor.
    if path is null then
        return 1
    var fp is File = fopen(path, "rb")
    if fp is null then
        return 2
    if fseek(fp, 0, SEEK_END) != 0 then
        fclose(fp)
        return 3
    var sz is isize = ftell(fp)
    if sz <= 0 then
        fclose(fp)
        return 4
    if fseek(fp, 0, SEEK_SET) != 0 then
        fclose(fp)
        return 5
    var nbytes is usize = sz
    var rem is usize = nbytes - ((nbytes / 4) * 4)
    if rem != 0 then
        fclose(fp)
        return 6
    var blob is MutString = malloc(nbytes)
    if blob is null then
        fclose(fp)
        return 7
    var got is usize = fread(blob, 1, nbytes, fp)
    fclose(fp)
    if got != nbytes then
        free(blob)
        return 8
    if tensor_from_owned_blob_f32(out, blob, nbytes) != 0 then
        free(blob)
        return 9
    return 0


def tensor_from_url_raw_f32(out is mut ref Tensor, url is String) returns i32
    # Download an HTTPS URL and interpret the body as a raw float32 blob.
    # This is best-effort and intended for small test/model assets.
    #
    # Supported:
    # - https://<host>/<path>
    if url is null then
        return 1
    if cstr_starts_with(url, "https://") == 0 then
        return 1

    var ub is slice of u8 = url
    var host_start is usize = 8
    var i is usize = host_start
    while ub[i] != 0 and ub[i] != 47 do
        i = i + 1
    var host_end is usize = i
    if host_end == host_start then
        return 1

    var host is MutString = cstr_dup_range(url, host_start, host_end)
    if host is null then
        return 1

    var path is String = "/"
    if ub[host_end] == 47 then
        path = url + host_end

    var s is HttpStream
    if http_init_get(&s, host, path, 0, null) != 0 then
        free(host)
        return 1
    if s.status != 200 then
        http_close(&s)
        free(host)
        return 1

    var cap is usize = 65536
    var blob is MutString = malloc(cap)
    if blob is null then
        http_close(&s)
        free(host)
        return 1
    var bb is slice of u8 = blob
    var len is usize = 0
    while 1 do
        var bi is i32 = http_body_next(&s)
        if bi < 0 then
            break
        if len == cap then
            var new_cap is usize = cap * 2
            if new_cap < cap then
                free(blob)
                http_close(&s)
                free(host)
                return 1
            var nb is MutString = realloc(blob, new_cap)
            if nb is null then
                free(blob)
                http_close(&s)
                free(host)
                return 1
            blob = nb
            bb = blob
            cap = new_cap
        var b is u8 = bi
        bb[len] = b
        len = len + 1

    http_close(&s)
    free(host)

    var rem2 is usize = len - ((len / 4) * 4)
    if len == 0 or rem2 != 0 then
        free(blob)
        return 1

    var shr is MutString = realloc(blob, len)
    if shr is not null then
        blob = shr

    if tensor_from_owned_blob_f32(out, blob, len) != 0 then
        free(blob)
        return 1
    return 0
