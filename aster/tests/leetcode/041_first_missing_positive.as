# LeetCode 41: First Missing Positive
use core.libc

def first_missing(a is slice of i32, n is i32) returns i32
    var i is i32 = 0
    while i < n do
        while 1 == 1 do
            var v is i32 = a[i]
            if v <= 0 or v > n then
                break
            var j is i32 = v - 1
            if a[j] == v then
                break
            var t is i32 = a[j]
            a[j] = v
            a[i] = t
        i = i + 1
    i = 0
    while i < n do
        if a[i] != i + 1 then
            return i + 1
        i = i + 1
    return n + 1

def main() returns i32
    var a is slice of i32 = malloc(4 * 4)
    if a is null then
        return 1
    a[0] = 3
    a[1] = 4
    a[2] = -1
    a[3] = 1
    if first_missing(a, 4) != 2 then
        return 1
    free(a)

    var b is slice of i32 = malloc(3 * 4)
    if b is null then
        return 1
    b[0] = 1
    b[1] = 2
    b[2] = 0
    if first_missing(b, 3) != 3 then
        return 1
    free(b)
    return 0
