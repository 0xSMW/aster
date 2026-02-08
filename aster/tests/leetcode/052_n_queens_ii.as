# LeetCode 52: N-Queens II

def solve(n is i32, row is i32, cols is u32, d1 is u32, d2 is u32) returns i32
    if row == n then
        return 1
    var count is i32 = 0
    var all is u32 = (1 << n) - 1
    var used is u32 = cols | d1 | d2
    # Aster1 intentionally avoids bitwise-not `~`.
    var avail is u32 = all & (all ^ used)
    while avail != 0 do
        var bit is u32 = avail & (0 - avail)
        avail = avail ^ bit
        count = count + solve(n, row + 1, cols | bit, (d1 | bit) << 1, (d2 | bit) >> 1)
    return count

def total_n_queens(n is i32) returns i32
    return solve(n, 0, 0, 0, 0)

def main() returns i32
    if total_n_queens(4) != 2 then
        return 1
    if total_n_queens(1) != 1 then
        return 1
    if total_n_queens(5) != 10 then
        return 1
    return 0
