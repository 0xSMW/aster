# Conformance: char literal escapes.

def main() returns i32
    var nl is u8 = '\n'
    var sq is u8 = '\''
    if nl != 10 then
        return 1
    if sq != 39 then
        return 1
    return 0

