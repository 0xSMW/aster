# Compiler IR conformance: AST/HIR dumps should be deterministic.

use core.io

const ANSWER is i32 = 42

struct Pair
    var a is i32
    var b is i32

def add(x is i32, y is i32) returns i32
    return x + y

def main() returns i32
    var p is Pair
    p.a = ANSWER
    p.b = 1
    println("ok")
    return add(p.a, p.b) - 43

