# LeetCode 72: Edit Distance
use core.libc

def min3(a is i32, b is i32, c is i32) returns i32
    var m is i32 = a
    if b < m then
        m = b
    if c < m then
        m = c
    return m

def edit(a is String, b is String) returns i32
    var m is i32 = strlen(a)
    var n is i32 = strlen(b)
    var cols is i32 = n + 1
    var dp is slice of i32 = malloc((m + 1) * (n + 1) * 4)
    if dp is null then
        return 0
    var i is i32 = 0
    while i <= m do
        dp[i * cols + 0] = i
        i = i + 1
    var j is i32 = 0
    while j <= n do
        dp[0 * cols + j] = j
        j = j + 1

    i = 1
    while i <= m do
        j = 1
        while j <= n do
            var cost is i32 = 0
            if a[i - 1] != b[j - 1] then
                cost = 1
            var del is i32 = dp[(i - 1) * cols + j] + 1
            var ins is i32 = dp[i * cols + (j - 1)] + 1
            var sub is i32 = dp[(i - 1) * cols + (j - 1)] + cost
            dp[i * cols + j] = min3(del, ins, sub)
            j = j + 1
        i = i + 1
    var ans is i32 = dp[m * cols + n]
    free(dp)
    return ans

def main() returns i32
    if edit("horse", "ros") != 3 then
        return 1
    if edit("intention", "execution") != 5 then
        return 1
    return 0
