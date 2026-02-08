# core.net: macOS-first TLS sockets (minimal).
#
# The heavy TLS implementation lives in `asm/compiler/net_tls_rt.c` and is
# linked into produced Aster binaries when `core.net`/`core.http` is imported.

use core.libc

# Runtime helpers (C; linked into Aster binaries).
extern def aster_tls_connect(host is String, port is u16, timeout_ms is i32) returns ptr of void
extern def aster_tls_read(conn is ptr of void, buf is MutString, cap is usize) returns isize
extern def aster_tls_write(conn is ptr of void, buf is String, len is usize) returns isize
extern def aster_tls_close(conn is ptr of void) returns i32


def tls_connect(host is String, port is u16, timeout_ms is i32) returns ptr of void
    return aster_tls_connect(host, port, timeout_ms)


def tls_read(conn is ptr of void, buf is MutString, cap is usize) returns isize
    return aster_tls_read(conn, buf, cap)


def tls_write(conn is ptr of void, buf is String, len is usize) returns isize
    return aster_tls_write(conn, buf, len)


def tls_write_all(conn is ptr of void, buf is String, len is usize) returns i32
    var off is usize = 0
    while off < len do
        var n is isize = tls_write(conn, buf + off, len - off)
        if n <= 0 then
            return 1
        var un is usize = n
        off = off + un
    return 0


def tls_close(conn is ptr of void) returns ()
    aster_tls_close(conn)
    return

