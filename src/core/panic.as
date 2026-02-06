use core.libc

const PANIC_FD is i32 = 2
const BT_CAP is i32 = 64

def panic(msg is String) returns ()
    write(PANIC_FD, "panic: ", 7)
    write(PANIC_FD, msg, strlen(msg))
    write(PANIC_FD, "\n", 1)

    # Print a best-effort stack trace.
    var frames is slice of ptr of u8 = calloc(BT_CAP, 8)
    if frames is null then
        exit(1)
        return
    var n is i32 = backtrace(frames, BT_CAP)
    if n > 0 then
        backtrace_symbols_fd(frames, n, PANIC_FD)
    free(frames)
    exit(1)
    return
