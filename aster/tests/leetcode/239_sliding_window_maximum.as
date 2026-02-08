# LeetCode 239: Sliding Window Maximum
use core.libc

def max_window(a is slice of i32, n is i32, k is i32, out is slice of i32) returns i32
    var dq is slice of i32 = malloc(n * 4) # store indices
    if dq is null then
        return 0
    var head is i32 = 0
    var tail is i32 = 0
    var oi is i32 = 0
    var i is i32 = 0
    while i < n do
        # pop front out of window
        if head < tail and dq[head] <= i - k then
            head = head + 1
        # pop back smaller
        while head < tail and a[dq[tail - 1]] <= a[i] do
            tail = tail - 1
        dq[tail] = i
        tail = tail + 1
        if i >= k - 1 then
            out[oi] = a[dq[head]]
            oi = oi + 1
        i = i + 1
    free(dq)
    return oi

def main() returns i32
    var a is slice of i32 = malloc(8 * 4)
    if a is null then
        return 1
    a[0] = 1
    a[1] = 3
    a[2] = -1
    a[3] = -3
    a[4] = 5
    a[5] = 3
    a[6] = 6
    a[7] = 7
    var out is slice of i32 = malloc(6 * 4)
    if out is null then
        return 1
    var m is i32 = max_window(a, 8, 3, out)
    if m != 6 then
        return 1
    if out[0] != 3 then
        return 1
    if out[1] != 3 then
        return 1
    if out[2] != 5 then
        return 1
    if out[3] != 5 then
        return 1
    if out[4] != 6 then
        return 1
    if out[5] != 7 then
        return 1
    free(a)
    free(out)
    return 0
