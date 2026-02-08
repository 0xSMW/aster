# LeetCode 312: Burst Balloons
use core.libc

def max2(a is i32, b is i32) returns i32
    if a > b then
        return a
    return b

def burst(nums is slice of i32, n is i32) returns i32
    # build arr with 1 at ends
    var a is slice of i32 = malloc((n + 2) * 4)
    if a is null then
        return 0
    a[0] = 1
    var i is i32 = 0
    while i < n do
        a[i + 1] = nums[i]
        i = i + 1
    a[n + 1] = 1

    var m is i32 = n + 2
    var dp is slice of i32 = malloc(m * m * 4)
    if dp is null then
        free(a)
        return 0
    i = 0
    while i < m * m do
        dp[i] = 0
        i = i + 1

    var len is i32 = 2
    while len < m do
        var l is i32 = 0
        while l + len < m do
            var r is i32 = l + len
            var best is i32 = 0
            var k is i32 = l + 1
            while k < r do
                var score is i32 = dp[l * m + k] + dp[k * m + r] + a[l] * a[k] * a[r]
                if score > best then
                    best = score
                k = k + 1
            dp[l * m + r] = best
            l = l + 1
        len = len + 1

    var ans is i32 = dp[0 * m + (m - 1)]
    free(dp)
    free(a)
    return ans

def main() returns i32
    var a is slice of i32 = malloc(4 * 4)
    if a is null then
        return 1
    a[0] = 3
    a[1] = 1
    a[2] = 5
    a[3] = 8
    if burst(a, 4) != 167 then
        return 1
    free(a)
    return 0
