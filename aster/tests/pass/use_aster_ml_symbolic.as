# Expected: compile+run OK (symbolic ints)

use aster_ml.uop.symbolic
use core.libc
use core.io

def main() returns i32
    # expr = (N + 1) * 3
    var n is MutString = sym_var("N")
    var one is MutString = sym_const(1)
    var three is MutString = sym_const(3)
    if n is null or one is null or three is null then
        return 1
    var add is MutString = sym_add(n, one)
    if add is null then
        sym_free(three)
        sym_free(one)
        sym_free(n)
        return 1
    var expr is MutString = sym_mul(add, three)
    if expr is null then
        sym_free(add)
        # add owns n+one, freed above
        sym_free(three)
        return 1

    # env: N=4
    var names is slice of String = malloc(1 * 8)
    var vals is slice of i64 = malloc(1 * 8)
    if names is null or vals is null then
        if names is not null then
            free(names)
        if vals is not null then
            free(vals)
        sym_free(expr)
        return 1
    names[0] = "N"
    vals[0] = 4

    var ok is i32 = 0
    var got is i64 = sym_eval(expr, 1, names, vals, &ok)
    free(vals)
    free(names)
    sym_free(expr)

    if ok == 0 then
        return 1
    if got != 15 then
        return 1
    println("ok")
    return 0
