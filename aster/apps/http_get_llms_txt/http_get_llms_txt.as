# Fetch the OpenAI docs `llms.txt` over HTTPS and print it to stdout.
#
# Run:
#   tools/aster/aster run aster/apps/http_get_llms_txt/http_get_llms_txt.as

use core.http
use core.libc

const CAP is usize = 1048576

def main() returns i32
    var buf is MutString = malloc(CAP)
    if buf is null then
        printf("OOM\n")
        return 1

    var n is isize = https_get("platform.openai.com", "/docs/llms.txt", buf, CAP)
    if n < 0 then
        printf("request failed\n")
        free(buf)
        return 1

    printf("%s", buf)
    free(buf)
    return 0

