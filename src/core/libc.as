# core.libc: centralized libc/OS externs for Aster code.

# IO
extern def printf(fmt is String) returns i32
extern def write(fd is i32, buf is String, n is usize) returns isize
extern def strlen(s is String) returns usize
extern def exit(code is i32) returns ()

# Memory
extern def malloc(n is usize) returns MutString
extern def free(ptr is MutString) returns ()

# Env
extern def getenv(name is String) returns String
extern def atoi(s is String) returns i32

# Time
extern def clock_gettime(clk_id is i32, ts is mut ref TimeSpec) returns i32

# Stack traces (macOS / execinfo)
extern def backtrace(buf is slice of ptr of u8, size is i32) returns i32
extern def backtrace_symbols_fd(buf is slice of ptr of u8, size is i32, fd is i32) returns ()
