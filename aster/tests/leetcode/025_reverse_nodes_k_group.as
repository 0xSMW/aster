# LeetCode 25: Reverse Nodes in k-Group
#
# Implemented over an array to avoid self-referential pointer fields.

use core.libc

def reverse_k(a is slice of i32, n is i32, k is i32)
    var i is i32 = 0
    while i + k <= n do
        var l is i32 = i
        var r is i32 = i + k - 1
        while l < r do
            var t is i32 = a[l]
            a[l] = a[r]
            a[r] = t
            l = l + 1
            r = r - 1
        i = i + k

def main() returns i32
    var a is slice of i32 = malloc(5 * 4)
    if a is null then
        return 1
    a[0] = 1
    a[1] = 2
    a[2] = 3
    a[3] = 4
    a[4] = 5
    reverse_k(a, 5, 2)
    if a[0] != 2 then
        return 1
    if a[1] != 1 then
        return 1
    if a[2] != 4 then
        return 1
    if a[3] != 3 then
        return 1
    if a[4] != 5 then
        return 1
    free(a)
    return 0

