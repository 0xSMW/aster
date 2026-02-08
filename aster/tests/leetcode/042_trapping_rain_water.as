# LeetCode 42: Trapping Rain Water
use core.libc

def trap(a is slice of i32, n is i32) returns i32
    var l is i32 = 0
    var r is i32 = n - 1
    var lm is i32 = 0
    var rm is i32 = 0
    var ans is i32 = 0
    while l < r do
        if a[l] < a[r] then
            if a[l] >= lm then
                lm = a[l]
            else
                ans = ans + (lm - a[l])
            l = l + 1
        else
            if a[r] >= rm then
                rm = a[r]
            else
                ans = ans + (rm - a[r])
            r = r - 1
    return ans

def main() returns i32
    var a is slice of i32 = malloc(12 * 4)
    if a is null then
        return 1
    a[0] = 0
    a[1] = 1
    a[2] = 0
    a[3] = 2
    a[4] = 1
    a[5] = 0
    a[6] = 1
    a[7] = 3
    a[8] = 2
    a[9] = 1
    a[10] = 2
    a[11] = 1
    if trap(a, 12) != 6 then
        return 1
    free(a)
    return 0
