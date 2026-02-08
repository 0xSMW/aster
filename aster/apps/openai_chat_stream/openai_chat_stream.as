# OpenAI-style chat completions streaming demo (SSE over HTTPS).
#
# Requires:
#   export OPENAI_API_KEY="..."
#
# Run:
#   tools/aster/aster run aster/apps/openai_chat_stream/openai_chat_stream.as

use core.http
use core.libc

const HDR_CAP is usize = 2048
const EV_CAP is usize = 65536

def copy_cstr(dst is MutString, dst_cap is usize, off is mut ref usize, src is String) returns i32
    if src is null then
        return 0
    var i is usize = 0
    while src[i] != 0 do
        if *off + 1 >= dst_cap then
            return 1
        dst[*off] = src[i]
        *off = *off + 1
        i = i + 1
    return 0


def build_headers(key is String) returns MutString
    var hdr is MutString = malloc(HDR_CAP)
    if hdr is null then
        return null
    var off is usize = 0
    if copy_cstr(hdr, HDR_CAP, &off, "Authorization: Bearer ") != 0 then
        free(hdr)
        return null
    if copy_cstr(hdr, HDR_CAP, &off, key) != 0 then
        free(hdr)
        return null
    if copy_cstr(hdr, HDR_CAP, &off, "\r\nContent-Type: application/json\r\n") != 0 then
        free(hdr)
        return null
    hdr[off] = 0
    return hdr


def str_eq(a is String, b is String) returns i32
    if a is null or b is null then
        return 0
    var i is usize = 0
    while 1 do
        var x is u8 = a[i]
        var y is u8 = b[i]
        if x != y then
            return 0
        if x == 0 then
            return 1
        i = i + 1


def main() returns i32
    var key is String = getenv("OPENAI_API_KEY")
    if key is null then
        printf("missing OPENAI_API_KEY\n")
        return 1

    var headers is MutString = build_headers(key)
    if headers is null then
        printf("failed to build headers\n")
        return 1

    # Minimal request body. Replace model/inputs as needed.
    var body is String = "{\"model\":\"gpt-4o-mini\",\"messages\":[{\"role\":\"user\",\"content\":\"hello\"}],\"stream\":true}"

    var s is HttpStream
    if http_init_post(&s, "api.openai.com", "/v1/chat/completions", 1, headers, body) != 0 then
        printf("request failed\n")
        free(headers)
        return 1

    var ev is MutString = malloc(EV_CAP)
    if ev is null then
        printf("OOM\n")
        http_close(&s)
        free(headers)
        return 1

    while 1 do
        var n is isize = sse_next_event(&s, ev, EV_CAP)
        if n < 0 then
            break
        if str_eq(ev, "[DONE]") != 0 then
            break
        printf("%s\n", ev)

    http_close(&s)
    free(ev)
    free(headers)
    return 0
