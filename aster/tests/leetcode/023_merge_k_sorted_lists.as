# LeetCode 23: Merge k Sorted Lists
#
# Aster doesn't currently support self-referential struct fields like
# `ptr of ListNode`, so this test implements the same merge-k logic over
# k sorted arrays (equivalent to iterating k list heads).

use core.libc

def heap_swap(v is slice of i32, lid is slice of i32, pos is slice of i32, i is i32, j is i32)
    var tv is i32 = v[i]
    var tl is i32 = lid[i]
    var tp is i32 = pos[i]
    v[i] = v[j]
    lid[i] = lid[j]
    pos[i] = pos[j]
    v[j] = tv
    lid[j] = tl
    pos[j] = tp

def heap_up(v is slice of i32, lid is slice of i32, pos is slice of i32, idx is i32)
    var i is i32 = idx
    while i > 0 do
        var p is i32 = (i - 1) / 2
        if v[p] <= v[i] then
            return
        heap_swap(v, lid, pos, p, i)
        i = p

def heap_down(v is slice of i32, lid is slice of i32, pos is slice of i32, n is i32, idx is i32)
    var i is i32 = idx
    while 1 == 1 do
        var l is i32 = i * 2 + 1
        if l >= n then
            return
        var r is i32 = l + 1
        var m is i32 = l
        if r < n and v[r] < v[l] then
            m = r
        if v[i] <= v[m] then
            return
        heap_swap(v, lid, pos, i, m)
        i = m

def main() returns i32
    # lists: [1,4,5], [1,3,4], [2,6,7]
    var a0 is slice of i32 = malloc(3 * 4)
    var a1 is slice of i32 = malloc(3 * 4)
    var a2 is slice of i32 = malloc(3 * 4)
    if a0 is null or a1 is null or a2 is null then
        return 1
    a0[0] = 1
    a0[1] = 4
    a0[2] = 5
    a1[0] = 1
    a1[1] = 3
    a1[2] = 4
    a2[0] = 2
    a2[1] = 6
    a2[2] = 7

    var hv is slice of i32 = malloc(3 * 4)
    var hl is slice of i32 = malloc(3 * 4)
    var hp is slice of i32 = malloc(3 * 4)
    if hv is null or hl is null or hp is null then
        return 1

    var hn is i32 = 0
    var lid is i32 = 0
    while lid < 3 do
        if lid == 0 then
            hv[hn] = a0[0]
        else if lid == 1 then
            hv[hn] = a1[0]
        else
            hv[hn] = a2[0]
        hl[hn] = lid
        hp[hn] = 0
        heap_up(hv, hl, hp, hn)
        hn = hn + 1
        lid = lid + 1

    var out is slice of i32 = malloc(9 * 4)
    if out is null then
        return 1

    var oi is i32 = 0
    while hn > 0 do
        var minv is i32 = hv[0]
        var minl is i32 = hl[0]
        var minp is i32 = hp[0]
        out[oi] = minv
        oi = oi + 1

        hn = hn - 1
        hv[0] = hv[hn]
        hl[0] = hl[hn]
        hp[0] = hp[hn]
        if hn > 0 then
            heap_down(hv, hl, hp, hn, 0)

        var np is i32 = minp + 1
        if np < 3 then
            if minl == 0 then
                hv[hn] = a0[np]
            else if minl == 1 then
                hv[hn] = a1[np]
            else
                hv[hn] = a2[np]
            hl[hn] = minl
            hp[hn] = np
            heap_up(hv, hl, hp, hn)
            hn = hn + 1

    if oi != 9 then
        return 1
    # expected: 1,1,2,3,4,4,5,6,7
    if out[0] != 1 then
        return 1
    if out[1] != 1 then
        return 1
    if out[2] != 2 then
        return 1
    if out[3] != 3 then
        return 1
    if out[4] != 4 then
        return 1
    if out[5] != 4 then
        return 1
    if out[6] != 5 then
        return 1
    if out[7] != 6 then
        return 1
    if out[8] != 7 then
        return 1

    free(a0)
    free(a1)
    free(a2)
    free(hv)
    free(hl)
    free(hp)
    free(out)
    return 0
