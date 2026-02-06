#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/attr.h>
#include <sys/stat.h>
#include <sys/vnode.h>
#include <unistd.h>

// Multithreaded helpers for the filesystem benchmarks.
//
// These are implemented in C so we can use pthreads for parallelism even
// before the Aster MVP has first-class fn pointers/closures.
//
// Linked into the fswalk benchmark binary via ASTER_LINK_OBJ.

static const uint64_t HASH_OFFSET = 1469598103934665603ull;
static const uint64_t HASH_PRIME = 1099511628211ull;

static inline size_t hash_name(uint64_t* hash, const char* name) {
  size_t len = 0;
  while (name[len]) {
    *hash ^= (uint64_t)(unsigned char)name[len];
    *hash *= HASH_PRIME;
    len++;
  }
  return len;
}

static size_t read_env_usize(const char* name, size_t def) {
  const char* v = getenv(name);
  if (!v || !*v) return def;
  long n = strtol(v, 0, 10);
  if (n <= 0) return def;
  return (size_t)n;
}

static int read_env_int(const char* name, int def) {
  const char* v = getenv(name);
  if (!v || !*v) return def;
  return atoi(v);
}

static int read_env_bool(const char* name, int def) {
  const char* v = getenv(name);
  if (!v || !*v) return def;
  return atoi(v) != 0;
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
  // Avoid oversubscription; stat/getattrlistbulk tends to scale well up to a
  // point but can degrade beyond it depending on cache state.
  if (n > 8) n = 8;
  return n;
}

typedef struct {
  char* buf;
  size_t len;
  char** lines;
  size_t nlines;
} LineFile;

static void free_line_file(LineFile* f) {
  if (!f) return;
  free(f->lines);
  free(f->buf);
  f->lines = 0;
  f->buf = 0;
  f->len = 0;
  f->nlines = 0;
}

static int read_lines(const char* path, LineFile* out) {
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
  // Allow empty files (cap=0) but still null-terminate.
  char* buf = (char*)malloc(cap + 1);
  if (!buf) {
    close(fd);
    return 1;
  }

  size_t off = 0;
  while (off < cap) {
    ssize_t n = read(fd, buf + off, cap - off);
    if (n < 0) {
      if (errno == EINTR) continue;
      free(buf);
      close(fd);
      return 1;
    }
    if (n == 0) break;
    off += (size_t)n;
  }
  close(fd);
  buf[off] = 0;

  // Normalize newlines to '\0' separators.
  for (size_t i = 0; i < off; i++) {
    char c = buf[i];
    if (c == '\n' || c == '\r') buf[i] = 0;
  }

  // Count line starts.
  size_t nlines = 0;
  for (size_t i = 0; i < off; i++) {
    if (buf[i] != 0 && (i == 0 || buf[i - 1] == 0)) nlines++;
  }

  char** lines = 0;
  if (nlines) {
    lines = (char**)malloc(nlines * sizeof(char*));
    if (!lines) {
      free(buf);
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

typedef struct {
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
} FswalkListCtx;

static void* fswalk_list_worker(void* arg) {
  FswalkListCtx* c = (FswalkListCtx*)arg;
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
  return 0;
}

// Multithreaded stat/lstat over a newline-delimited list of paths.
int aster_fswalk_list_mt(const char* list_path, uint64_t* files, uint64_t* dirs, uint64_t* bytes, int follow,
                         int count_only, int inventory, uint64_t* links, uint64_t* name_bytes, uint64_t* name_hash) {
  if (!list_path || !files || !dirs || !bytes) return 1;

  LineFile f = {0};
  if (read_lines(list_path, &f) != 0) return 1;

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
  memset(ctx, 0, sizeof(ctx));
  memset(threads, 0, sizeof(threads));

  for (size_t tid = 0; tid < nth; tid++) {
    size_t start = (nlines * tid) / nth;
    size_t end = (nlines * (tid + 1)) / nth;
    ctx[tid] = (FswalkListCtx){
        .lines = f.lines,
        .start = start,
        .end = end,
        .follow = follow,
        .count_only = count_only,
        .inventory = inventory,
        .files = 0,
        .dirs = 0,
        .bytes = 0,
        .links = 0,
        .name_bytes = 0,
        .name_hash = HASH_OFFSET,
    };
  }

  for (size_t tid = 1; tid < nth; tid++) {
    pthread_create(&threads[tid - 1], 0, fswalk_list_worker, &ctx[tid]);
  }
  fswalk_list_worker(&ctx[0]);
  for (size_t tid = 1; tid < nth; tid++) {
    pthread_join(threads[tid - 1], 0);
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
      // Mix per-thread hashes deterministically by tid.
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

typedef struct {
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
} TreewalkListCtx;

static void* treewalk_list_worker(void* arg) {
  TreewalkListCtx* c = (TreewalkListCtx*)arg;
  uint64_t files = 0, dirs = 0, bytes = 0, links = 0, name_bytes = 0;
  uint64_t name_hash = HASH_OFFSET;

  char* buf = (char*)malloc(c->buf_size);
  if (!buf) return (void*)1;

  for (size_t i = c->start; i < c->end; i++) {
    const char* line = c->dirs_list[i];
    if (!line || !*line) continue;
    int dirfd = open(line, c->open_flags);
    if (dirfd < 0) continue;

    // Count the directory itself (matches the benchmark semantics).
    dirs++;
    if (c->inventory) {
      name_bytes += hash_name(&name_hash, line);
    }

    int n = getattrlistbulk(dirfd, &c->attrs, buf, c->buf_size, c->options);
    while (n > 0) {
      size_t offset = 0;
      for (int idx = 0; idx < n; idx++) {
        uint32_t reclen = 0;
        memcpy(&reclen, buf + offset, sizeof(uint32_t));
        if (reclen == 0) break;

        const char* rec = buf + offset;
        attribute_set_t rattrs;
        memcpy(&rattrs, rec + 4, sizeof(attribute_set_t));
        size_t off = 4 + sizeof(attribute_set_t);

        attrreference_t name_ref = {0};
        size_t name_ref_off = 0;
        if (rattrs.commonattr & ATTR_CMN_NAME) {
          name_ref_off = off;
          memcpy(&name_ref, rec + off, sizeof(attrreference_t));
          off += sizeof(attrreference_t);
        }

        uint32_t objtype = 0;
        if (rattrs.commonattr & ATTR_CMN_OBJTYPE) {
          memcpy(&objtype, rec + off, sizeof(uint32_t));
          off += sizeof(uint32_t);
        }

        const char* name = 0;
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
            memcpy(&sz, rec + off, sizeof(uint64_t));
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

  free(buf);
  c->files = files;
  c->dirs = dirs;
  c->bytes = bytes;
  c->links = links;
  c->name_bytes = name_bytes;
  c->name_hash = name_hash;
  return 0;
}

// Multithreaded getattrlistbulk enumeration of a prelisted set of directory roots.
int aster_treewalk_list_bulk_mt(const char* list_path, uint64_t* files, uint64_t* dirs, uint64_t* bytes, int follow,
                                int count_only, int inventory, uint64_t* links, uint64_t* name_bytes, uint64_t* name_hash) {
  if (!list_path || !files || !dirs || !bytes) return 1;

  LineFile f = {0};
  if (read_lines(list_path, &f) != 0) return 1;

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

  const size_t buf_size = read_env_usize("FS_BENCH_BULK_BUF", 8ull * 1024 * 1024);
  int open_flags = O_RDONLY | O_DIRECTORY;
  if (!follow) open_flags |= O_NOFOLLOW;

  struct attrlist attrs;
  memset(&attrs, 0, sizeof(attrs));
  attrs.bitmapcount = ATTR_BIT_MAP_COUNT;
  attrs.commonattr = ATTR_CMN_RETURNED_ATTRS | ATTR_CMN_NAME | ATTR_CMN_OBJTYPE;
  attrs.fileattr = count_only ? 0 : ATTR_FILE_DATALENGTH;

  uint64_t options = 0;
  if (!follow) options |= FSOPT_NOFOLLOW;
  if (read_env_bool("FS_BENCH_BULK_PACK", 1)) options |= FSOPT_PACK_INVAL_ATTRS;
  if (read_env_bool("FS_BENCH_BULK_NOINMEM", 0)) options |= FSOPT_NOINMEMUPDATE;

  TreewalkListCtx ctx[32];
  pthread_t threads[31];
  memset(ctx, 0, sizeof(ctx));
  memset(threads, 0, sizeof(threads));

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
        .count_only = count_only,
        .inventory = inventory,
        .files = 0,
        .dirs = 0,
        .bytes = 0,
        .links = 0,
        .name_bytes = 0,
        .name_hash = HASH_OFFSET,
    };
  }

  for (size_t tid = 1; tid < nth; tid++) {
    pthread_create(&threads[tid - 1], 0, treewalk_list_worker, &ctx[tid]);
  }
  treewalk_list_worker(&ctx[0]);
  for (size_t tid = 1; tid < nth; tid++) {
    pthread_join(threads[tid - 1], 0);
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
