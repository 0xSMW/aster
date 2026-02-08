# LeetCode 127: Word Ladder
use core.libc

def str_eq(a is String, b is String) returns i32
    var i is usize = 0
    while 1 == 1 do
        var ca is u8 = a[i]
        var cb is u8 = b[i]
        if ca != cb then
            return 0
        if ca == 0 then
            return 1
        i = i + 1
    return 0

def diff1(a is String, b is String) returns i32
    var i is usize = 0
    var d is i32 = 0
    while a[i] != 0 do
        if a[i] != b[i] then
            d = d + 1
            if d > 1 then
                return 0
        i = i + 1
    if d == 1 then
        return 1
    return 0

def ladder(begin is String, end is String, words is slice of String, n is i32) returns i32
    var seen is slice of u8 = malloc(n)
    var q is slice of i32 = malloc(n * 4)
    var dist is slice of i32 = malloc(n * 4)
    if seen is null or q is null or dist is null then
        return 0
    var i is i32 = 0
    while i < n do
        seen[i] = 0
        i = i + 1

    var head is i32 = 0
    var tail is i32 = 0
    i = 0
    while i < n do
        if str_eq(words[i], begin) != 0 then
            seen[i] = 1
            q[tail] = i
            dist[tail] = 1
            tail = tail + 1
        i = i + 1

    # also allow begin not in list: start by neighbors
    if tail == 0 then
        i = 0
        while i < n do
            if diff1(begin, words[i]) != 0 then
                seen[i] = 1
                q[tail] = i
                dist[tail] = 2
                tail = tail + 1
            i = i + 1

    while head < tail do
        var idx is i32 = q[head]
        var d is i32 = dist[head]
        head = head + 1
        if str_eq(words[idx], end) != 0 then
            free(seen)
            free(q)
            free(dist)
            return d
        i = 0
        while i < n do
            if seen[i] == 0 and diff1(words[idx], words[i]) != 0 then
                seen[i] = 1
                q[tail] = i
                dist[tail] = d + 1
                tail = tail + 1
            i = i + 1
    free(seen)
    free(q)
    free(dist)
    return 0

def main() returns i32
    # ["hot","dot","dog","lot","log","cog"]
    var words is slice of String = malloc(6 * 8)
    if words is null then
        return 1
    words[0] = "hot"
    words[1] = "dot"
    words[2] = "dog"
    words[3] = "lot"
    words[4] = "log"
    words[5] = "cog"
    if ladder("hit", "cog", words, 6) != 5 then
        return 1
    free(words)
    return 0
