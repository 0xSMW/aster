#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <errno.h>
#include <filesystem>
#include <system_error>
#include <string>
#include <fstream>
#include <pthread.h>
#include <sys/stat.h>
#include <fts.h>
#include <sys/attr.h>
#include <sys/vnode.h>
#include <fcntl.h>
#include <unistd.h>
#include <vector>

struct DirNode {
    int fd;
    int depth;
};

static constexpr uint64_t HASH_OFFSET = 1469598103934665603ull;
static constexpr uint64_t HASH_PRIME = 1099511628211ull;

static inline size_t hash_name(uint64_t* hash, const char* name) {
    size_t len = 0;
    while (name[len]) {
        *hash ^= static_cast<uint64_t>(static_cast<unsigned char>(name[len]));
        *hash *= HASH_PRIME;
        len++;
    }
    return len;
}

static int read_env_int(const char* name, int def) {
    const char* val = std::getenv(name);
    if (!val || !*val) return def;
    return std::atoi(val);
}

static bool read_env_bool(const char* name, bool def) {
    const char* val = std::getenv(name);
    if (!val || !*val) return def;
    return std::atoi(val) != 0;
}

static const char* read_env_str(const char* name) {
    const char* val = std::getenv(name);
    if (!val || !*val) return nullptr;
    return val;
}

static size_t clamp_threads(size_t n) {
    if (n < 1) return 1;
    if (n > 32) return 32;
    return n;
}

static size_t default_threads(void) {
    long ncpu = sysconf(_SC_NPROCESSORS_ONLN);
    size_t n = 1;
    if (ncpu > 0) n = (size_t)ncpu;
    if (n > 8) n = 8;
    return n;
}

struct LineFile {
    char* buf;
    size_t len;
    char** lines;
    size_t nlines;
};

static void free_line_file(LineFile* f) {
    if (!f) return;
    std::free(f->lines);
    std::free(f->buf);
    f->buf = nullptr;
    f->len = 0;
    f->lines = nullptr;
    f->nlines = 0;
}

static int read_lines_file(const char* path, LineFile* out) {
    if (!out) return 1;
    *out = (LineFile){0};

    int fd = open(path, O_RDONLY);
    if (fd < 0) return 1;

    struct stat st;
    if (fstat(fd, &st) != 0) {
        close(fd);
        return 1;
    }

    size_t cap = 0;
    if (st.st_size > 0) {
        cap = (size_t)st.st_size;
    }
    char* buf = (char*)std::malloc(cap + 1);
    if (!buf) {
        close(fd);
        return 1;
    }

    size_t off = 0;
    while (off < cap) {
        ssize_t n = read(fd, buf + off, cap - off);
        if (n < 0) {
            if (errno == EINTR) continue;
            std::free(buf);
            close(fd);
            return 1;
        }
        if (n == 0) break;
        off += (size_t)n;
    }
    close(fd);
    buf[off] = 0;

    for (size_t i = 0; i < off; i++) {
        char c = buf[i];
        if (c == '\n' || c == '\r') buf[i] = 0;
    }

    size_t nlines = 0;
    for (size_t i = 0; i < off; i++) {
        if (buf[i] != 0 && (i == 0 || buf[i - 1] == 0)) nlines++;
    }

    char** lines = nullptr;
    if (nlines) {
        lines = (char**)std::malloc(nlines * sizeof(char*));
        if (!lines) {
            std::free(buf);
            return 1;
        }
        size_t wi = 0;
        for (size_t i = 0; i < off; i++) {
            if (buf[i] != 0 && (i == 0 || buf[i - 1] == 0)) {
                lines[wi++] = buf + i;
            }
        }
    }

    out->buf = buf;
    out->len = off;
    out->lines = lines;
    out->nlines = nlines;
    return 0;
}

struct FswalkListCtx {
    char** lines;
    size_t start;
    size_t end;
    int follow;
    int count_only;
    int inventory;
    uint64_t files;
    uint64_t dirs;
    uint64_t bytes;
    uint64_t links;
    uint64_t name_bytes;
    uint64_t name_hash;
};

static void* fswalk_list_worker(void* arg) {
    auto* c = (FswalkListCtx*)arg;
    uint64_t files = 0, dirs = 0, bytes = 0, links = 0, name_bytes = 0;
    uint64_t name_hash = HASH_OFFSET;

    for (size_t i = c->start; i < c->end; i++) {
        const char* line = c->lines[i];
        if (!line || !*line) continue;

        if (c->inventory) {
            name_bytes += hash_name(&name_hash, line);
        }

        struct stat st;
        int rc = c->follow ? stat(line, &st) : lstat(line, &st);
        if (rc != 0) continue;

        if (S_ISDIR(st.st_mode)) {
            dirs++;
        } else if (S_ISREG(st.st_mode)) {
            files++;
            if (!c->count_only) bytes += (uint64_t)st.st_size;
        } else if (S_ISLNK(st.st_mode)) {
            if (c->inventory) links++;
        }
    }

    c->files = files;
    c->dirs = dirs;
    c->bytes = bytes;
    c->links = links;
    c->name_bytes = name_bytes;
    c->name_hash = name_hash;
    return nullptr;
}

static int fswalk_list_mt(const char* list_path, uint64_t* files, uint64_t* dirs, uint64_t* bytes, bool follow,
                          bool count_only, bool inventory, uint64_t* links, uint64_t* name_bytes, uint64_t* name_hash) {
    if (!list_path || !files || !dirs || !bytes) return 1;

    LineFile f{0};
    if (read_lines_file(list_path, &f) != 0) return 1;

    const size_t nlines = f.nlines;
    if (nlines == 0) {
        *files = 0;
        *dirs = 0;
        *bytes = 0;
        if (links) *links = 0;
        if (name_bytes) *name_bytes = 0;
        if (name_hash) *name_hash = HASH_OFFSET;
        free_line_file(&f);
        return 0;
    }

    size_t nth = (size_t)read_env_int("FS_BENCH_THREADS", (int)default_threads());
    nth = clamp_threads(nth);
    if (nth > nlines) nth = nlines;
    if (nth < 1) nth = 1;

    FswalkListCtx ctx[32];
    pthread_t threads[31];
    std::memset(ctx, 0, sizeof(ctx));
    std::memset(threads, 0, sizeof(threads));

    for (size_t tid = 0; tid < nth; tid++) {
        size_t start = (nlines * tid) / nth;
        size_t end = (nlines * (tid + 1)) / nth;
        ctx[tid] = (FswalkListCtx){
            .lines = f.lines,
            .start = start,
            .end = end,
            .follow = follow ? 1 : 0,
            .count_only = count_only ? 1 : 0,
            .inventory = inventory ? 1 : 0,
            .files = 0,
            .dirs = 0,
            .bytes = 0,
            .links = 0,
            .name_bytes = 0,
            .name_hash = HASH_OFFSET,
        };
    }

    for (size_t tid = 1; tid < nth; tid++) {
        pthread_create(&threads[tid - 1], nullptr, fswalk_list_worker, &ctx[tid]);
    }
    (void)fswalk_list_worker(&ctx[0]);
    for (size_t tid = 1; tid < nth; tid++) {
        pthread_join(threads[tid - 1], nullptr);
    }

    uint64_t tfiles = 0, tdirs = 0, tbytes = 0, tlinks = 0, tname_bytes = 0;
    uint64_t combined_hash = HASH_OFFSET;
    for (size_t tid = 0; tid < nth; tid++) {
        tfiles += ctx[tid].files;
        tdirs += ctx[tid].dirs;
        tbytes += ctx[tid].bytes;
        tlinks += ctx[tid].links;
        tname_bytes += ctx[tid].name_bytes;
        if (inventory) {
            uint64_t h = ctx[tid].name_hash;
            for (int b = 0; b < 8; b++) {
                combined_hash ^= (uint8_t)(h & 0xffu);
                combined_hash *= HASH_PRIME;
                h >>= 8;
            }
        }
    }

    *files = tfiles;
    *dirs = tdirs;
    *bytes = tbytes;
    if (links) *links = tlinks;
    if (name_bytes) *name_bytes = tname_bytes;
    if (name_hash) *name_hash = inventory ? combined_hash : HASH_OFFSET;

    free_line_file(&f);
    return 0;
}

static int fswalk_list(const char* list_path, uint64_t* files, uint64_t* dirs, uint64_t* bytes, bool follow, bool count_only, bool inventory, uint64_t* links, uint64_t* name_bytes, uint64_t* name_hash) {
    std::ifstream in(list_path, std::ios::binary);
    if (!in) return 1;

    in.seekg(0, std::ios::end);
    std::streamsize size = in.tellg();
    if (size <= 0) {
        *files = 0;
        *dirs = 0;
        *bytes = 0;
        return 0;
    }
    in.seekg(0, std::ios::beg);

    std::string buf;
    buf.resize(static_cast<size_t>(size));
    in.read(buf.data(), size);
    size_t read = static_cast<size_t>(in.gcount());
    buf.resize(read);
    buf.push_back('\0');

    *files = 0;
    *dirs = 0;
    *bytes = 0;

    size_t start = 0;
    size_t i = 0;
    while (i <= read) {
        char c = buf[i];
        if (c == '\n' || c == '\r' || c == '\0') {
            buf[i] = '\0';
            if (i > start) {
                const char* line = buf.data() + start;
                if (inventory) {
                    *name_bytes += hash_name(name_hash, line);
                }
                struct stat st;
                int rc = follow ? stat(line, &st) : lstat(line, &st);
                if (rc == 0) {
                    if (S_ISDIR(st.st_mode)) {
                        (*dirs)++;
                    } else if (S_ISREG(st.st_mode)) {
                        (*files)++;
                        if (!count_only) {
                            *bytes += static_cast<uint64_t>(st.st_size);
                        }
                    } else if (S_ISLNK(st.st_mode)) {
                        if (inventory) {
                            (*links)++;
                        }
                    }
                }
            }
            size_t j = i + 1;
            while (j < read) {
                char d = buf[j];
                if (d == '\n' || d == '\r') {
                    j++;
                } else {
                    break;
                }
            }
            start = j;
            i = j;
            continue;
        }
        i++;
    }

    return 0;
}

static int fswalk_fts(const char* root, uint64_t* files, uint64_t* dirs, uint64_t* bytes, int max_depth, bool follow, bool count_only, bool inventory, uint64_t* links, uint64_t* name_bytes, uint64_t* name_hash) {
    char* paths[2];
    paths[0] = const_cast<char*>(root);
    paths[1] = nullptr;

    int options = FTS_NOCHDIR;
    options |= follow ? FTS_LOGICAL : FTS_PHYSICAL;

    FTS* ftsp = fts_open(paths, options, nullptr);
    if (!ftsp) return 1;

    *files = 0;
    *dirs = 0;
    *bytes = 0;

    FTSENT* ent;
    while ((ent = fts_read(ftsp)) != nullptr) {
        if (max_depth >= 0 && ent->fts_level >= max_depth) {
            fts_set(ftsp, ent, FTS_SKIP);
        }
        switch (ent->fts_info) {
            case FTS_D:
                (*dirs)++;
                break;
            case FTS_F:
                (*files)++;
                if (!count_only) {
                    if (ent->fts_statp) {
                        *bytes += static_cast<uint64_t>(ent->fts_statp->st_size);
                    }
                }
                break;
            case FTS_SL:
                if (inventory) {
                    (*links)++;
                }
                break;
            default:
                break;
        }
        if (inventory && ent->fts_path) {
            *name_bytes += hash_name(name_hash, ent->fts_path);
        }
    }
    fts_close(ftsp);
    return 0;
}

static int treewalk_list_bulk(const char* list_path, uint64_t* files, uint64_t* dirs, uint64_t* bytes, bool follow, bool count_only, bool inventory, uint64_t* links, uint64_t* name_bytes, uint64_t* name_hash) {
    std::ifstream in(list_path, std::ios::binary);
    if (!in) return 1;

    in.seekg(0, std::ios::end);
    std::streamsize size = in.tellg();
    if (size <= 0) {
        return 0;
    }
    in.seekg(0, std::ios::beg);

    std::string list_buf;
    list_buf.resize(static_cast<size_t>(size));
    in.read(list_buf.data(), size);
    size_t read = static_cast<size_t>(in.gcount());
    list_buf.resize(read);
    list_buf.push_back('\0');

    int open_flags = O_RDONLY | O_DIRECTORY;
    if (!follow) {
        open_flags |= O_NOFOLLOW;
    }
    size_t buf_size = static_cast<size_t>(read_env_int("FS_BENCH_BULK_BUF", 8388608));
    if (buf_size == 0) {
        buf_size = 8388608;
    }
    std::string buf;
    buf.resize(buf_size);

    struct attrlist attrs;
    attrs.bitmapcount = ATTR_BIT_MAP_COUNT;
    attrs.reserved = 0;
    attrs.commonattr = ATTR_CMN_RETURNED_ATTRS | ATTR_CMN_NAME | ATTR_CMN_OBJTYPE;
    attrs.volattr = 0;
    attrs.dirattr = 0;
    attrs.fileattr = count_only ? 0 : ATTR_FILE_DATALENGTH;
    attrs.forkattr = 0;

    uint64_t options = 0;
    if (!follow) {
        options |= FSOPT_NOFOLLOW;
    }
    if (read_env_bool("FS_BENCH_BULK_PACK", true)) {
        options |= FSOPT_PACK_INVAL_ATTRS;
    }
    if (read_env_bool("FS_BENCH_BULK_NOINMEM", false)) {
        options |= FSOPT_NOINMEMUPDATE;
    }

    size_t start = 0;
    size_t i = 0;
    while (i <= read) {
        char c = list_buf[i];
        if (c == '\n' || c == '\r' || c == '\0') {
            list_buf[i] = '\0';
            if (i > start) {
                const char* line = list_buf.data() + start;
                int dirfd = open(line, open_flags);
                if (dirfd >= 0) {
                    (*dirs)++;
                    if (inventory) {
                        *name_bytes += hash_name(name_hash, line);
                    }
                    int n = getattrlistbulk(dirfd, &attrs, buf.data(), buf.size(), options);
                    while (n > 0) {
                        size_t offset = 0;
                        for (int idx = 0; idx < n; idx++) {
                            uint32_t reclen = 0;
                            std::memcpy(&reclen, buf.data() + offset, sizeof(uint32_t));
                            if (reclen == 0) break;

                            const char* rec = buf.data() + offset;
                            attribute_set_t rattrs;
                            std::memcpy(&rattrs, rec + 4, sizeof(attribute_set_t));
                            size_t off = 4 + sizeof(attribute_set_t);

                                attrreference_t name_ref{};
                                size_t name_ref_off = 0;
                                if (rattrs.commonattr & ATTR_CMN_NAME) {
                                    name_ref_off = off;
                                    std::memcpy(&name_ref, rec + off, sizeof(attrreference_t));
                                    off += sizeof(attrreference_t);
                                }

                                uint32_t objtype = 0;
                                if (rattrs.commonattr & ATTR_CMN_OBJTYPE) {
                                    std::memcpy(&objtype, rec + off, sizeof(uint32_t));
                                    off += sizeof(uint32_t);
                                }

                                if (inventory) {
                                    const char* name_base = rec + name_ref_off;
                                    const char* name = name_base + name_ref.attr_dataoffset;
                                    if (objtype == VDIR) {
                                        if (name[0] == '.') {
                                            if (name[1] == '\0') {
                                                offset += reclen;
                                                continue;
                                            }
                                            if (name[1] == '.' && name[2] == '\0') {
                                                offset += reclen;
                                                continue;
                                            }
                                        }
                                        (*dirs)++;
                                    } else if (objtype == VREG) {
                                        (*files)++;
                                        if (!count_only && (rattrs.fileattr & ATTR_FILE_DATALENGTH)) {
                                            uint64_t size_val = 0;
                                            std::memcpy(&size_val, rec + off, sizeof(uint64_t));
                                            *bytes += size_val;
                                        }
                                    } else if (objtype == VLNK) {
                                        (*links)++;
                                    }
                                    *name_bytes += hash_name(name_hash, name);
                                } else {
                                    if (objtype == VDIR) {
                                        const char* name_base = rec + name_ref_off;
                                        const char* name = name_base + name_ref.attr_dataoffset;
                                        if (name[0] == '.') {
                                            if (name[1] == '\0') {
                                                offset += reclen;
                                                continue;
                                            }
                                            if (name[1] == '.' && name[2] == '\0') {
                                                offset += reclen;
                                                continue;
                                            }
                                        }
                                        (*dirs)++;
                                    } else if (objtype == VREG) {
                                        (*files)++;
                                        if (!count_only && (rattrs.fileattr & ATTR_FILE_DATALENGTH)) {
                                            uint64_t size_val = 0;
                                            std::memcpy(&size_val, rec + off, sizeof(uint64_t));
                                            *bytes += size_val;
                                        }
                                    }
                                }

                            offset += reclen;
                        }
                        n = getattrlistbulk(dirfd, &attrs, buf.data(), buf.size(), options);
                    }
                    close(dirfd);
                }
            }
            size_t j = i + 1;
            while (j < read) {
                char d = list_buf[j];
                if (d == '\n' || d == '\r') {
                    j++;
                } else {
                    break;
                }
            }
            start = j;
            i = j;
            continue;
        }
        i++;
    }
    return 0;
}

struct TreewalkListCtx {
    char** dirs_list;
    size_t start;
    size_t end;
    int open_flags;
    uint64_t options;
    struct attrlist attrs;
    size_t buf_size;
    int count_only;
    int inventory;
    uint64_t files;
    uint64_t dirs;
    uint64_t bytes;
    uint64_t links;
    uint64_t name_bytes;
    uint64_t name_hash;
};

static void* treewalk_list_worker(void* arg) {
    auto* c = (TreewalkListCtx*)arg;
    uint64_t files = 0, dirs = 0, bytes = 0, links = 0, name_bytes = 0;
    uint64_t name_hash = HASH_OFFSET;

    char* buf = (char*)std::malloc(c->buf_size);
    if (!buf) return (void*)1;

    for (size_t i = c->start; i < c->end; i++) {
        const char* line = c->dirs_list[i];
        if (!line || !*line) continue;

        int dirfd = open(line, c->open_flags);
        if (dirfd < 0) continue;

        // Count the directory itself.
        dirs++;
        if (c->inventory) {
            name_bytes += hash_name(&name_hash, line);
        }

        int n = getattrlistbulk(dirfd, &c->attrs, buf, c->buf_size, c->options);
        while (n > 0) {
            size_t offset = 0;
            for (int idx = 0; idx < n; idx++) {
                uint32_t reclen = 0;
                std::memcpy(&reclen, buf + offset, sizeof(uint32_t));
                if (reclen == 0) break;

                const char* rec = buf + offset;
                attribute_set_t rattrs;
                std::memcpy(&rattrs, rec + 4, sizeof(attribute_set_t));
                size_t off = 4 + sizeof(attribute_set_t);

                attrreference_t name_ref{};
                size_t name_ref_off = 0;
                if (rattrs.commonattr & ATTR_CMN_NAME) {
                    name_ref_off = off;
                    std::memcpy(&name_ref, rec + off, sizeof(attrreference_t));
                    off += sizeof(attrreference_t);
                }

                uint32_t objtype = 0;
                if (rattrs.commonattr & ATTR_CMN_OBJTYPE) {
                    std::memcpy(&objtype, rec + off, sizeof(uint32_t));
                    off += sizeof(uint32_t);
                }

                const char* name = nullptr;
                if (rattrs.commonattr & ATTR_CMN_NAME) {
                    const char* name_base = rec + name_ref_off;
                    name = name_base + name_ref.attr_dataoffset;
                }

                if (objtype == VDIR) {
                    if (name && name[0] == '.') {
                        if (name[1] == 0) {
                            offset += reclen;
                            continue;
                        }
                        if (name[1] == '.' && name[2] == 0) {
                            offset += reclen;
                            continue;
                        }
                    }
                    dirs++;
                } else if (objtype == VREG) {
                    files++;
                    if (!c->count_only && (rattrs.fileattr & ATTR_FILE_DATALENGTH)) {
                        uint64_t sz = 0;
                        std::memcpy(&sz, rec + off, sizeof(uint64_t));
                        bytes += sz;
                    }
                } else if (objtype == VLNK) {
                    if (c->inventory) links++;
                }

                if (c->inventory && name) {
                    name_bytes += hash_name(&name_hash, name);
                }

                offset += reclen;
            }
            n = getattrlistbulk(dirfd, &c->attrs, buf, c->buf_size, c->options);
        }

        close(dirfd);
    }

    std::free(buf);
    c->files = files;
    c->dirs = dirs;
    c->bytes = bytes;
    c->links = links;
    c->name_bytes = name_bytes;
    c->name_hash = name_hash;
    return nullptr;
}

static int treewalk_list_bulk_mt(const char* list_path, uint64_t* files, uint64_t* dirs, uint64_t* bytes, bool follow,
                                 bool count_only, bool inventory, uint64_t* links, uint64_t* name_bytes, uint64_t* name_hash) {
    if (!list_path || !files || !dirs || !bytes) return 1;

    LineFile f{0};
    if (read_lines_file(list_path, &f) != 0) return 1;

    const size_t nlines = f.nlines;
    if (nlines == 0) {
        *files = 0;
        *dirs = 0;
        *bytes = 0;
        if (links) *links = 0;
        if (name_bytes) *name_bytes = 0;
        if (name_hash) *name_hash = HASH_OFFSET;
        free_line_file(&f);
        return 0;
    }

    size_t nth = (size_t)read_env_int("FS_BENCH_THREADS", (int)default_threads());
    nth = clamp_threads(nth);
    if (nth > nlines) nth = nlines;
    if (nth < 1) nth = 1;

    int open_flags = O_RDONLY | O_DIRECTORY;
    if (!follow) open_flags |= O_NOFOLLOW;

    size_t buf_size = (size_t)read_env_int("FS_BENCH_BULK_BUF", 8388608);
    if (buf_size == 0) buf_size = 8388608;

    struct attrlist attrs;
    std::memset(&attrs, 0, sizeof(attrs));
    attrs.bitmapcount = ATTR_BIT_MAP_COUNT;
    attrs.commonattr = ATTR_CMN_RETURNED_ATTRS | ATTR_CMN_NAME | ATTR_CMN_OBJTYPE;
    attrs.fileattr = count_only ? 0 : ATTR_FILE_DATALENGTH;

    uint64_t options = 0;
    if (!follow) options |= FSOPT_NOFOLLOW;
    if (read_env_bool("FS_BENCH_BULK_PACK", true)) options |= FSOPT_PACK_INVAL_ATTRS;
    if (read_env_bool("FS_BENCH_BULK_NOINMEM", false)) options |= FSOPT_NOINMEMUPDATE;

    TreewalkListCtx ctx[32];
    pthread_t threads[31];
    std::memset(ctx, 0, sizeof(ctx));
    std::memset(threads, 0, sizeof(threads));

    for (size_t tid = 0; tid < nth; tid++) {
        size_t start = (nlines * tid) / nth;
        size_t end = (nlines * (tid + 1)) / nth;
        ctx[tid] = (TreewalkListCtx){
            .dirs_list = f.lines,
            .start = start,
            .end = end,
            .open_flags = open_flags,
            .options = options,
            .attrs = attrs,
            .buf_size = buf_size,
            .count_only = count_only ? 1 : 0,
            .inventory = inventory ? 1 : 0,
            .files = 0,
            .dirs = 0,
            .bytes = 0,
            .links = 0,
            .name_bytes = 0,
            .name_hash = HASH_OFFSET,
        };
    }

    for (size_t tid = 1; tid < nth; tid++) {
        pthread_create(&threads[tid - 1], nullptr, treewalk_list_worker, &ctx[tid]);
    }
    (void)treewalk_list_worker(&ctx[0]);
    for (size_t tid = 1; tid < nth; tid++) {
        pthread_join(threads[tid - 1], nullptr);
    }

    uint64_t tfiles = 0, tdirs = 0, tbytes = 0, tlinks = 0, tname_bytes = 0;
    uint64_t combined_hash = HASH_OFFSET;
    for (size_t tid = 0; tid < nth; tid++) {
        tfiles += ctx[tid].files;
        tdirs += ctx[tid].dirs;
        tbytes += ctx[tid].bytes;
        tlinks += ctx[tid].links;
        tname_bytes += ctx[tid].name_bytes;
        if (inventory) {
            uint64_t h = ctx[tid].name_hash;
            for (int b = 0; b < 8; b++) {
                combined_hash ^= (uint8_t)(h & 0xffu);
                combined_hash *= HASH_PRIME;
                h >>= 8;
            }
        }
    }

    *files = tfiles;
    *dirs = tdirs;
    *bytes = tbytes;
    if (links) *links = tlinks;
    if (name_bytes) *name_bytes = tname_bytes;
    if (name_hash) *name_hash = inventory ? combined_hash : HASH_OFFSET;

    free_line_file(&f);
    return 0;
}

static int treewalk_list_fts(const char* list_path, uint64_t* files, uint64_t* dirs, uint64_t* bytes, bool follow, bool count_only, bool inventory, uint64_t* links, uint64_t* name_bytes, uint64_t* name_hash) {
    std::ifstream in(list_path, std::ios::binary);
    if (!in) return 1;

    in.seekg(0, std::ios::end);
    std::streamsize size = in.tellg();
    if (size <= 0) {
        return 0;
    }
    in.seekg(0, std::ios::beg);

    std::string buf;
    buf.resize(static_cast<size_t>(size));
    in.read(buf.data(), size);
    size_t read = static_cast<size_t>(in.gcount());
    buf.resize(read);
    buf.push_back('\0');

    size_t start = 0;
    size_t i = 0;
    while (i <= read) {
        char c = buf[i];
        if (c == '\n' || c == '\r' || c == '\0') {
            buf[i] = '\0';
            if (i > start) {
                const char* line = buf.data() + start;
                if (inventory) {
                    *name_bytes += hash_name(name_hash, line);
                }
                char* paths[2];
                paths[0] = const_cast<char*>(line);
                paths[1] = nullptr;

                int options = FTS_NOCHDIR;
                options |= follow ? FTS_LOGICAL : FTS_PHYSICAL;

                FTS* ftsp = fts_open(paths, options, nullptr);
                if (ftsp) {
                    FTSENT* ent;
                    while ((ent = fts_read(ftsp)) != nullptr) {
                        if (ent->fts_level >= 1 && ent->fts_info == FTS_D) {
                            fts_set(ftsp, ent, FTS_SKIP);
                        }
                        switch (ent->fts_info) {
                            case FTS_D:
                                (*dirs)++;
                                break;
                            case FTS_F:
                                (*files)++;
                                if (!count_only && ent->fts_statp) {
                                    *bytes += static_cast<uint64_t>(ent->fts_statp->st_size);
                                }
                                break;
                            case FTS_SL:
                                if (inventory) {
                                    (*links)++;
                                }
                                break;
                            default:
                                break;
                        }
                        if (inventory && ent->fts_path) {
                            *name_bytes += hash_name(name_hash, ent->fts_path);
                        }
                    }
                    fts_close(ftsp);
                }
            }
            size_t j = i + 1;
            while (j < read) {
                char d = buf[j];
                if (d == '\n' || d == '\r') {
                    j++;
                } else {
                    break;
                }
            }
            start = j;
            i = j;
            continue;
        }
        i++;
    }
    return 0;
}

static int fswalk_bulk(const char* root, uint64_t* files, uint64_t* dirs, uint64_t* bytes, int max_depth, bool follow, bool count_only, bool inventory, uint64_t* links, uint64_t* name_bytes, uint64_t* name_hash) {
    int open_flags = O_RDONLY | O_DIRECTORY;
    if (!follow) {
        open_flags |= O_NOFOLLOW;
    }
    int root_fd = open(root, open_flags);
    if (root_fd < 0) {
        return 1;
    }

    size_t buf_size = static_cast<size_t>(read_env_int("FS_BENCH_BULK_BUF", 8388608));
    if (buf_size == 0) {
        buf_size = 8388608;
    }
    std::string buf;
    buf.resize(buf_size);

    struct attrlist attrs;
    attrs.bitmapcount = ATTR_BIT_MAP_COUNT;
    attrs.reserved = 0;
    attrs.commonattr = ATTR_CMN_RETURNED_ATTRS | ATTR_CMN_NAME | ATTR_CMN_OBJTYPE;
    attrs.volattr = 0;
    attrs.dirattr = 0;
    attrs.fileattr = count_only ? 0 : ATTR_FILE_DATALENGTH;
    attrs.forkattr = 0;

    uint64_t options = 0;
    if (!follow) {
        options |= FSOPT_NOFOLLOW;
    }
    if (read_env_bool("FS_BENCH_BULK_PACK", true)) {
        options |= FSOPT_PACK_INVAL_ATTRS;
    }
    if (read_env_bool("FS_BENCH_BULK_NOINMEM", false)) {
        options |= FSOPT_NOINMEMUPDATE;
    }

    std::vector<DirNode> stack;
    stack.reserve(1024);
    stack.push_back({root_fd, 0});
    *files = 0;
    *dirs = 0;
    *bytes = 0;
    (*dirs)++;
    if (inventory) {
        *name_bytes += hash_name(name_hash, root);
    }

    while (!stack.empty()) {
        DirNode node = stack.back();
        stack.pop_back();
        int dirfd = node.fd;
        int depth = node.depth;
        if (max_depth >= 0 && depth >= max_depth) {
            close(dirfd);
            continue;
        }

        int n = getattrlistbulk(dirfd, &attrs, buf.data(), buf.size(), options);
        while (n > 0) {
            size_t offset = 0;
            for (int idx = 0; idx < n; idx++) {
                uint32_t reclen = 0;
                std::memcpy(&reclen, buf.data() + offset, sizeof(uint32_t));
                if (reclen == 0) break;

                const char* rec = buf.data() + offset;
                attribute_set_t rattrs;
                std::memcpy(&rattrs, rec + 4, sizeof(attribute_set_t));
                size_t off = 4 + sizeof(attribute_set_t);

                    attrreference_t name_ref{};
                    size_t name_ref_off = 0;
                    if (rattrs.commonattr & ATTR_CMN_NAME) {
                        name_ref_off = off;
                        std::memcpy(&name_ref, rec + off, sizeof(attrreference_t));
                        off += sizeof(attrreference_t);
                    }

                    uint32_t objtype = 0;
                    if (rattrs.commonattr & ATTR_CMN_OBJTYPE) {
                        std::memcpy(&objtype, rec + off, sizeof(uint32_t));
                        off += sizeof(uint32_t);
                    }

                    if (inventory) {
                        const char* name_base = rec + name_ref_off;
                        const char* name = name_base + name_ref.attr_dataoffset;
                        if (objtype == VDIR) {
                            if (name[0] == '.') {
                                if (name[1] == '\0') {
                                    offset += reclen;
                                    continue;
                                }
                                if (name[1] == '.' && name[2] == '\0') {
                                    offset += reclen;
                                    continue;
                                }
                            }
                            (*dirs)++;
                            if (max_depth < 0 || (depth + 1) < max_depth) {
                                int child_fd = openat(dirfd, name, open_flags);
                                if (child_fd >= 0) {
                                    stack.push_back({child_fd, depth + 1});
                                }
                            }
                        } else if (objtype == VREG) {
                            (*files)++;
                            if (!count_only && (rattrs.fileattr & ATTR_FILE_DATALENGTH)) {
                                uint64_t size = 0;
                                std::memcpy(&size, rec + off, sizeof(uint64_t));
                                *bytes += size;
                            }
                        } else if (objtype == VLNK) {
                            (*links)++;
                        }
                        *name_bytes += hash_name(name_hash, name);
                    } else {
                        if (objtype == VDIR) {
                            const char* name_base = rec + name_ref_off;
                            const char* name = name_base + name_ref.attr_dataoffset;
                            if (name[0] == '.') {
                                if (name[1] == '\0') {
                                    offset += reclen;
                                    continue;
                                }
                                if (name[1] == '.' && name[2] == '\0') {
                                    offset += reclen;
                                    continue;
                                }
                            }
                            (*dirs)++;
                            if (max_depth < 0 || (depth + 1) < max_depth) {
                                int child_fd = openat(dirfd, name, open_flags);
                                if (child_fd >= 0) {
                                    stack.push_back({child_fd, depth + 1});
                                }
                            }
                        } else if (objtype == VREG) {
                            (*files)++;
                            if (!count_only && (rattrs.fileattr & ATTR_FILE_DATALENGTH)) {
                                uint64_t size = 0;
                                std::memcpy(&size, rec + off, sizeof(uint64_t));
                                *bytes += size;
                            }
                        }
                    }

                offset += reclen;
            }
            n = getattrlistbulk(dirfd, &attrs, buf.data(), buf.size(), options);
        }
        close(dirfd);
    }
    return 0;
}

static int fswalk_fs(const char* root, uint64_t* files, uint64_t* dirs, uint64_t* bytes, int max_depth, bool follow, bool count_only, bool inventory, uint64_t* links, uint64_t* name_bytes, uint64_t* name_hash) {
    std::filesystem::directory_options opts = std::filesystem::directory_options::skip_permission_denied;
    if (follow) {
        opts |= std::filesystem::directory_options::follow_directory_symlink;
    }

    std::error_code ec;
    std::filesystem::recursive_directory_iterator it(root, opts, ec), end;
    if (ec) {
        return 2;
    }

    *files = 0;
    *dirs = 0;
    *bytes = 0;

    for (; it != end; it.increment(ec)) {
        if (ec) {
            ec.clear();
            continue;
        }
        if (max_depth >= 0 && it.depth() >= max_depth) {
            it.disable_recursion_pending();
        }
        auto status = it->symlink_status(ec);
        if (ec) {
            ec.clear();
            continue;
        }
        if (status.type() == std::filesystem::file_type::directory) {
            (*dirs)++;
        } else if (status.type() == std::filesystem::file_type::regular) {
            (*files)++;
            if (!count_only) {
                auto size = std::filesystem::file_size(it->path(), ec);
                if (!ec) {
                    *bytes += static_cast<uint64_t>(size);
                } else {
                    ec.clear();
                }
            }
        } else if (status.type() == std::filesystem::file_type::symlink) {
            if (inventory) {
                (*links)++;
            }
        }
        if (inventory) {
            const char* path = it->path().c_str();
            *name_bytes += hash_name(name_hash, path);
        }
    }

    return 0;
}

int main(int argc, char** argv) {
    if (argc < 2) {
        std::printf("usage: fswalk <path>\n");
        return 1;
    }

    const char* root = argv[1];
    int max_depth = read_env_int("FS_BENCH_MAX_DEPTH", 6);
    bool follow = read_env_bool("FS_BENCH_FOLLOW_SYMLINKS", false);
    bool count_only = read_env_bool("FS_BENCH_COUNT_ONLY", false);
    bool inventory = read_env_bool("FS_BENCH_INVENTORY", false);
    const char* list_path = read_env_str("FS_BENCH_LIST");
    const char* tree_list = read_env_str("FS_BENCH_TREEWALK_LIST");
    const char* mode = read_env_str("FS_BENCH_CPP_MODE");

    uint64_t files = 0;
    uint64_t dirs = 0;
    uint64_t bytes = 0;
    uint64_t links = 0;
    uint64_t name_bytes = 0;
    uint64_t name_hash = HASH_OFFSET;

    if (list_path) {
        if (fswalk_list_mt(list_path, &files, &dirs, &bytes, follow, count_only, inventory, &links, &name_bytes, &name_hash) != 0) {
            return 2;
        }
    } else if (tree_list) {
        if (mode && std::string(mode) == "fts") {
            if (treewalk_list_fts(tree_list, &files, &dirs, &bytes, follow, count_only, inventory, &links, &name_bytes, &name_hash) != 0) {
                return 2;
            }
        } else {
            if (treewalk_list_bulk_mt(tree_list, &files, &dirs, &bytes, follow, count_only, inventory, &links, &name_bytes, &name_hash) != 0) {
                return 2;
            }
        }
    } else if (mode && std::string(mode) == "fts") {
        if (fswalk_fts(root, &files, &dirs, &bytes, max_depth, follow, count_only, inventory, &links, &name_bytes, &name_hash) != 0) {
            return 2;
        }
    } else if (mode && std::string(mode) == "bulk") {
        if (fswalk_bulk(root, &files, &dirs, &bytes, max_depth, follow, count_only, inventory, &links, &name_bytes, &name_hash) != 0) {
            return 2;
        }
    } else {
        if (fswalk_fs(root, &files, &dirs, &bytes, max_depth, follow, count_only, inventory, &links, &name_bytes, &name_hash) != 0) {
            return 2;
        }
    }

    if (inventory) {
        std::printf("files=%llu dirs=%llu bytes=%llu links=%llu name_bytes=%llu hash=%llu\n",
                    static_cast<unsigned long long>(files),
                    static_cast<unsigned long long>(dirs),
                    static_cast<unsigned long long>(bytes),
                    static_cast<unsigned long long>(links),
                    static_cast<unsigned long long>(name_bytes),
                    static_cast<unsigned long long>(name_hash));
    } else {
        std::printf("files=%llu dirs=%llu bytes=%llu\n",
                    static_cast<unsigned long long>(files),
                    static_cast<unsigned long long>(dirs),
                    static_cast<unsigned long long>(bytes));
    }
    return 0;
}
