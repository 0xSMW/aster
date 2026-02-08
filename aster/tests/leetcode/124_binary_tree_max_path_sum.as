# LeetCode 124: Binary Tree Maximum Path Sum
#
# Implemented with integer-indexed nodes to avoid recursive pointer types.

use core.libc

def max2(a is i32, b is i32) returns i32
    if a > b then
        return a
    return b

def dfs(i is i32, vals is slice of i32, left is slice of i32, right is slice of i32, best is mut ref i32) returns i32
    if i < 0 then
        return 0
    var lg is i32 = dfs(left[i], vals, left, right, best)
    var rg is i32 = dfs(right[i], vals, left, right, best)
    if lg < 0 then
        lg = 0
    if rg < 0 then
        rg = 0
    var through is i32 = vals[i] + lg + rg
    if through > *best then
        *best = through
    return vals[i] + max2(lg, rg)

def main() returns i32
    # tree: [-10,9,20,null,null,15,7] => 42
    # indices: 0=-10, 1=9, 2=20, 3=15, 4=7
    var vals is slice of i32 = malloc(5 * 4)
    var left is slice of i32 = malloc(5 * 4)
    var right is slice of i32 = malloc(5 * 4)
    if vals is null or left is null or right is null then
        return 1
    vals[0] = -10
    vals[1] = 9
    vals[2] = 20
    vals[3] = 15
    vals[4] = 7

    left[0] = 1
    right[0] = 2
    left[1] = -1
    right[1] = -1
    left[2] = 3
    right[2] = 4
    left[3] = -1
    right[3] = -1
    left[4] = -1
    right[4] = -1

    var best is i32 = -2147483647
    dfs(0, vals, left, right, &best)
    if best != 42 then
        return 1
    free(vals)
    free(left)
    free(right)
    return 0

