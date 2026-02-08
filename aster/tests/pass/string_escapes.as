# Conformance: string escape decoding + global string constants.

extern def strlen(s is String) returns usize

def main() returns i32
    var n is usize = strlen("a\n\t\\\"b")
    if n == 6 then
        return 0
    return 1
