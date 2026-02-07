# Filesystem count demo (fts traversal).
#
# Run:
#   FS_ROOT=. tools/aster/aster run aster/apps/fs_count/fs_count.as

use core.fs
use core.libc

struct PathList2
    var first is String
    var second is String

extern def printf(fmt is String, a is u64, b is u64) returns i32

def main() returns i32
    var root is String = getenv("FS_ROOT")
    if root is null then
        root = "."

    var plist is PathList2
    plist.first = root
    plist.second = null

    var options is i32 = FTS_NOCHDIR | FTS_PHYSICAL
    var ftsp is ptr of FTS = fts_open(&plist.first, options, null)
    if ftsp is null then
        return 1

    var files is u64 = 0
    var dirs is u64 = 0

    var ent is ptr of FTSENT = fts_read(ftsp)
    while ent is not null do
        var info is i32 = (*ent).fts_info
        if info is FTS_D then
            dirs = dirs + 1
        else if info is FTS_F then
            files = files + 1
        ent = fts_read(ftsp)

    fts_close(ftsp)
    printf("files=%llu dirs=%llu\n", files, dirs)
    return 0

