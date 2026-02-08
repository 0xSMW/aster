# core.http: tiny HTTP/1.1 client + SSE parser (macOS-first; TLS-only).
#
# Intended for remote API clients (OpenAI-style streaming). Networking is kept
# minimal and avoids shelling out.

use core.libc
use core.net

const HTTP_TLS_PORT is u16 = 443
const HTTP_TIMEOUT_MS is i32 = 15000

struct HttpStream
    var tls is ptr of void
    var buf is MutString
    var cap is usize
    var len is usize
    var pos is usize
    var chunked is i32
    var chunk_rem is usize
    var content_rem is isize
    var eof is i32
    var status is i32
    var line is MutString
    var line_cap is usize


def http_is_hex(c is u8) returns i32
    if c >= 48 and c <= 57 then
        return 1
    if c >= 65 and c <= 70 then
        return 1
    if c >= 97 and c <= 102 then
        return 1
    return 0


def http_hex_val(c is u8) returns i32
    if c >= 48 and c <= 57 then
        return c - 48
    if c >= 65 and c <= 70 then
        return c - 65 + 10
    if c >= 97 and c <= 102 then
        return c - 97 + 10
    return -1


def http_is_digit(c is u8) returns i32
    return (c >= 48 and c <= 57)


def http_write_str(tls is ptr of void, s is String) returns i32
    return tls_write_all(tls, s, strlen(s))


def http_write_u64_dec(tls is ptr of void, x is u64) returns i32
    # decimal in a tiny stackless buffer
    var tmp is MutString = malloc(32)
    if tmp is null then
        return 1
    var i is usize = 0
    var v is u64 = x
    if v == 0 then
        tmp[i] = 48
        i = i + 1
    else
        while v != 0 do
            var q is u64 = v / 10
            var d is u64 = v - (q * 10)
            tmp[i] = 48 + d
            i = i + 1
            v = q
    # reverse in place
    var a is usize = 0
    var b is usize = i
    while a < b do
        b = b - 1
        var t is u8 = tmp[a]
        tmp[a] = tmp[b]
        tmp[b] = t
        a = a + 1
    var rc is i32 = tls_write_all(tls, tmp, i)
    free(tmp)
    return rc


def http_buf_compact(s is mut ref HttpStream) returns ()
    if (*s).pos == 0 then
        return
    if (*s).pos >= (*s).len then
        (*s).pos = 0
        (*s).len = 0
        return
    var i is usize = 0
    var j is usize = (*s).pos
    while j < (*s).len do
        (*s).buf[i] = (*s).buf[j]
        i = i + 1
        j = j + 1
    (*s).len = i
    (*s).pos = 0
    return


def http_fill(s is mut ref HttpStream) returns i32
    if (*s).eof != 0 then
        return 0
    if (*s).len == (*s).cap then
        http_buf_compact(s)
        if (*s).len == (*s).cap then
            return 1
    var n is isize = tls_read((*s).tls, (*s).buf + (*s).len, (*s).cap - (*s).len)
    if n == -2 then
        return 0
    if n <= 0 then
        (*s).eof = 1
        return 0
    var un is usize = n
    (*s).len = (*s).len + un
    return 0


def http_raw_next(s is mut ref HttpStream) returns i32
    while (*s).pos >= (*s).len do
        (*s).pos = 0
        (*s).len = 0
        if http_fill(s) != 0 then
            return -1
        if (*s).eof != 0 and (*s).len == 0 then
            return -1
    var b is u8 = (*s).buf[(*s).pos]
    (*s).pos = (*s).pos + 1
    return b


def http_eq_ci(a is u8, b is u8) returns i32
    var x is u8 = a
    if x >= 65 and x <= 90 then
        x = x + 32
    var y is u8 = b
    if y >= 65 and y <= 90 then
        y = y + 32
    return (x == y)


def http_starts_with_ci(s is String, n is usize, prefix is String, pn is usize) returns i32
    if n < pn then
        return 0
    var i is usize = 0
    while i < pn do
        if http_eq_ci(s[i], prefix[i]) == 0 then
            return 0
        i = i + 1
    return 1


def http_contains_chunked(value is String, n is usize) returns i32
    # Case-insensitive substring "chunked".
    var pat is String = "chunked"
    var pn is usize = 7
    if n < pn then
        return 0
    var i is usize = 0
    while i + pn <= n do
        var ok is i32 = 1
        var j is usize = 0
        while j < pn do
            if http_eq_ci(value[i + j], pat[j]) == 0 then
                ok = 0
                break
            j = j + 1
        if ok != 0 then
            return 1
        i = i + 1
    return 0


def http_parse_u64_dec(s is String, n is usize) returns u64
    var i is usize = 0
    while i < n and http_is_digit(s[i]) == 0 do
        i = i + 1
    var v is u64 = 0
    while i < n and http_is_digit(s[i]) != 0 do
        v = v * 10 + (s[i] - 48)
        i = i + 1
    return v


def http_parse_status_line(line is String, n is usize) returns i32
    # "HTTP/1.1 200 OK"
    var i is usize = 0
    while i < n and line[i] != 32 do
        i = i + 1
    while i < n and line[i] == 32 do
        i = i + 1
    if i + 3 > n then
        return 0
    var a is u8 = line[i]
    var b is u8 = line[i + 1]
    var c is u8 = line[i + 2]
    if http_is_digit(a) == 0 or http_is_digit(b) == 0 or http_is_digit(c) == 0 then
        return 0
    return (a - 48) * 100 + (b - 48) * 10 + (c - 48)


def http_send_get(tls is ptr of void, host is String, path is String, accept_sse is i32, extra_headers is String) returns i32
    if http_write_str(tls, "GET ") != 0 then
        return 1
    if tls_write_all(tls, path, strlen(path)) != 0 then
        return 1
    if http_write_str(tls, " HTTP/1.1\r\nHost: ") != 0 then
        return 1
    if tls_write_all(tls, host, strlen(host)) != 0 then
        return 1
    if http_write_str(tls, "\r\nUser-Agent: aster/0\r\n") != 0 then
        return 1
    if accept_sse != 0 then
        if http_write_str(tls, "Accept: text/event-stream\r\n") != 0 then
            return 1
        if http_write_str(tls, "Cache-Control: no-cache\r\n") != 0 then
            return 1
    else
        if http_write_str(tls, "Accept: */*\r\n") != 0 then
            return 1
    if http_write_str(tls, "Connection: close\r\n") != 0 then
        return 1
    if extra_headers != null then
        # Caller must include trailing CRLF(s) if needed.
        if tls_write_all(tls, extra_headers, strlen(extra_headers)) != 0 then
            return 1
    if http_write_str(tls, "\r\n") != 0 then
        return 1
    return 0


def http_send_post(tls is ptr of void, host is String, path is String, accept_sse is i32, extra_headers is String, body is String) returns i32
    var body_len is usize = 0
    if body != null then
        body_len = strlen(body)

    if http_write_str(tls, "POST ") != 0 then
        return 1
    if tls_write_all(tls, path, strlen(path)) != 0 then
        return 1
    if http_write_str(tls, " HTTP/1.1\r\nHost: ") != 0 then
        return 1
    if tls_write_all(tls, host, strlen(host)) != 0 then
        return 1
    if http_write_str(tls, "\r\nUser-Agent: aster/0\r\n") != 0 then
        return 1
    if accept_sse != 0 then
        if http_write_str(tls, "Accept: text/event-stream\r\n") != 0 then
            return 1
        if http_write_str(tls, "Cache-Control: no-cache\r\n") != 0 then
            return 1
    else
        if http_write_str(tls, "Accept: */*\r\n") != 0 then
            return 1
    if http_write_str(tls, "Connection: close\r\n") != 0 then
        return 1
    if http_write_str(tls, "Content-Length: ") != 0 then
        return 1
    if http_write_u64_dec(tls, body_len) != 0 then
        return 1
    if http_write_str(tls, "\r\n") != 0 then
        return 1
    if extra_headers != null then
        if tls_write_all(tls, extra_headers, strlen(extra_headers)) != 0 then
            return 1
    if http_write_str(tls, "\r\n") != 0 then
        return 1
    if body_len != 0 then
        if tls_write_all(tls, body, body_len) != 0 then
            return 1
    return 0


def http_parse_headers(s is mut ref HttpStream) returns i32
    # Fill until we see \r\n\r\n (or \n\n).
    while 1 do
        # Scan current buffer.
        var i is usize = (*s).pos
        while i + 3 < (*s).len do
            if (*s).buf[i] == 13 and (*s).buf[i + 1] == 10 and (*s).buf[i + 2] == 13 and (*s).buf[i + 3] == 10 then
                # header end at i+4
                var hdr_end is usize = i + 4
                # Parse line-by-line from start of headers to hdr_end.
                var p is usize = 0
                var line_no is i32 = 0
                while p < hdr_end do
                    # find end of line
                    var q is usize = p
                    while q < hdr_end and (*s).buf[q] != 10 do
                        q = q + 1
                    var line_len is usize = 0
                    if q > p and (*s).buf[q - 1] == 13 then
                        line_len = (q - 1) - p
                    else
                        line_len = q - p

                    if line_no == 0 then
                        (*s).status = http_parse_status_line((*s).buf + p, line_len)
                    else
                        # "Name: value"
                        var k is usize = 0
                        while k < line_len and (*s).buf[p + k] != 58 do
                            k = k + 1
                        if k < line_len then
                            var name is String = (*s).buf + p
                            var name_len is usize = k
                            var val is String = (*s).buf + p + k + 1
                            var val_len is usize = line_len - (k + 1)
                            # trim leading spaces
                            while val_len > 0 and (val[0] == 32 or val[0] == 9) do
                                val = val + 1
                                val_len = val_len - 1

                            if http_starts_with_ci(name, name_len, "Transfer-Encoding", 17) != 0 then
                                if http_contains_chunked(val, val_len) != 0 then
                                    (*s).chunked = 1
                            if http_starts_with_ci(name, name_len, "Content-Length", 14) != 0 then
                                var n64 is u64 = http_parse_u64_dec(val, val_len)
                                (*s).content_rem = n64
                    line_no = line_no + 1
                    if q >= hdr_end then
                        break
                    p = q + 1

                # Advance pos to body start.
                (*s).pos = hdr_end
                return 0
            i = i + 1
        # Need more bytes.
        if http_fill(s) != 0 then
            return 1
        if (*s).eof != 0 then
            return 1


def http_init_get(s is mut ref HttpStream, host is String, path is String, accept_sse is i32, extra_headers is String) returns i32
    (*s).tls = null
    (*s).buf = null
    (*s).cap = 0
    (*s).len = 0
    (*s).pos = 0
    (*s).chunked = 0
    (*s).chunk_rem = 0
    (*s).content_rem = -1
    (*s).eof = 0
    (*s).status = 0
    (*s).line = null
    (*s).line_cap = 0

    var tls is ptr of void = tls_connect(host, HTTP_TLS_PORT, HTTP_TIMEOUT_MS)
    if tls is null then
        return 1
    (*s).tls = tls

    if http_send_get(tls, host, path, accept_sse, extra_headers) != 0 then
        http_close(s)
        return 1

    var cap is usize = 65536
    var buf is MutString = malloc(cap)
    var line is MutString = malloc(8192)
    if buf is null or line is null then
        if buf != null then
            free(buf)
        if line != null then
            free(line)
        http_close(s)
        return 1
    (*s).buf = buf
    (*s).cap = cap
    (*s).line = line
    (*s).line_cap = 8192

    if http_fill(s) != 0 then
        http_close(s)
        return 1
    if http_parse_headers(s) != 0 then
        http_close(s)
        return 1
    return 0


def http_init_post(s is mut ref HttpStream, host is String, path is String, accept_sse is i32, extra_headers is String, body is String) returns i32
    (*s).tls = null
    (*s).buf = null
    (*s).cap = 0
    (*s).len = 0
    (*s).pos = 0
    (*s).chunked = 0
    (*s).chunk_rem = 0
    (*s).content_rem = -1
    (*s).eof = 0
    (*s).status = 0
    (*s).line = null
    (*s).line_cap = 0

    var tls is ptr of void = tls_connect(host, HTTP_TLS_PORT, HTTP_TIMEOUT_MS)
    if tls is null then
        return 1
    (*s).tls = tls

    if http_send_post(tls, host, path, accept_sse, extra_headers, body) != 0 then
        http_close(s)
        return 1

    var cap is usize = 65536
    var buf is MutString = malloc(cap)
    var line is MutString = malloc(8192)
    if buf is null or line is null then
        if buf != null then
            free(buf)
        if line != null then
            free(line)
        http_close(s)
        return 1
    (*s).buf = buf
    (*s).cap = cap
    (*s).line = line
    (*s).line_cap = 8192

    if http_fill(s) != 0 then
        http_close(s)
        return 1
    if http_parse_headers(s) != 0 then
        http_close(s)
        return 1
    return 0


def http_close(s is mut ref HttpStream) returns ()
    if (*s).tls != null then
        tls_close((*s).tls)
        (*s).tls = null
    if (*s).buf != null then
        free((*s).buf)
        (*s).buf = null
    if (*s).line != null then
        free((*s).line)
        (*s).line = null
    (*s).cap = 0
    (*s).len = 0
    (*s).pos = 0
    (*s).eof = 1
    return


def http_body_next(s is mut ref HttpStream) returns i32
    if (*s).eof != 0 then
        return -1

    # Honor content-length if present.
    if (*s).chunked == 0 and (*s).content_rem == 0 then
        (*s).eof = 1
        return -1

    if (*s).chunked != 0 then
        while (*s).chunk_rem == 0 do
            # Read next chunk size line (hex).
            var saw is i32 = 0
            var size is usize = 0
            while 1 do
                var bi is i32 = http_raw_next(s)
                if bi < 0 then
                    (*s).eof = 1
                    return -1
                var b is u8 = bi
                if b == 10 then
                    break
                if b == 13 then
                    continue
                if b == 59 then
                    # extensions: skip until newline
                    while 1 do
                        bi = http_raw_next(s)
                        if bi < 0 then
                            (*s).eof = 1
                            return -1
                        if bi == 10 then
                            break
                    break
                var hv is i32 = http_hex_val(b)
                if hv >= 0 then
                    saw = 1
                    size = size * 16 + hv
            if saw == 0 then
                continue
            if size == 0 then
                (*s).eof = 1
                return -1
            (*s).chunk_rem = size

        var out is i32 = http_raw_next(s)
        if out < 0 then
            (*s).eof = 1
            return -1
        (*s).chunk_rem = (*s).chunk_rem - 1
        if (*s).chunk_rem == 0 then
            # Consume trailing CRLF.
            var c1 is i32 = http_raw_next(s)
            if c1 == 13 then
                var drop is i32 = http_raw_next(s)
        return out

    # Not chunked: raw byte stream.
    var out2 is i32 = http_raw_next(s)
    if out2 < 0 then
        (*s).eof = 1
        return -1
    if (*s).content_rem > 0 then
        (*s).content_rem = (*s).content_rem - 1
    return out2


def http_read_all(s is mut ref HttpStream, out is MutString, cap is usize) returns isize
    var w is usize = 0
    while w + 1 < cap do
        var bi is i32 = http_body_next(s)
        if bi < 0 then
            break
        out[w] = bi
        w = w + 1
    out[w] = 0
    return w


def https_get(host is String, path is String, out is MutString, cap is usize) returns isize
    var s is HttpStream
    if http_init_get(&s, host, path, 0, null) != 0 then
        return -1
    var n is isize = http_read_all(&s, out, cap)
    http_close(&s)
    return n


def http_read_line_body(s is mut ref HttpStream, out is MutString, cap is usize) returns isize
    var w is usize = 0
    while 1 do
        var bi is i32 = http_body_next(s)
        if bi < 0 then
            if w == 0 then
                return -1
            break
        var b is u8 = bi
        if b == 10 then
            break
        if b == 13 then
            continue
        if w + 1 < cap then
            out[w] = b
            w = w + 1
    out[w] = 0
    return w


def sse_next_event(s is mut ref HttpStream, out is MutString, cap is usize) returns isize
    # Returns next SSE `data:` payload (joined with '\n' for multi-line data).
    var w is usize = 0
    var started is i32 = 0
    while 1 do
        var n is isize = http_read_line_body(s, (*s).line, (*s).line_cap)
        if n < 0 then
            return -1
        if n == 0 then
            if started != 0 then
                if w < cap then
                    out[w] = 0
                return w
            continue
        started = 1
        # Prefix match "data:"
        if n >= 5 and (*s).line[0] == 100 and (*s).line[1] == 97 and (*s).line[2] == 116 and (*s).line[3] == 97 and (*s).line[4] == 58 then
            var i is usize = 5
            if (*s).line[i] == 32 then
                i = i + 1
            if w != 0 and w + 1 < cap then
                out[w] = 10
                w = w + 1
            while i < n and w + 1 < cap do
                out[w] = (*s).line[i]
                w = w + 1
                i = i + 1
    return -1
