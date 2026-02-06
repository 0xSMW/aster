# Aster filesystem traversal benchmark (Aster0 subset)

# Counts files and directories either from a list (FS_BENCH_LIST)
# or via live traversal using fts (no helper objects).

const STAT_MODE_MASK is u32 = 0xF000
const STAT_DIR is u32 = 0x4000
const STAT_FILE is u32 = 0x8000
const STAT_LNK is u32 = 0xA000
const BUF_PAD is usize = 1
const SEEK_SET_CONST is i32 = 0
const SEEK_END_CONST is i32 = 2
const DEFAULT_MAX_DEPTH is i32 = 6
const BULK_BUF_SIZE is usize = 8388608
const BULK_STACK_CAP is usize = 1000000
const DIRNODE_SIZE is usize = 8
const ATTR_REF_SIZE is usize = 8
const U32_SIZE is usize = 4
const ATTR_SET_SIZE is usize = 20
const U64_SIZE is usize = 8
const HASH_OFFSET is u64 = 1469598103934665603
const HASH_PRIME is u64 = 1099511628211

struct PathList2
    var first is MutString
    var second is MutString

struct DirNode
    var fd is i32
    var depth is i32

struct AttrSet
    var commonattr is u32
    var volattr is u32
    var dirattr is u32
    var fileattr is u32
    var forkattr is u32

struct BenchProfile
    var enabled is i32
    var t_bulk is u64
    var t_parse is u64
    var t_open is u64
    var n_bulk is u64
    var n_entries is u64
    var n_open is u64

extern def getenv(name is String) returns String
extern def atoi(s is String) returns i32
extern def malloc(n is usize) returns String
extern def free(ptr is String) returns ()
extern def fopen(path is String, mode is String) returns File
extern def fseek(fp is File, offset is isize, origin is i32) returns i32
extern def ftell(fp is File) returns isize
extern def fread(ptr is String, size is usize, count is usize, fp is File) returns usize
extern def fclose(fp is File) returns i32
extern def stat(path is String, st is mut ref Stat) returns i32
extern def lstat(path is String, st is mut ref Stat) returns i32
extern def printf(fmt is String) returns i32
extern def open(path is String, flags is i32) returns i32
extern def openat(dirfd is i32, path is String, flags is i32) returns i32
extern def fstatat(dirfd is i32, path is String, st is mut ref Stat, flags is i32) returns i32
extern def close(fd is i32) returns i32
extern def getattrlistbulk(fd is i32, attrs is mut ref AttrList, buf is String, bufsize is usize, options is u64) returns i32

# fts traversal
extern def fts_open(paths is ptr of String, options is i32, compar is ptr of void) returns ptr of FTS
extern def fts_read(ftsp is ptr of FTS) returns ptr of FTSENT
extern def fts_close(ftsp is ptr of FTS) returns i32
extern def fts_set(ftsp is ptr of FTS, ent is ptr of FTSENT, instr is i32) returns i32
extern def clock_gettime(clk_id is i32, ts is mut ref TimeSpec) returns i32


def hash_name(hash is mut ref u64, name is String) returns usize
    var i is usize = 0
    while name[i] != 0 do
        var b is u64 = name[i]
        *hash = (*hash ^ b) * HASH_PRIME
        i = i + 1
    return i


def env_int(name is String, defval is i32) returns i32
    var val is String = getenv(name)
    if val is null then
        return defval
    return atoi(val)


def env_bool(name is String, defval is i32) returns i32
    var val is String = getenv(name)
    if val is null then
        return defval
    return atoi(val)


def env_usize(name is String, defval is usize) returns usize
    var val is String = getenv(name)
    if val is null then
        return defval
    var num is i32 = atoi(val)
    if num <= 0 then
        return defval
    return num


def now_ns() returns u64
    var ts is TimeSpec
    clock_gettime(CLOCK_MONOTONIC, &ts)
    return (ts.tv_sec * 1000000000) + ts.tv_nsec


# list-mode traversal

def fswalk_list(list_path is String, files is mut ref u64, dirs is mut ref u64, bytes is mut ref u64, follow is i32, count_only is i32, inventory is i32, links is mut ref u64, name_bytes is mut ref u64, name_hash is mut ref u64, prof is mut ref BenchProfile) returns i32
    var fp is File = fopen(list_path, "r")
    if fp is null then
        return 1

    if fseek(fp, 0, SEEK_END_CONST) != 0 then
        fclose(fp)
        return 1

    var file_len is isize = ftell(fp)
    if file_len <= 0 then
        fclose(fp)
        return 0

    if fseek(fp, 0, SEEK_SET_CONST) != 0 then
        fclose(fp)
        return 1

    var size is usize = file_len
    var buf is MutString = malloc(size + BUF_PAD)
    if buf is null then
        fclose(fp)
        return 1

    var read is usize = fread(buf, 1, size, fp)
    buf[read] = 0

    var i is usize = 0
    var start is usize = 0

    while i <= read do
        var c is u8 = buf[i]
        if c == 10 or c == 13 or c == 0 then
            buf[i] = 0
            if i > start then
                var line is String = buf + start
                if inventory != 0 then
                    var len is usize = hash_name(name_hash, line)
                    *name_bytes = *name_bytes + len
                var st is Stat
                if follow != 0 then
                    if stat(line, &st) == 0 then
                        var mode is u32 = st.st_mode & STAT_MODE_MASK
                        if mode == STAT_DIR then
                            *dirs = *dirs + 1
                        else if mode == STAT_FILE then
                            *files = *files + 1
                            if count_only == 0 then
                                *bytes = *bytes + st.st_size
                else
                    if lstat(line, &st) == 0 then
                        var mode2 is u32 = st.st_mode & STAT_MODE_MASK
                        if mode2 == STAT_DIR then
                            *dirs = *dirs + 1
                        else if mode2 == STAT_FILE then
                            *files = *files + 1
                            if count_only == 0 then
                                *bytes = *bytes + st.st_size
                        else if mode2 == STAT_LNK then
                            if inventory != 0 then
                                *links = *links + 1

            var j is usize = i + 1
            while j < read do
                var d is u8 = buf[j]
                if d == 10 or d == 13 then
                    j = j + 1
                else
                    break
            start = j
            i = j
            continue

        i = i + 1

    free(buf)
    fclose(fp)
    return 0


# treewalk list mode (enumerate prelisted directories, non-recursive)

def treewalk_list(list_path is String, files is mut ref u64, dirs is mut ref u64, bytes is mut ref u64, follow is i32, count_only is i32, inventory is i32, links is mut ref u64, name_bytes is mut ref u64, name_hash is mut ref u64, prof is mut ref BenchProfile) returns i32
    var fp is File = fopen(list_path, "r")
    if fp is null then
        return 1

    if fseek(fp, 0, SEEK_END_CONST) != 0 then
        fclose(fp)
        return 1

    var file_len is isize = ftell(fp)
    if file_len <= 0 then
        fclose(fp)
        return 0

    if fseek(fp, 0, SEEK_SET_CONST) != 0 then
        fclose(fp)
        return 1

    var size is usize = file_len
    var list_buf is MutString = malloc(size + BUF_PAD)
    if list_buf is null then
        fclose(fp)
        return 1

    var read is usize = fread(list_buf, 1, size, fp)
    list_buf[read] = 0

    var open_flags is i32 = O_RDONLY | O_DIRECTORY
    if follow == 0 then
        open_flags = open_flags | O_NOFOLLOW

    var buf_size is usize = env_usize("FS_BENCH_BULK_BUF", BULK_BUF_SIZE)
    var buf is MutString = malloc(buf_size)
    if buf is null then
        free(list_buf)
        fclose(fp)
        return 1

    var attrs is AttrList
    attrs.bitmapcount = ATTR_BIT_MAP_COUNT
    attrs.reserved = 0
    attrs.commonattr = ATTR_CMN_RETURNED_ATTRS | ATTR_CMN_NAME | ATTR_CMN_OBJTYPE
    attrs.volattr = 0
    attrs.dirattr = 0
    if count_only == 0 then
        attrs.fileattr = ATTR_FILE_DATALENGTH
    else
        attrs.fileattr = 0
    attrs.forkattr = 0

    var options is u64 = 0
    var opt_pack is i32 = env_bool("FS_BENCH_BULK_PACK", 1)
    if opt_pack != 0 then
        options = options | FSOPT_PACK_INVAL_ATTRS
    var opt_no_update is i32 = env_bool("FS_BENCH_BULK_NOINMEM", 0)
    if opt_no_update != 0 then
        options = options | FSOPT_NOINMEMUPDATE
    if follow == 0 then
        options = options | FSOPT_NOFOLLOW

    var i is usize = 0
    var start is usize = 0

    while i <= read do
        var c is u8 = list_buf[i]
        if c == 10 or c == 13 or c == 0 then
            list_buf[i] = 0
            if i > start then
                var line is String = list_buf + start
                var dirfd is i32 = open(line, open_flags)
                if dirfd >= 0 then
                    *dirs = *dirs + 1
                    if inventory != 0 then
                        var len_dir is usize = hash_name(name_hash, line)
                        *name_bytes = *name_bytes + len_dir
                    var n is i32 = 0
                    if (*prof).enabled != 0 then
                        var t0 is u64 = now_ns()
                        n = getattrlistbulk(dirfd, &attrs, buf, buf_size, options)
                        (*prof).t_bulk = (*prof).t_bulk + (now_ns() - t0)
                        (*prof).n_bulk = (*prof).n_bulk + 1
                    else
                        n = getattrlistbulk(dirfd, &attrs, buf, buf_size, options)
                    while n > 0 do
                        var p0 is u64 = 0
                        if (*prof).enabled != 0 then
                            p0 = now_ns()
                        var offset is usize = 0
                        var idx is i32 = 0
                        while idx < n do
                            var reclen is u32 = 0
                            memcpy(&reclen, buf + offset, U32_SIZE)
                            if reclen == 0 then
                                break

                            var rec is String = buf + offset
                            var rattrs is AttrSet
                            memcpy(&rattrs, rec + 4, ATTR_SET_SIZE)

                            var off is usize = 4 + ATTR_SET_SIZE
                            var name_ref2 is AttrRef
                            var name_ref_off is usize = 0
                            if (rattrs.commonattr & ATTR_CMN_NAME) != 0 then
                                name_ref_off = off
                                memcpy(&name_ref2, rec + off, ATTR_REF_SIZE)
                                off = off + ATTR_REF_SIZE

                            var objtype2 is u32 = 0
                            if (rattrs.commonattr & ATTR_CMN_OBJTYPE) != 0 then
                                memcpy(&objtype2, rec + off, U32_SIZE)
                                off = off + U32_SIZE

                            if inventory != 0 then
                                var name_ref_base2 is String = rec + name_ref_off
                                var name2 is String = name_ref_base2 + name_ref2.attr_dataoffset
                                if objtype2 == VDIR then
                                    if name2[0] == 46 then
                                        if name2[1] == 0 then
                                            offset = offset + reclen
                                            idx = idx + 1
                                            continue
                                        if name2[1] == 46 and name2[2] == 0 then
                                            offset = offset + reclen
                                            idx = idx + 1
                                            continue
                                    *dirs = *dirs + 1
                                else if objtype2 == VREG then
                                    *files = *files + 1
                                    if count_only == 0 then
                                        if (rattrs.fileattr & ATTR_FILE_DATALENGTH) != 0 then
                                            var size3 is u64 = 0
                                            memcpy(&size3, rec + off, U64_SIZE)
                                            *bytes = *bytes + size3
                                else if objtype2 == VLNK then
                                    *links = *links + 1

                                var len_name2 is usize = hash_name(name_hash, name2)
                                *name_bytes = *name_bytes + len_name2
                            else
                                if objtype2 == VDIR then
                                    var name_ref_base3 is String = rec + name_ref_off
                                    var name3 is String = name_ref_base3 + name_ref2.attr_dataoffset
                                    if name3[0] == 46 then
                                        if name3[1] == 0 then
                                            offset = offset + reclen
                                            idx = idx + 1
                                            continue
                                        if name3[1] == 46 and name3[2] == 0 then
                                            offset = offset + reclen
                                            idx = idx + 1
                                            continue
                                    *dirs = *dirs + 1
                                else if objtype2 == VREG then
                                    *files = *files + 1
                                    if count_only == 0 then
                                        if (rattrs.fileattr & ATTR_FILE_DATALENGTH) != 0 then
                                            var size4 is u64 = 0
                                            memcpy(&size4, rec + off, U64_SIZE)
                                            *bytes = *bytes + size4

                            offset = offset + reclen
                            idx = idx + 1

                        if (*prof).enabled != 0 then
                            (*prof).t_parse = (*prof).t_parse + (now_ns() - p0)
                            (*prof).n_entries = (*prof).n_entries + idx
                            var t1 is u64 = now_ns()
                            n = getattrlistbulk(dirfd, &attrs, buf, buf_size, options)
                            (*prof).t_bulk = (*prof).t_bulk + (now_ns() - t1)
                            (*prof).n_bulk = (*prof).n_bulk + 1
                        else
                            n = getattrlistbulk(dirfd, &attrs, buf, buf_size, options)

                    close(dirfd)

            var j is usize = i + 1
            while j < read do
                var d is u8 = list_buf[j]
                if d == 10 or d == 13 then
                    j = j + 1
                else
                    break
            start = j
            i = j
            continue

        i = i + 1

    free(buf)
    free(list_buf)
    fclose(fp)
    return 0


# compatibility entry used by the Aster0 compiler stub
def fswalk(list_path is String, files is mut ref u64, dirs is mut ref u64, bytes is mut ref u64) returns i32
    var follow is i32 = env_bool("FS_BENCH_FOLLOW_SYMLINKS", 0)
    var count_only is i32 = env_bool("FS_BENCH_COUNT_ONLY", 0)
    var links is u64 = 0
    var name_bytes is u64 = 0
    var name_hash is u64 = HASH_OFFSET
    var prof is BenchProfile
    prof.enabled = 0
    return fswalk_list(list_path, files, dirs, bytes, follow, count_only, 0, &links, &name_bytes, &name_hash, &prof)


# live traversal via fts

def fswalk_live(root is MutString, files is mut ref u64, dirs is mut ref u64, bytes is mut ref u64, max_depth is i32, follow is i32, count_only is i32, inventory is i32, links is mut ref u64, name_bytes is mut ref u64, name_hash is mut ref u64, prof is mut ref BenchProfile) returns i32
    var plist is PathList2
    plist.first = root
    plist.second = null

    var options is i32 = FTS_NOCHDIR
    if follow != 0 then
        options = options | FTS_LOGICAL
    else
        options = options | FTS_PHYSICAL

    var ftsp is ptr of FTS = fts_open(&plist.first, options, null)
    if ftsp is null then
        return 1

    var ent is ptr of FTSENT = fts_read(ftsp)
    while ent is not null do
        var level is i32 = (*ent).fts_level
        if max_depth >= 0 and level >= max_depth then
            if (*ent).fts_info is FTS_D then
                fts_set(ftsp, ent, FTS_SKIP)

        var info is i32 = (*ent).fts_info
        if info is FTS_D then
            *dirs = *dirs + 1
        else if info is FTS_F then
            *files = *files + 1
            if count_only == 0 then
                var stp is ptr of Stat = (*ent).fts_statp
                if stp is not null then
                    *bytes = *bytes + (*stp).st_size
        else if info is FTS_SL then
            if inventory != 0 then
                *links = *links + 1

        if inventory != 0 then
            var p is String = (*ent).fts_path
            var len_path is usize = hash_name(name_hash, p)
            *name_bytes = *name_bytes + len_path

        ent = fts_read(ftsp)

    fts_close(ftsp)
    return 0


# live traversal via getattrlistbulk (macOS)

def fswalk_bulk(root is String, files is mut ref u64, dirs is mut ref u64, bytes is mut ref u64, max_depth is i32, follow is i32, count_only is i32, inventory is i32, links is mut ref u64, name_bytes is mut ref u64, name_hash is mut ref u64, prof is mut ref BenchProfile) returns i32
    var open_flags is i32 = O_RDONLY | O_DIRECTORY
    if follow == 0 then
        open_flags = open_flags | O_NOFOLLOW
    var root_fd is i32 = open(root, open_flags)
    if root_fd < 0 then
        return 1

    var stack is ptr of DirNode = malloc(BULK_STACK_CAP * DIRNODE_SIZE)
    if stack is null then
        close(root_fd)
        return 1

    var buf_size is usize = env_usize("FS_BENCH_BULK_BUF", BULK_BUF_SIZE)
    var buf is MutString = malloc(buf_size)
    if buf is null then
        free(stack)
        close(root_fd)
        return 1

    var attrs is AttrList
    attrs.bitmapcount = ATTR_BIT_MAP_COUNT
    attrs.reserved = 0
    attrs.commonattr = ATTR_CMN_RETURNED_ATTRS | ATTR_CMN_NAME | ATTR_CMN_OBJTYPE
    attrs.volattr = 0
    attrs.dirattr = 0
    if count_only == 0 then
        attrs.fileattr = ATTR_FILE_DATALENGTH
    else
        attrs.fileattr = 0
    attrs.forkattr = 0

    var options is u64 = 0
    var opt_pack is i32 = env_bool("FS_BENCH_BULK_PACK", 1)
    if opt_pack != 0 then
        options = options | FSOPT_PACK_INVAL_ATTRS
    var opt_no_update is i32 = env_bool("FS_BENCH_BULK_NOINMEM", 0)
    if opt_no_update != 0 then
        options = options | FSOPT_NOINMEMUPDATE
    if follow == 0 then
        options = options | FSOPT_NOFOLLOW

    var sp is usize = 0
    stack[0].fd = root_fd
    stack[0].depth = 0
    sp = 1
    *dirs = *dirs + 1
    if inventory != 0 then
        var len_root is usize = hash_name(name_hash, root)
        *name_bytes = *name_bytes + len_root

    while sp > 0 do
        sp = sp - 1
        var node is DirNode = stack[sp]
        var dirfd is i32 = node.fd
        var depth is i32 = node.depth

        if max_depth >= 0 and depth >= max_depth then
            close(dirfd)
            continue

        var n is i32 = 0
        if (*prof).enabled != 0 then
            var t0b is u64 = now_ns()
            n = getattrlistbulk(dirfd, &attrs, buf, buf_size, options)
            (*prof).t_bulk = (*prof).t_bulk + (now_ns() - t0b)
            (*prof).n_bulk = (*prof).n_bulk + 1
        else
            n = getattrlistbulk(dirfd, &attrs, buf, buf_size, options)
        while n > 0 do
            var p0b is u64 = 0
            if (*prof).enabled != 0 then
                p0b = now_ns()
            var offset is usize = 0
            var idx is i32 = 0
            while idx < n do
                var reclen is u32 = 0
                memcpy(&reclen, buf + offset, U32_SIZE)
                if reclen == 0 then
                    break

                var rec is String = buf + offset
                var rattrs is AttrSet
                memcpy(&rattrs, rec + 4, ATTR_SET_SIZE)

                var off is usize = 4 + ATTR_SET_SIZE
                var name_ref2 is AttrRef
                var name_ref_off is usize = 0
                if (rattrs.commonattr & ATTR_CMN_NAME) != 0 then
                    name_ref_off = off
                    memcpy(&name_ref2, rec + off, ATTR_REF_SIZE)
                    off = off + ATTR_REF_SIZE

                var objtype2 is u32 = 0
                if (rattrs.commonattr & ATTR_CMN_OBJTYPE) != 0 then
                    memcpy(&objtype2, rec + off, U32_SIZE)
                    off = off + U32_SIZE

                if inventory != 0 then
                    var name_ref_base2 is String = rec + name_ref_off
                    var name2 is String = name_ref_base2 + name_ref2.attr_dataoffset
                    if objtype2 == VDIR then
                        if name2[0] == 46 then
                            if name2[1] == 0 then
                                offset = offset + reclen
                                idx = idx + 1
                                continue
                            if name2[1] == 46 and name2[2] == 0 then
                                offset = offset + reclen
                                idx = idx + 1
                                continue
                        *dirs = *dirs + 1
                        if max_depth < 0 or (depth + 1) < max_depth then
                            var child_fd is i32 = 0
                            if (*prof).enabled != 0 then
                                var o0c is u64 = now_ns()
                                child_fd = openat(dirfd, name2, open_flags)
                                (*prof).t_open = (*prof).t_open + (now_ns() - o0c)
                                (*prof).n_open = (*prof).n_open + 1
                            else
                                child_fd = openat(dirfd, name2, open_flags)
                            if child_fd >= 0 then
                                if sp >= BULK_STACK_CAP then
                                    close(child_fd)
                                    free(buf)
                                    free(stack)
                                    close(dirfd)
                                    return 3
                                stack[sp].fd = child_fd
                                stack[sp].depth = depth + 1
                                sp = sp + 1
                    else if objtype2 == VREG then
                        *files = *files + 1
                        if count_only == 0 then
                            if (rattrs.fileattr & ATTR_FILE_DATALENGTH) != 0 then
                                var size is u64 = 0
                                memcpy(&size, rec + off, U64_SIZE)
                                *bytes = *bytes + size
                    else if objtype2 == VLNK then
                        *links = *links + 1

                    var len_name is usize = hash_name(name_hash, name2)
                    *name_bytes = *name_bytes + len_name
                else
                    if objtype2 == VDIR then
                        var name_ref_base3 is String = rec + name_ref_off
                        var name3 is String = name_ref_base3 + name_ref2.attr_dataoffset
                        if name3[0] == 46 then
                            if name3[1] == 0 then
                                offset = offset + reclen
                                idx = idx + 1
                                continue
                            if name3[1] == 46 and name3[2] == 0 then
                                offset = offset + reclen
                                idx = idx + 1
                                continue
                        *dirs = *dirs + 1
                        if max_depth < 0 or (depth + 1) < max_depth then
                            var child_fd2 is i32 = 0
                            if (*prof).enabled != 0 then
                                var o1c is u64 = now_ns()
                                child_fd2 = openat(dirfd, name3, open_flags)
                                (*prof).t_open = (*prof).t_open + (now_ns() - o1c)
                                (*prof).n_open = (*prof).n_open + 1
                            else
                                child_fd2 = openat(dirfd, name3, open_flags)
                            if child_fd2 >= 0 then
                                if sp >= BULK_STACK_CAP then
                                    close(child_fd2)
                                    free(buf)
                                    free(stack)
                                    close(dirfd)
                                    return 3
                                stack[sp].fd = child_fd2
                                stack[sp].depth = depth + 1
                                sp = sp + 1
                    else if objtype2 == VREG then
                        *files = *files + 1
                        if count_only == 0 then
                            if (rattrs.fileattr & ATTR_FILE_DATALENGTH) != 0 then
                                var size2 is u64 = 0
                                memcpy(&size2, rec + off, U64_SIZE)
                                *bytes = *bytes + size2

                offset = offset + reclen
                idx = idx + 1

            if (*prof).enabled != 0 then
                (*prof).t_parse = (*prof).t_parse + (now_ns() - p0b)
                (*prof).n_entries = (*prof).n_entries + idx
                var t1b is u64 = now_ns()
                n = getattrlistbulk(dirfd, &attrs, buf, buf_size, options)
                (*prof).t_bulk = (*prof).t_bulk + (now_ns() - t1b)
                (*prof).n_bulk = (*prof).n_bulk + 1
            else
                n = getattrlistbulk(dirfd, &attrs, buf, buf_size, options)

        close(dirfd)

    free(buf)
    free(stack)
    return 0


# entry point for bench harness

def main(argc is i32, argv is ptr of MutString) returns i32
    var list_path is String = getenv("FS_BENCH_LIST")
    var tree_list is String = getenv("FS_BENCH_TREEWALK_LIST")

    var root is MutString = null
    if argc >= 2 then
        root = argv[1]
    else
        root = getenv("FS_BENCH_ROOT")

    if list_path is null and root is null and tree_list is null then
        printf("usage: fswalk <path> (or set FS_BENCH_ROOT/FS_BENCH_LIST)\n")
        return 1

    var follow is i32 = env_bool("FS_BENCH_FOLLOW_SYMLINKS", 0)
    var count_only is i32 = env_bool("FS_BENCH_COUNT_ONLY", 0)
    var inventory is i32 = env_bool("FS_BENCH_INVENTORY", 0)
    var profile is i32 = env_bool("FS_BENCH_PROFILE", 0)

    var files is u64 = 0
    var dirs is u64 = 0
    var bytes is u64 = 0
    var links is u64 = 0
    var name_bytes is u64 = 0
    var name_hash is u64 = HASH_OFFSET
    var prof is BenchProfile
    prof.enabled = profile
    prof.t_bulk = 0
    prof.t_parse = 0
    prof.t_open = 0
    prof.n_bulk = 0
    prof.n_entries = 0
    prof.n_open = 0

    if list_path is not null then
        if fswalk_list(list_path, &files, &dirs, &bytes, follow, count_only, inventory, &links, &name_bytes, &name_hash, &prof) != 0 then
            return 2
    else if tree_list is not null then
        if treewalk_list(tree_list, &files, &dirs, &bytes, follow, count_only, inventory, &links, &name_bytes, &name_hash, &prof) != 0 then
            return 2
    else
        var max_depth is i32 = env_int("FS_BENCH_MAX_DEPTH", DEFAULT_MAX_DEPTH)
        var mode is String = getenv("FS_BENCH_TREEWALK_MODE")
        if mode is not null and mode[0] == 98 then
            if fswalk_bulk(root, &files, &dirs, &bytes, max_depth, follow, count_only, inventory, &links, &name_bytes, &name_hash, &prof) != 0 then
                return 2
        else
            if fswalk_live(root, &files, &dirs, &bytes, max_depth, follow, count_only, inventory, &links, &name_bytes, &name_hash, &prof) != 0 then
                return 2

    if inventory != 0 then
        printf("files=%llu dirs=%llu bytes=%llu links=%llu name_bytes=%llu hash=%llu\n", files, dirs, bytes, links, name_bytes, name_hash)
    else
        printf("files=%llu dirs=%llu bytes=%llu\n", files, dirs, bytes)
    if profile != 0 then
        printf("profile bulk_ns=%llu parse_ns=%llu open_ns=%llu calls=%llu entries=%llu open=%llu\n", prof.t_bulk, prof.t_parse, prof.t_open, prof.n_bulk, prof.n_entries, prof.n_open)
    return 0
