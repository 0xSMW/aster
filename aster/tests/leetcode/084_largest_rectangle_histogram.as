# LeetCode 84: Largest Rectangle in Histogram
use core.libc

def largest(a is slice of i32, n is i32) returns i32
    var st is slice of i32 = malloc((n + 1) * 4)
    if st is null then
        return 0
    var top is i32 = -1
    var best is i32 = 0
    var i is i32 = 0
    while i <= n do
        var cur is i32 = 0
        if i < n then
            cur = a[i]
        while top >= 0 and (i == n or a[st[top]] > cur) do
            var h is i32 = a[st[top]]
            top = top - 1
            var left is i32 = -1
            if top >= 0 then
                left = st[top]
            var w is i32 = i - left - 1
            var area is i32 = h * w
            if area > best then
                best = area
        top = top + 1
        st[top] = i
        i = i + 1
    free(st)
    return best

def main() returns i32
    var a is slice of i32 = malloc(6 * 4)
    if a is null then
        return 1
    a[0] = 2
    a[1] = 1
    a[2] = 5
    a[3] = 6
    a[4] = 2
    a[5] = 3
    if largest(a, 6) != 10 then
        return 1
    free(a)
    return 0
