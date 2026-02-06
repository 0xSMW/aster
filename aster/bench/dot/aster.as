# Aster dot product benchmark (Aster0 subset)

const N is usize = 5000000
const REPS is usize = 3

def dot(a is slice of f64, b is slice of f64, n is usize) returns f64
    var sum is f64 = 0.0
    var i is usize = 0
    while i < n do
        sum = sum + a[i] * b[i]
        i = i + 1
    return sum

# entry point for bench harness

def main() returns f64
    return 0.0
