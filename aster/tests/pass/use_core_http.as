# Conformance: importing core.http should compile+link (TLS runtime is auto-linked).

use core.http
use core.io

def main() returns i32
    println("ok")
    return 0

