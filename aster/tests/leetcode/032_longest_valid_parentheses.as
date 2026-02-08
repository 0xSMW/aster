# LeetCode 32: Longest Valid Parentheses
use core.libc

def longest_valid(s is String) returns i32
    var n is usize = strlen(s)
    var stack is slice of i32 = malloc((n + 1) * 4)
    if stack is null then
        return 0
    var top is i32 = 0
    stack[0] = -1
    var best is i32 = 0
    var i is i32 = 0
    while i < n do
        if s[i] == 40 then # '('
            top = top + 1
            stack[top] = i
        else
            top = top - 1
            if top < 0 then
                top = 0
                stack[0] = i
            else
                var len is i32 = i - stack[top]
                if len > best then
                    best = len
        i = i + 1
    free(stack)
    return best

def main() returns i32
    if longest_valid("(()") != 2 then
        return 1
    if longest_valid(")()())") != 4 then
        return 1
    if longest_valid("") != 0 then
        return 1
    if longest_valid("()(())") != 6 then
        return 1
    return 0
