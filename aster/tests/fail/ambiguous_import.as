# Name resolution: two direct imports exporting the same symbol should error.

use testmods.m1
use testmods.m2

def main() returns i32
    return foo()

