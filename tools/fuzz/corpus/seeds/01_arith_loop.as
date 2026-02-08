# Seed: arithmetic + while + comparisons.

def main() returns i32
    var i is i32 = 0
    var sum is i64 = 0
    while i < 10 do
        sum = sum + (i * 3) - 1
        i = i + 1
    if sum == 125 then
        return 0
    return 1

