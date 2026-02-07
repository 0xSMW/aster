# core.fs: filesystem traversal + attribute helpers (macOS-first).

# Path-based metadata
extern def stat(path is String, st is mut ref Stat) returns i32
extern def lstat(path is String, st is mut ref Stat) returns i32

# Benchmark helpers (linked via `ASTER_LINK_OBJ=.../fswalk_rt.o`).
extern def aster_fswalk_list_mt(list_path is String, files is mut ref u64, dirs is mut ref u64, bytes is mut ref u64, follow is i32, count_only is i32, inventory is i32, links is mut ref u64, name_bytes is mut ref u64, name_hash is mut ref u64) returns i32
extern def aster_treewalk_list_bulk_mt(list_path is String, files is mut ref u64, dirs is mut ref u64, bytes is mut ref u64, follow is i32, count_only is i32, inventory is i32, links is mut ref u64, name_bytes is mut ref u64, name_hash is mut ref u64) returns i32

def fswalk_list_mt(list_path is String, files is mut ref u64, dirs is mut ref u64, bytes is mut ref u64, follow is i32, count_only is i32, inventory is i32, links is mut ref u64, name_bytes is mut ref u64, name_hash is mut ref u64) returns i32
    return aster_fswalk_list_mt(list_path, files, dirs, bytes, follow, count_only, inventory, links, name_bytes, name_hash)

def treewalk_list_bulk_mt(list_path is String, files is mut ref u64, dirs is mut ref u64, bytes is mut ref u64, follow is i32, count_only is i32, inventory is i32, links is mut ref u64, name_bytes is mut ref u64, name_hash is mut ref u64) returns i32
    return aster_treewalk_list_bulk_mt(list_path, files, dirs, bytes, follow, count_only, inventory, links, name_bytes, name_hash)

# FD-based operations
extern def open(path is String, flags is i32) returns i32
extern def openat(dirfd is i32, path is String, flags is i32) returns i32
extern def fstatat(dirfd is i32, path is String, st is mut ref Stat, flags is i32) returns i32
extern def close(fd is i32) returns i32

# fts traversal
extern def fts_open(paths is ptr of String, options is i32, compar is ptr of void) returns ptr of FTS
extern def fts_read(ftsp is ptr of FTS) returns ptr of FTSENT
extern def fts_close(ftsp is ptr of FTS) returns i32
extern def fts_set(ftsp is ptr of FTS, ent is ptr of FTSENT, instr is i32) returns i32

# opendir traversal (Darwin layout)
struct DIR
    # Placeholder: `DIR` is opaque to Aster code.
    # Note: identifiers may not start with `_` in the Aster1 MVP lexer.
    var opaque is u64

struct DirEnt
    var d_ino is u64
    var d_seekoff is u64
    var d_reclen is u16
    var d_namlen is u16
    var d_type is u8

extern def opendir(path is String) returns ptr of DIR
extern def readdir(dirp is ptr of DIR) returns ptr of DirEnt
extern def closedir(dirp is ptr of DIR) returns i32

const DIRENT_D_NAME_OFF is usize = 21

def dirent_name(ent is ptr of DirEnt) returns String
    var base is String = ent
    return base + DIRENT_D_NAME_OFF


# getattrlistbulk (macOS)
extern def getattrlistbulk(fd is i32, attrs is mut ref AttrList, buf is String, bufsize is usize, options is u64) returns i32

def bulk_init_attrs(attrs is mut ref AttrList, include_size is i32) returns ()
    (*attrs).bitmapcount = ATTR_BIT_MAP_COUNT
    (*attrs).reserved = 0
    (*attrs).commonattr = ATTR_CMN_RETURNED_ATTRS | ATTR_CMN_NAME | ATTR_CMN_OBJTYPE
    (*attrs).volattr = 0
    (*attrs).dirattr = 0
    if include_size != 0 then
        (*attrs).fileattr = ATTR_FILE_DATALENGTH
    else
        (*attrs).fileattr = 0
    (*attrs).forkattr = 0
    return


def bulk_make_options(follow is i32, pack is i32, no_inmem_update is i32) returns u64
    var options is u64 = 0
    if pack != 0 then
        options = options | FSOPT_PACK_INVAL_ATTRS
    if no_inmem_update != 0 then
        options = options | FSOPT_NOINMEMUPDATE
    if follow == 0 then
        options = options | FSOPT_NOFOLLOW
    return options
