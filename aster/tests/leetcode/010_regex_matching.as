# LeetCode 10: Regular Expression Matching (., *)
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

    var j is usize = 2
    while j <= n do
        if p[j - 1] == 42 then # '*'
            if dp[j - 2] != 0 then
                dp[j] = 1
        j = j + 1

    i = 1
    while i <= m do
        j = 1
        while j <= n do
            var pj is u8 = p[j - 1]
            var si is u8 = s[i - 1]
            var v is u8 = 0
            if pj == 46 or pj == si then # '.' or match
                v = dp[(i - 1) * cols + (j - 1)]
            else if pj == 42 then # '*'
                # zero occurrence
                v = dp[i * cols + (j - 2)]
                if v == 0 then
                    var prev is u8 = p[j - 2]
                    if prev == 46 or prev == si then
                        v = dp[(i - 1) * cols + j]
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
    if is_match("aa", "a*") == 0 then
        return 1
    if is_match("ab", ".*") == 0 then
        return 1
    if is_match("aab", "c*a*b") == 0 then
        return 1
    if is_match("mississippi", "mis*is*p*.") != 0 then
        return 1
    return 0

