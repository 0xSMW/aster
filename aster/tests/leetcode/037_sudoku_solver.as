# LeetCode 37: Sudoku Solver
use core.libc

def box_id(r is i32, c is i32) returns i32
    return (r / 3) * 3 + (c / 3)

def solve(grid is slice of u8, rows is slice of u16, cols is slice of u16, boxes is slice of u16, idx is i32) returns i32
    if idx == 81 then
        return 1
    var r is i32 = idx / 9
    var c is i32 = idx - r * 9
    var ch is u8 = grid[idx]
    if ch != 46 then
        return solve(grid, rows, cols, boxes, idx + 1)

    var b is i32 = box_id(r, c)
    var used is u16 = rows[r] | cols[c] | boxes[b]
    var d is i32 = 1
    while d <= 9 do
        var bit is u16 = 1 << d
        if (used & bit) == 0 then
            grid[idx] = 48 + d
            rows[r] = rows[r] | bit
            cols[c] = cols[c] | bit
            boxes[b] = boxes[b] | bit
            if solve(grid, rows, cols, boxes, idx + 1) != 0 then
                return 1
            # Clear the bit (Aster1 intentionally avoids bitwise-not `~`).
            rows[r] = rows[r] ^ bit
            cols[c] = cols[c] ^ bit
            boxes[b] = boxes[b] ^ bit
            grid[idx] = 46
        d = d + 1
    return 0

def main() returns i32
    # classic example puzzle (LeetCode)
    var s is String = "53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79"
    var grid is slice of u8 = malloc(81)
    var i is i32 = 0
    while i < 81 do
        grid[i] = s[i]
        i = i + 1

    var rows is slice of u16 = malloc(9 * 2)
    var cols is slice of u16 = malloc(9 * 2)
    var boxes is slice of u16 = malloc(9 * 2)
    if grid is null or rows is null or cols is null or boxes is null then
        return 1

    i = 0
    while i < 9 do
        rows[i] = 0
        cols[i] = 0
        boxes[i] = 0
        i = i + 1

    i = 0
    while i < 81 do
        var ch is u8 = grid[i]
        if ch != 46 then
            var r is i32 = i / 9
            var c is i32 = i - r * 9
            var b is i32 = box_id(r, c)
            var d is i32 = ch - 48
            var bit is u16 = 1 << d
            rows[r] = rows[r] | bit
            cols[c] = cols[c] | bit
            boxes[b] = boxes[b] | bit
        i = i + 1

    if solve(grid, rows, cols, boxes, 0) == 0 then
        return 1

    # check a few cells of known solution
    if grid[0] != 53 then
        return 1  # '5'
    if grid[1] != 51 then
        return 1  # '3'
    if grid[4] != 55 then
        return 1  # '7'
    if grid[80] != 57 then
        return 1 # '9'

    free(grid)
    free(rows)
    free(cols)
    free(boxes)
    return 0
