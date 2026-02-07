# Expected: compile+run OK (local type inference from initializer)

def main() returns i32
    var x = 41
    x = x + 1
    if x != 42 then
        return 1
    return 0

