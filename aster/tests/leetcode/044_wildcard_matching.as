# LeetCode 44: Wildcard Matching (?, *)
use core.libc

def is_match(s is String, p is String) returns i32
    var m is usize = strlen(s)
    var n is usize = strlen(p)
    var cols is usize = n + 1
    var bytes is usize = (m + 1) * cols
    var dp is slice of u8 = malloc(bytes)
    if dp is null then
        return 0

    var i is usize = 0
    while i < bytes do
        dp[i] = 0
        i = i + 1

    dp[0] = 1

    var j is usize = 1
    while j <= n do
        if p[j - 1] == 42 and dp[j - 1] != 0 then # '*'
            dp[j] = 1
        j = j + 1

    i = 1
    while i <= m do
        j = 1
        while j <= n do
            var pj is u8 = p[j - 1]
            var v is u8 = 0
            if pj == 42 then
                # '*' matches empty (dp[i][j-1]) or one more (dp[i-1][j])
                var a is u8 = dp[i * cols + (j - 1)]
                var b is u8 = dp[(i - 1) * cols + j]
                if a != 0 or b != 0 then
                    v = 1
            else
                var si is u8 = s[i - 1]
                if pj == 63 or pj == si then # '?'
                    v = dp[(i - 1) * cols + (j - 1)]
            dp[i * cols + j] = v
            j = j + 1
        i = i + 1

    var ok is u8 = dp[m * cols + n]
    free(dp)
    if ok != 0 then
        return 1
    return 0

def main() returns i32
    if is_match("aa", "a") != 0 then
        return 1
    if is_match("aa", "*") == 0 then
        return 1
    if is_match("cb", "?a") != 0 then
        return 1
    if is_match("adceb", "*a*b") == 0 then
        return 1
    if is_match("acdcb", "a*c?b") != 0 then
        return 1
    return 0
