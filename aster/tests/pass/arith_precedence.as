# Conformance: parser precedence + integer arithmetic codegen.

def main() returns i32
    var x is i64 = 1 + 2 * 3
    if x != 7 then
        return 1

    var y is i64 = (1 + 2) * 3
    if y != 9 then
        return 1

    var z is i64 = 20 / 5 + 1
    if z != 5 then
        return 1

    return 0

