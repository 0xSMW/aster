#include <assert.h>
#include <errno.h>
#include <inttypes.h>
#include <limits.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>

#ifdef __APPLE__
#include <fts.h>
#include <mach-o/dyld.h>
#include <sys/attr.h>
#include <sys/vnode.h>
#include <time.h>
#endif

// Reuse the assembly lexer (token kinds are kept in sync with asm/macros/lexer.inc).
#define LEXER_SIZE 568u

typedef struct {
  uint8_t data[LEXER_SIZE];
} AsterLex;

typedef struct {
  uint32_t kind;  // TOK_*
  uint32_t start; // byte offset into src
  uint32_t end;   // byte offset into src
  uint32_t _pad;
} AsterTok;

uint64_t aster_lex__init(AsterLex* lex, const uint8_t* src, uint64_t len);
uint64_t aster_lex__next(AsterLex* lex, AsterTok* out);

enum {
  TOK_EOF = 0,
  TOK_IDENT = 1,
  TOK_INT = 2,
  TOK_NEWLINE = 3,
  TOK_INDENT = 4,
  TOK_DEDENT = 5,
  TOK_LPAREN = 6,
  TOK_RPAREN = 7,
  TOK_COMMA = 8,
  TOK_PLUS = 9,
  TOK_MINUS = 10,
  TOK_STAR = 11,
  TOK_SLASH = 12,
  TOK_EQ = 13,
  TOK_LT = 14,
  TOK_GT = 15,
  TOK_EQEQ = 16,
  TOK_NEQ = 17,
  TOK_LTE = 18,
  TOK_GTE = 19,
  TOK_KW_DEF = 20,
  TOK_KW_IF = 21,
  TOK_KW_ELSE = 22,
  TOK_KW_WHILE = 23,
  TOK_KW_RETURN = 24,
  TOK_KW_LET = 25,
  TOK_KW_VAR = 26,
  TOK_KW_CONST = 27,
  TOK_LBRACK = 28,
  TOK_RBRACK = 29,
  TOK_DOT = 30,
  TOK_AMP = 31,
  TOK_BAR = 32,
  TOK_CARET = 33,
  TOK_SHL = 34,
  TOK_SHR = 35,
  TOK_FLOAT = 36,
  TOK_STRING = 37,
  TOK_CHAR = 38,
  TOK_KW_EXTERN = 40,
  TOK_KW_STRUCT = 41,
  TOK_KW_RETURNS = 42,
  TOK_KW_IS = 43,
  TOK_KW_OF = 44,
  TOK_KW_NULL = 45,
  TOK_KW_AND = 46,
  TOK_KW_OR = 47,
  TOK_KW_DO = 48,
  TOK_KW_THEN = 49,
  TOK_KW_CONTINUE = 50,
  TOK_KW_BREAK = 51,
  TOK_KW_NOT = 52,
  TOK_KW_MUT = 53,
  TOK_KW_REF = 54,
  TOK_KW_PTR = 55,
  TOK_KW_SLICE = 56,
  TOK_KW_TRUE = 57,
  TOK_KW_FALSE = 58,
  TOK_KW_NOALLOC = 59,
};

typedef enum {
  TY_VOID,
  TY_INT,
  TY_FLOAT,
  TY_PTR,
  TY_STRUCT,
  TY_BOOL,
} TypeKind;

typedef struct Type Type;

typedef struct {
  const char* name;
  size_t name_len;
  Type* type;
  size_t offset;
} Field;

typedef struct StructDef {
  const char* name;
  size_t name_len;
  uint32_t module_id;
  size_t size;
  size_t align;
  Field* fields;
  size_t field_count;
} StructDef;

struct Type {
  TypeKind kind;
  uint16_t bits;      // int/float bits
  bool is_signed;     // int signedness
  bool is_mut;        // ptr mutability (only meaningful for TY_PTR)
  Type* pointee;      // ptr
  StructDef* sdef;    // struct
};

typedef enum {
  CONST_INT,
  CONST_FLOAT,
  CONST_STRING,
} ConstKind;

typedef struct StrConst {
  size_t id;
  uint8_t* bytes; // includes trailing NUL
  size_t len;     // includes trailing NUL
} StrConst;

typedef struct ConstDef {
  const char* name;
  size_t name_len;
  uint32_t module_id;
  Type* type;
  ConstKind kind;
  union {
    uint64_t u;
    struct {
      const char* text;
      size_t len;
    } ftxt;
    StrConst* str;
  } v;
} ConstDef;

typedef struct {
  const char* name;
  size_t name_len;
  Type* type;
} Param;

typedef struct FuncDef {
  size_t id; // stable index within Compiler.funcs
  const char* name;
  size_t name_len;
  uint32_t module_id;
  const char* ir_name; // LLVM symbol name (may be mangled)
  size_t ir_name_len;
  Type* ret;
  Param* params;
  size_t param_count;
  bool is_extern;
  bool is_varargs;
  bool is_noalloc;
  bool direct_alloc; // calls a known allocator directly (or unknown extern in strict mode)
  size_t decl_tok;   // token index for diagnostics (start of decl)
  size_t* calls;     // callee func ids
  size_t call_count, call_cap;
  size_t body_start; // token index (inclusive), only for defs
  size_t body_end;   // token index (exclusive), only for defs
} FuncDef;

typedef struct {
  const char* name;
  size_t name_len;
  Type* type;
  bool is_mut; // true for `var`, false for `let`
  size_t slot;
} Local;

typedef struct ModInfo {
  char* name;      // e.g. "core.io" (or namespace prefix like "core")
  size_t name_len;
  char* rel_path;  // e.g. "src/core/io.as" (NULL for namespace-only modules)
  size_t unit_start; // byte offset in the unit where this module's content begins (file modules only)

  // Imports from the module's `use` preamble (names like "core.io").
  char** uses;
  size_t nuses;

  // Resolved module ids for `uses` (filled after scanning).
  uint32_t* use_ids;
  size_t nuse_ids;

  bool is_namespace;
} ModInfo;

typedef struct {
  const uint8_t* src;
  size_t src_len;
  AsterTok* toks;
  size_t ntoks;
  size_t i; // cursor for module parse
  bool had_error;

  FILE* out;

  // Module metadata extracted from the preprocessed unit comments
  // (`# --- module: ... ---`, `# --- use: ... ---`).
  ModInfo* mods;
  size_t nmods;
  size_t nfile_mods;
  uint32_t entry_mod;

  StructDef** structs;
  size_t nstructs, capstructs;

  FuncDef** funcs;
  size_t nfuncs, capfuncs;

  ConstDef** consts;
  size_t nconsts, capconsts;

  StrConst** strings;
  size_t nstrings, capstrings;

  Type** ptr_types; // interner for pointer types
  size_t nptr_types, capptr_types;
} Compiler;

typedef struct {
  Compiler* c;
  FuncDef* f;
  Local* locals;
  size_t nlocals, caplocals;
  int next_temp;
  int next_label;
  int loop_cond[32];
  int loop_end[32];
  int loop_depth;
  bool terminated;
} FuncCtx;

static void* xmalloc(size_t n) {
  void* p = malloc(n);
  if (!p) {
    fprintf(stderr, "asterc: OOM\n");
    exit(1);
  }
  return p;
}

static void* xrealloc(void* p, size_t n) {
  void* q = realloc(p, n);
  if (!q) {
    fprintf(stderr, "asterc: OOM\n");
    exit(1);
  }
  return q;
}

static bool str_eq(const char* a, size_t alen, const char* b) {
  size_t blen = strlen(b);
  return alen == blen && memcmp(a, b, alen) == 0;
}

static const char* tok_ptr(const Compiler* c, const AsterTok* t) {
  if (t->end < t->start) return (const char*)c->src;
  return (const char*)c->src + t->start;
}

static size_t tok_len(const AsterTok* t) {
  return (size_t)(t->end - t->start);
}

static AsterTok* cur(Compiler* c) {
  return c->i < c->ntoks ? &c->toks[c->i] : &c->toks[c->ntoks - 1];
}

static AsterTok* peek(Compiler* c, size_t n) {
  size_t j = c->i + n;
  if (j >= c->ntoks) j = c->ntoks - 1;
  return &c->toks[j];
}

static bool accept(Compiler* c, uint32_t kind) {
  if (cur(c)->kind != kind) return false;
  c->i++;
  return true;
}

static void compute_line_col(const uint8_t* src, size_t src_len, size_t off, size_t* out_line, size_t* out_col) {
  if (off > src_len) off = src_len;
  size_t line = 1;
  size_t col = 1;
  for (size_t i = 0; i < off; i++) {
    if (src[i] == '\n') {
      line++;
      col = 1;
    } else {
      col++;
    }
  }
  *out_line = line;
  *out_col = col;
}

static void compute_line_col_from(const uint8_t* src, size_t src_len, size_t base_off, size_t off, size_t* out_line,
                                  size_t* out_col) {
  if (base_off > src_len) base_off = src_len;
  if (off > src_len) off = src_len;
  if (off < base_off) off = base_off;
  size_t line = 1;
  size_t col = 1;
  for (size_t i = base_off; i < off; i++) {
    if (src[i] == '\n') {
      line++;
      col = 1;
    } else {
      col++;
    }
  }
  *out_line = line;
  *out_col = col;
}

static void error_at_tok(Compiler* c, const AsterTok* t, const char* fmt, ...) {
  c->had_error = true;
  size_t line = 1, col = 1;
  size_t off = t ? (size_t)t->start : 0;
  const char* file = NULL;
  size_t base = 0;
  uint32_t mod_id = t ? t->_pad : c->entry_mod;
  if (c->mods && mod_id < c->nfile_mods && c->mods[mod_id].rel_path) {
    file = c->mods[mod_id].rel_path;
    base = c->mods[mod_id].unit_start;
  }
  if (file) {
    compute_line_col_from(c->src, c->src_len, base, off, &line, &col);
    fprintf(stderr, "asterc: %s:%zu:%zu: ", file, line, col);
  } else {
    compute_line_col(c->src, c->src_len, off, &line, &col);
    fprintf(stderr, "asterc: error:%zu:%zu: ", line, col);
  }
  va_list ap;
  va_start(ap, fmt);
  vfprintf(stderr, fmt, ap);
  va_end(ap);
  if (t) {
    size_t n = tok_len(t);
    if (n > 40) n = 40;
    fprintf(stderr, " (`%.*s`)", (int)n, tok_ptr(c, t));
  }
  fputc('\n', stderr);
}

static bool expect(Compiler* c, uint32_t kind, const char* what) {
  if (cur(c)->kind != kind) {
    AsterTok* t = cur(c);
    error_at_tok(c, t, "parse error: expected %s, got kind %u", what, t->kind);
    return false;
  }
  c->i++;
  return true;
}

static void skip_newlines(Compiler* c) {
  while (cur(c)->kind == TOK_NEWLINE) c->i++;
}

static uint64_t parse_uint_lit(const char* p, size_t n) {
  uint64_t acc = 0;
  uint64_t base = 10;
  if (n >= 2 && p[0] == '0' && (p[1] == 'x' || p[1] == 'X')) {
    base = 16;
    p += 2;
    n -= 2;
  }
  for (size_t i = 0; i < n; i++) {
    unsigned v;
    char c = p[i];
    if ('0' <= c && c <= '9') v = (unsigned)(c - '0');
    else if ('a' <= c && c <= 'f') v = (unsigned)(c - 'a') + 10;
    else if ('A' <= c && c <= 'F') v = (unsigned)(c - 'A') + 10;
    else break;
    acc = acc * base + v;
  }
  return acc;
}

static Type TY_VOID_OBJ = {.kind = TY_VOID};
static Type TY_BOOL_OBJ = {.kind = TY_BOOL, .bits = 1};
static Type TY_I8_OBJ = {.kind = TY_INT, .bits = 8, .is_signed = true};
static Type TY_U8_OBJ = {.kind = TY_INT, .bits = 8, .is_signed = false};
static Type TY_I16_OBJ = {.kind = TY_INT, .bits = 16, .is_signed = true};
static Type TY_U16_OBJ = {.kind = TY_INT, .bits = 16, .is_signed = false};
static Type TY_I32_OBJ = {.kind = TY_INT, .bits = 32, .is_signed = true};
static Type TY_U32_OBJ = {.kind = TY_INT, .bits = 32, .is_signed = false};
static Type TY_I64_OBJ = {.kind = TY_INT, .bits = 64, .is_signed = true};
static Type TY_U64_OBJ = {.kind = TY_INT, .bits = 64, .is_signed = false};
static Type TY_F32_OBJ = {.kind = TY_FLOAT, .bits = 32};
static Type TY_F64_OBJ = {.kind = TY_FLOAT, .bits = 64};

static Type* ty_void(void) { return &TY_VOID_OBJ; }
static Type* ty_bool(void) { return &TY_BOOL_OBJ; }
static Type* ty_i8(void) { return &TY_I8_OBJ; }
static Type* ty_u8(void) { return &TY_U8_OBJ; }
static Type* ty_i16(void) { return &TY_I16_OBJ; }
static Type* ty_u16(void) { return &TY_U16_OBJ; }
static Type* ty_i32(void) { return &TY_I32_OBJ; }
static Type* ty_u32(void) { return &TY_U32_OBJ; }
static Type* ty_i64(void) { return &TY_I64_OBJ; }
static Type* ty_u64(void) { return &TY_U64_OBJ; }
static Type* ty_usize(void) { return ty_u64(); }
static Type* ty_isize(void) { return ty_i64(); }
static Type* ty_f32(void) { return &TY_F32_OBJ; }
static Type* ty_f64(void) { return &TY_F64_OBJ; }

static Type* ptr_to(Compiler* c, Type* elem, bool is_mut) {
  for (size_t i = 0; i < c->nptr_types; i++) {
    Type* t = c->ptr_types[i];
    if (t->kind == TY_PTR && t->pointee == elem && t->is_mut == is_mut) return t;
  }
  Type* t = (Type*)xmalloc(sizeof(Type));
  *t = (Type){.kind = TY_PTR, .is_mut = is_mut, .pointee = elem};
  if (c->nptr_types == c->capptr_types) {
    c->capptr_types = c->capptr_types ? c->capptr_types * 2 : 16;
    c->ptr_types = (Type**)xrealloc(c->ptr_types, c->capptr_types * sizeof(Type*));
  }
  c->ptr_types[c->nptr_types++] = t;
  return t;
}

static size_t ty_size(Type* t) {
  switch (t->kind) {
    case TY_BOOL: return 1;
    case TY_INT: return (size_t)(t->bits / 8);
    case TY_FLOAT: return (size_t)(t->bits / 8);
    case TY_PTR: return 8;
    case TY_STRUCT: return t->sdef ? t->sdef->size : 0;
    case TY_VOID: return 0;
  }
  return 0;
}

static size_t ty_align(Type* t) {
  switch (t->kind) {
    case TY_BOOL: return 1;
    case TY_INT: return (size_t)(t->bits / 8);
    case TY_FLOAT: return (size_t)(t->bits / 8);
    case TY_PTR: return 8;
    case TY_STRUCT: return t->sdef ? t->sdef->align : 8;
    case TY_VOID: return 1;
  }
  return 1;
}

static const char* llvm_ty(Type* t) {
  switch (t->kind) {
    case TY_VOID: return "void";
    case TY_BOOL: return "i1";
    case TY_PTR: return "ptr";
    case TY_FLOAT:
      return (t->bits == 32) ? "float" : "double";
    case TY_INT:
      switch (t->bits) {
        case 8: return "i8";
        case 16: return "i16";
        case 32: return "i32";
        case 64: return "i64";
        default: return "i64";
      }
    case TY_STRUCT:
      // Struct values are emitted as raw byte arrays in allocas; rvalue struct is not supported in MVP.
      return "ptr";
  }
  return "i64";
}

static StructDef* find_struct(Compiler* c, const char* name, size_t name_len) {
  for (size_t i = 0; i < c->nstructs; i++) {
    StructDef* s = c->structs[i];
    if (s->name_len == name_len && memcmp(s->name, name, name_len) == 0) return s;
  }
  return NULL;
}

static FuncDef* find_func(Compiler* c, const char* name, size_t name_len) {
  for (size_t i = 0; i < c->nfuncs; i++) {
    FuncDef* f = c->funcs[i];
    if (f->name_len == name_len && memcmp(f->name, name, name_len) == 0) return f;
  }
  return NULL;
}

static FuncDef* find_func_in_mod(Compiler* c, uint32_t mod_id, const char* name, size_t name_len) {
  for (size_t i = 0; i < c->nfuncs; i++) {
    FuncDef* f = c->funcs[i];
    if (f->module_id != mod_id) continue;
    if (f->name_len == name_len && memcmp(f->name, name, name_len) == 0) return f;
  }
  return NULL;
}

static ConstDef* find_const(Compiler* c, const char* name, size_t name_len) {
  for (size_t i = 0; i < c->nconsts; i++) {
    ConstDef* k = c->consts[i];
    if (k->name_len == name_len && memcmp(k->name, name, name_len) == 0) return k;
  }
  return NULL;
}

static ConstDef* find_const_in_mod(Compiler* c, uint32_t mod_id, const char* name, size_t name_len) {
  for (size_t i = 0; i < c->nconsts; i++) {
    ConstDef* k = c->consts[i];
    if (k->module_id != mod_id) continue;
    if (k->name_len == name_len && memcmp(k->name, name, name_len) == 0) return k;
  }
  return NULL;
}

static bool is_known_alloc_fn(const char* name, size_t name_len) {
  return str_eq(name, name_len, "malloc") || str_eq(name, name_len, "calloc") || str_eq(name, name_len, "realloc") ||
         str_eq(name, name_len, "posix_memalign");
}

static bool is_known_nonalloc_extern(const char* name, size_t name_len) {
  // A conservative whitelist so `noalloc` can still call common libc helpers.
  return str_eq(name, name_len, "memcpy") || str_eq(name, name_len, "memset") || str_eq(name, name_len, "strlen") ||
         str_eq(name, name_len, "printf") || str_eq(name, name_len, "puts") || str_eq(name, name_len, "write") ||
         str_eq(name, name_len, "clock_gettime") || str_eq(name, name_len, "getenv") || str_eq(name, name_len, "atoi");
}

static void record_call(FuncDef* caller, FuncDef* callee) {
  if (!caller || !callee) return;
  // Avoid degenerate growth if a file contains repeated calls to the same callee.
  for (size_t i = 0; i < caller->call_count; i++) {
    if (caller->calls[i] == callee->id) return;
  }
  if (caller->call_count == caller->call_cap) {
    caller->call_cap = caller->call_cap ? caller->call_cap * 2 : 16;
    caller->calls = (size_t*)xrealloc(caller->calls, caller->call_cap * sizeof(size_t));
  }
  caller->calls[caller->call_count++] = callee->id;
}

static void analyze_noalloc(Compiler* c) {
  const size_t n = c->nfuncs;
  bool* may_alloc = (bool*)xmalloc(n);
  memset(may_alloc, 0, n);

  for (size_t i = 0; i < n; i++) {
    FuncDef* f = c->funcs[i];
    bool alloc = f->direct_alloc;
    if (f->is_extern) {
      // Externs are conservative: assume alloc unless whitelisted.
      if (is_known_alloc_fn(f->name, f->name_len)) alloc = true;
      else if (!is_known_nonalloc_extern(f->name, f->name_len)) alloc = true;
    }
    may_alloc[f->id] = alloc;
  }

  // Fixpoint: propagate alloc effects through the call graph.
  bool changed = true;
  while (changed) {
    changed = false;
    for (size_t i = 0; i < n; i++) {
      FuncDef* f = c->funcs[i];
      if (may_alloc[f->id]) continue;
      for (size_t j = 0; j < f->call_count; j++) {
        size_t cid = f->calls[j];
        if (cid < n && may_alloc[cid]) {
          may_alloc[f->id] = true;
          changed = true;
          break;
        }
      }
    }
  }

  for (size_t i = 0; i < n; i++) {
    FuncDef* f = c->funcs[i];
    if (f->is_noalloc && may_alloc[f->id]) {
      error_at_tok(c, (f->decl_tok < c->ntoks) ? &c->toks[f->decl_tok] : NULL, "`noalloc` function may allocate");
    }
  }

  free(may_alloc);
}

static bool builtin_const(const char* name, size_t name_len, Type** out_ty, uint64_t* out_u) {
#ifdef __APPLE__
  if (str_eq(name, name_len, "O_RDONLY")) {
    *out_ty = ty_i32();
    *out_u = (uint64_t)O_RDONLY;
    return true;
  }
  if (str_eq(name, name_len, "O_DIRECTORY")) {
    *out_ty = ty_i32();
    *out_u = (uint64_t)O_DIRECTORY;
    return true;
  }
  if (str_eq(name, name_len, "O_NOFOLLOW")) {
    *out_ty = ty_i32();
    *out_u = (uint64_t)O_NOFOLLOW;
    return true;
  }

  if (str_eq(name, name_len, "ATTR_BIT_MAP_COUNT")) {
    *out_ty = ty_u16();
    *out_u = (uint64_t)ATTR_BIT_MAP_COUNT;
    return true;
  }
  if (str_eq(name, name_len, "ATTR_CMN_RETURNED_ATTRS")) {
    *out_ty = ty_u32();
    *out_u = (uint64_t)ATTR_CMN_RETURNED_ATTRS;
    return true;
  }
  if (str_eq(name, name_len, "ATTR_CMN_NAME")) {
    *out_ty = ty_u32();
    *out_u = (uint64_t)ATTR_CMN_NAME;
    return true;
  }
  if (str_eq(name, name_len, "ATTR_CMN_OBJTYPE")) {
    *out_ty = ty_u32();
    *out_u = (uint64_t)ATTR_CMN_OBJTYPE;
    return true;
  }
  if (str_eq(name, name_len, "ATTR_FILE_DATALENGTH")) {
    *out_ty = ty_u32();
    *out_u = (uint64_t)ATTR_FILE_DATALENGTH;
    return true;
  }

  if (str_eq(name, name_len, "FSOPT_PACK_INVAL_ATTRS")) {
    *out_ty = ty_u64();
    *out_u = (uint64_t)FSOPT_PACK_INVAL_ATTRS;
    return true;
  }
  if (str_eq(name, name_len, "FSOPT_NOINMEMUPDATE")) {
    *out_ty = ty_u64();
    *out_u = (uint64_t)FSOPT_NOINMEMUPDATE;
    return true;
  }
  if (str_eq(name, name_len, "FSOPT_NOFOLLOW")) {
    *out_ty = ty_u64();
    *out_u = (uint64_t)FSOPT_NOFOLLOW;
    return true;
  }

  if (str_eq(name, name_len, "VDIR")) {
    *out_ty = ty_u32();
    *out_u = (uint64_t)VDIR;
    return true;
  }
  if (str_eq(name, name_len, "VREG")) {
    *out_ty = ty_u32();
    *out_u = (uint64_t)VREG;
    return true;
  }
  if (str_eq(name, name_len, "VLNK")) {
    *out_ty = ty_u32();
    *out_u = (uint64_t)VLNK;
    return true;
  }

  if (str_eq(name, name_len, "CLOCK_MONOTONIC")) {
    *out_ty = ty_i32();
    *out_u = (uint64_t)CLOCK_MONOTONIC;
    return true;
  }

  if (str_eq(name, name_len, "FTS_NOCHDIR")) {
    *out_ty = ty_i32();
    *out_u = (uint64_t)FTS_NOCHDIR;
    return true;
  }
  if (str_eq(name, name_len, "FTS_LOGICAL")) {
    *out_ty = ty_i32();
    *out_u = (uint64_t)FTS_LOGICAL;
    return true;
  }
  if (str_eq(name, name_len, "FTS_PHYSICAL")) {
    *out_ty = ty_i32();
    *out_u = (uint64_t)FTS_PHYSICAL;
    return true;
  }
  if (str_eq(name, name_len, "FTS_D")) {
    *out_ty = ty_i32();
    *out_u = (uint64_t)FTS_D;
    return true;
  }
  if (str_eq(name, name_len, "FTS_F")) {
    *out_ty = ty_i32();
    *out_u = (uint64_t)FTS_F;
    return true;
  }
  if (str_eq(name, name_len, "FTS_SL")) {
    *out_ty = ty_i32();
    *out_u = (uint64_t)FTS_SL;
    return true;
  }
  if (str_eq(name, name_len, "FTS_SKIP")) {
    *out_ty = ty_i32();
    *out_u = (uint64_t)FTS_SKIP;
    return true;
  }
#endif
  (void)name;
  (void)name_len;
  (void)out_ty;
  (void)out_u;
  return false;
}

static void push_struct(Compiler* c, StructDef* s) {
  if (c->nstructs == c->capstructs) {
    c->capstructs = c->capstructs ? c->capstructs * 2 : 32;
    c->structs = (StructDef**)xrealloc(c->structs, c->capstructs * sizeof(StructDef*));
  }
  c->structs[c->nstructs++] = s;
}

static void push_func(Compiler* c, FuncDef* f) {
  if (c->nfuncs == c->capfuncs) {
    c->capfuncs = c->capfuncs ? c->capfuncs * 2 : 64;
    c->funcs = (FuncDef**)xrealloc(c->funcs, c->capfuncs * sizeof(FuncDef*));
  }
  f->id = c->nfuncs;
  c->funcs[c->nfuncs++] = f;
}

static void push_const(Compiler* c, ConstDef* k) {
  if (c->nconsts == c->capconsts) {
    c->capconsts = c->capconsts ? c->capconsts * 2 : 64;
    c->consts = (ConstDef**)xrealloc(c->consts, c->capconsts * sizeof(ConstDef*));
  }
  c->consts[c->nconsts++] = k;
}

static StrConst* new_str_const(Compiler* c, const uint8_t* bytes, size_t len) {
  StrConst* s = (StrConst*)xmalloc(sizeof(StrConst));
  s->id = c->nstrings;
  s->bytes = (uint8_t*)xmalloc(len);
  memcpy(s->bytes, bytes, len);
  s->len = len;
  if (c->nstrings == c->capstrings) {
    c->capstrings = c->capstrings ? c->capstrings * 2 : 64;
    c->strings = (StrConst**)xrealloc(c->strings, c->capstrings * sizeof(StrConst*));
  }
  c->strings[c->nstrings++] = s;
  return s;
}

static bool unescape_string(const char* p, size_t n, uint8_t** out_bytes, size_t* out_len) {
  // Token includes quotes.
  if (n < 2 || p[0] != '"' || p[n - 1] != '"') return false;
  uint8_t* buf = (uint8_t*)xmalloc(n + 1);
  size_t w = 0;
  for (size_t i = 1; i + 1 < n; i++) {
    char c = p[i];
    if (c == '\\' && i + 1 < n - 1) {
      char d = p[++i];
      switch (d) {
        case 'n': buf[w++] = 10; break;
        case 'r': buf[w++] = 13; break;
        case 't': buf[w++] = 9; break;
        case '\\': buf[w++] = (uint8_t)'\\'; break;
        case '"': buf[w++] = (uint8_t)'"'; break;
        default: buf[w++] = (uint8_t)d; break;
      }
      continue;
    }
    buf[w++] = (uint8_t)c;
  }
  buf[w++] = 0;
  *out_bytes = buf;
  *out_len = w;
  return true;
}

static bool unescape_char_lit(const char* p, size_t n, uint8_t* out_byte) {
  // Token includes quotes: 'a' or '\n'
  if (n < 3 || p[0] != '\'' || p[n - 1] != '\'') return false;
  if (p[1] == '\\') {
    if (n != 4) return false;
    switch (p[2]) {
      case 'n': *out_byte = 10; return true;
      case 'r': *out_byte = 13; return true;
      case 't': *out_byte = 9; return true;
      case '\\': *out_byte = (uint8_t)'\\'; return true;
      case '\'': *out_byte = (uint8_t)'\''; return true;
      default: *out_byte = (uint8_t)p[2]; return true;
    }
  }
  if (n != 3) return false;
  *out_byte = (uint8_t)p[1];
  return true;
}

static Type* parse_type_at(Compiler* c, size_t* io_i);

static Type* parse_type_at(Compiler* c, size_t* io_i) {
  size_t i = *io_i;
  if (i >= c->ntoks) return NULL;
  AsterTok* t = &c->toks[i];
  if (t->kind == TOK_LPAREN) {
    if (i + 1 < c->ntoks && c->toks[i + 1].kind == TOK_RPAREN) {
      *io_i = i + 2;
      return ty_void();
    }
    return NULL;
  }
  if (t->kind == TOK_KW_SLICE || t->kind == TOK_KW_PTR) {
    bool ok = true;
    i++;
    if (i >= c->ntoks || c->toks[i].kind != TOK_KW_OF) ok = false;
    i++;
    if (!ok) return NULL;
    Type* elem = parse_type_at(c, &i);
    if (!elem) return NULL;
    *io_i = i;
    return ptr_to(c, elem, true);
  }
  if (t->kind == TOK_KW_REF) {
    i++;
    Type* elem = parse_type_at(c, &i);
    if (!elem) return NULL;
    *io_i = i;
    return ptr_to(c, elem, false);
  }
  if (t->kind == TOK_KW_MUT) {
    i++;
    if (i >= c->ntoks || c->toks[i].kind != TOK_KW_REF) return NULL;
    i++;
    Type* elem = parse_type_at(c, &i);
    if (!elem) return NULL;
    *io_i = i;
    return ptr_to(c, elem, true);
  }
  if (t->kind != TOK_IDENT) return NULL;
  const char* name = tok_ptr(c, t);
  size_t name_len = tok_len(t);
  *io_i = i + 1;

  if (str_eq(name, name_len, "i8")) return ty_i8();
  if (str_eq(name, name_len, "u8")) return ty_u8();
  if (str_eq(name, name_len, "i16")) return ty_i16();
  if (str_eq(name, name_len, "u16")) return ty_u16();
  if (str_eq(name, name_len, "i32")) return ty_i32();
  if (str_eq(name, name_len, "u32")) return ty_u32();
  if (str_eq(name, name_len, "i64")) return ty_i64();
  if (str_eq(name, name_len, "u64")) return ty_u64();
  if (str_eq(name, name_len, "usize")) return ty_usize();
  if (str_eq(name, name_len, "isize")) return ty_isize();
  if (str_eq(name, name_len, "f32")) return ty_f32();
  if (str_eq(name, name_len, "f64")) return ty_f64();
  if (str_eq(name, name_len, "void")) return ty_void();
  // In the Aster1 subset, `String` is a nullable `u8*` used for C-interop and
  // byte buffers. We treat it as mutable to preserve the pre-MVP convention
  // used throughout benches and stdlib.
  if (str_eq(name, name_len, "String")) return ptr_to(c, ty_u8(), true);
  if (str_eq(name, name_len, "MutString")) return ptr_to(c, ty_u8(), true);
  if (str_eq(name, name_len, "File")) return ptr_to(c, ty_void(), false);

  StructDef* s = find_struct(c, name, name_len);
  if (s) {
    Type* st = (Type*)xmalloc(sizeof(Type));
    *st = (Type){.kind = TY_STRUCT, .sdef = s};
    return st;
  }
  return NULL;
}

static bool parse_type(Compiler* c, Type** out) {
  size_t i = c->i;
  Type* t = parse_type_at(c, &i);
  if (!t) {
    error_at_tok(c, cur(c), "expected type");
    return false;
  }
  c->i = i;
  *out = t;
  return true;
}

static void add_builtin_structs(Compiler* c) {
  // PollFd: matches struct pollfd on macOS (fd i32 @0, events i16 @4, revents i16 @6)
  StructDef* pollfd = (StructDef*)xmalloc(sizeof(StructDef));
  pollfd->name = "PollFd";
  pollfd->name_len = strlen(pollfd->name);
  pollfd->size = 8;
  pollfd->align = 4;
  pollfd->field_count = 3;
  pollfd->fields = (Field*)xmalloc(sizeof(Field) * pollfd->field_count);
  pollfd->fields[0] = (Field){.name = "fd", .name_len = 2, .type = ty_i32(), .offset = 0};
  pollfd->fields[1] = (Field){.name = "events", .name_len = 6, .type = ty_i16(), .offset = 4};
  pollfd->fields[2] = (Field){.name = "revents", .name_len = 7, .type = ty_i16(), .offset = 6};
  push_struct(c, pollfd);

  // TimeSpec: struct timespec (tv_sec i64 @0, tv_nsec i64 @8), size 16
  StructDef* timespec = (StructDef*)xmalloc(sizeof(StructDef));
  timespec->name = "TimeSpec";
  timespec->name_len = strlen(timespec->name);
  timespec->size = 16;
  timespec->align = 8;
  timespec->field_count = 2;
  timespec->fields = (Field*)xmalloc(sizeof(Field) * timespec->field_count);
  timespec->fields[0] = (Field){.name = "tv_sec", .name_len = 6, .type = ty_i64(), .offset = 0};
  timespec->fields[1] = (Field){.name = "tv_nsec", .name_len = 7, .type = ty_i64(), .offset = 8};
  push_struct(c, timespec);

  // Stat: struct stat (st_mode u16 @4, st_size i64 @96), size 144
  StructDef* stat = (StructDef*)xmalloc(sizeof(StructDef));
  stat->name = "Stat";
  stat->name_len = strlen(stat->name);
  stat->size = 144;
  stat->align = 8;
  stat->field_count = 2;
  stat->fields = (Field*)xmalloc(sizeof(Field) * stat->field_count);
  stat->fields[0] = (Field){.name = "st_mode", .name_len = 7, .type = ty_u16(), .offset = 4};
  stat->fields[1] = (Field){.name = "st_size", .name_len = 7, .type = ty_i64(), .offset = 96};
  push_struct(c, stat);

  // AttrList: struct attrlist (u16,u16,u32*5), size 24
  StructDef* attrlist = (StructDef*)xmalloc(sizeof(StructDef));
  attrlist->name = "AttrList";
  attrlist->name_len = strlen(attrlist->name);
  attrlist->size = 24;
  attrlist->align = 4;
  attrlist->field_count = 7;
  attrlist->fields = (Field*)xmalloc(sizeof(Field) * attrlist->field_count);
  attrlist->fields[0] = (Field){.name = "bitmapcount", .name_len = 11, .type = ty_u16(), .offset = 0};
  attrlist->fields[1] = (Field){.name = "reserved", .name_len = 8, .type = ty_u16(), .offset = 2};
  attrlist->fields[2] = (Field){.name = "commonattr", .name_len = 10, .type = ty_u32(), .offset = 4};
  attrlist->fields[3] = (Field){.name = "volattr", .name_len = 7, .type = ty_u32(), .offset = 8};
  attrlist->fields[4] = (Field){.name = "dirattr", .name_len = 7, .type = ty_u32(), .offset = 12};
  attrlist->fields[5] = (Field){.name = "fileattr", .name_len = 8, .type = ty_u32(), .offset = 16};
  attrlist->fields[6] = (Field){.name = "forkattr", .name_len = 8, .type = ty_u32(), .offset = 20};
  push_struct(c, attrlist);

  // AttrRef: attrreference_t (i32 @0, u32 @4), size 8
  StructDef* attrref = (StructDef*)xmalloc(sizeof(StructDef));
  attrref->name = "AttrRef";
  attrref->name_len = strlen(attrref->name);
  attrref->size = 8;
  attrref->align = 4;
  attrref->field_count = 2;
  attrref->fields = (Field*)xmalloc(sizeof(Field) * attrref->field_count);
  attrref->fields[0] = (Field){.name = "attr_dataoffset", .name_len = 15, .type = ty_i32(), .offset = 0};
  attrref->fields[1] = (Field){.name = "attr_length", .name_len = 11, .type = ty_u32(), .offset = 4};
  push_struct(c, attrref);

  // FTS: opaque (only used behind pointers)
  StructDef* fts = (StructDef*)xmalloc(sizeof(StructDef));
  memset(fts, 0, sizeof(*fts));
  fts->name = "FTS";
  fts->name_len = strlen(fts->name);
  fts->size = 8;
  fts->align = 8;
  push_struct(c, fts);

  // FTSENT: partial layout for fields used by the bench on macOS.
  // size 112, fts_path @48, fts_level @86, fts_info @88, fts_statp @96
  StructDef* ftsent = (StructDef*)xmalloc(sizeof(StructDef));
  ftsent->name = "FTSENT";
  ftsent->name_len = strlen(ftsent->name);
  ftsent->size = 112;
  ftsent->align = 8;
  ftsent->field_count = 4;
  ftsent->fields = (Field*)xmalloc(sizeof(Field) * ftsent->field_count);
  Type* stat_ty = (Type*)xmalloc(sizeof(Type));
  *stat_ty = (Type){.kind = TY_STRUCT, .sdef = stat};
  // NOTE: `fts_path`/`fts_statp` are treated as mutable pointers in the Aster1
  // subset for compatibility with the existing benches/stdlib conventions
  // (notably `String` being mutable).
  ftsent->fields[0] = (Field){.name = "fts_path", .name_len = 8, .type = ptr_to(c, ty_u8(), true), .offset = 48};
  ftsent->fields[1] = (Field){.name = "fts_level", .name_len = 9, .type = ty_i16(), .offset = 86};
  ftsent->fields[2] = (Field){.name = "fts_info", .name_len = 8, .type = ty_u16(), .offset = 88};
  ftsent->fields[3] = (Field){.name = "fts_statp", .name_len = 9, .type = ptr_to(c, stat_ty, true), .offset = 96};
  push_struct(c, ftsent);
}

static bool parse_const_decl(Compiler* c) {
  size_t decl_tok = c->i;
  uint32_t mod_id = (decl_tok < c->ntoks) ? c->toks[decl_tok]._pad : 0;
  if (!expect(c, TOK_KW_CONST, "`const`")) return false;
  if (cur(c)->kind != TOK_IDENT) {
    error_at_tok(c, cur(c), "expected identifier after `const`");
    return false;
  }
  const char* name = tok_ptr(c, cur(c));
  size_t name_len = tok_len(cur(c));
  if (find_const_in_mod(c, mod_id, name, name_len)) {
    error_at_tok(c, cur(c), "duplicate const in module");
    return false;
  }
  c->i++;
  if (!expect(c, TOK_KW_IS, "`is`")) return false;
  Type* ty = NULL;
  if (!parse_type(c, &ty)) return false;
  if (!expect(c, TOK_EQ, "`=`")) return false;

  ConstDef* k = (ConstDef*)xmalloc(sizeof(ConstDef));
  memset(k, 0, sizeof(*k));
  k->name = name;
  k->name_len = name_len;
  k->module_id = mod_id;
  k->type = ty;

  if (cur(c)->kind == TOK_INT) {
    const char* lit = tok_ptr(c, cur(c));
    size_t lit_len = tok_len(cur(c));
    k->kind = CONST_INT;
    k->v.u = parse_uint_lit(lit, lit_len);
    c->i++;
  } else if (cur(c)->kind == TOK_FLOAT) {
    k->kind = CONST_FLOAT;
    k->v.ftxt.text = tok_ptr(c, cur(c));
    k->v.ftxt.len = tok_len(cur(c));
    c->i++;
  } else if (cur(c)->kind == TOK_STRING) {
    const char* sp = tok_ptr(c, cur(c));
    size_t slen = tok_len(cur(c));
    uint8_t* bytes = NULL;
    size_t blen = 0;
    if (!unescape_string(sp, slen, &bytes, &blen)) {
      error_at_tok(c, cur(c), "invalid string literal");
      return false;
    }
    StrConst* sc = new_str_const(c, bytes, blen);
    free(bytes);
    k->kind = CONST_STRING;
    k->v.str = sc;
    c->i++;
  } else if (cur(c)->kind == TOK_CHAR) {
    const char* cp = tok_ptr(c, cur(c));
    size_t clen = tok_len(cur(c));
    uint8_t b = 0;
    if (!unescape_char_lit(cp, clen, &b)) {
      error_at_tok(c, cur(c), "invalid char literal");
      return false;
    }
    k->kind = CONST_INT;
    k->v.u = (uint64_t)b;
    c->i++;
  } else {
    error_at_tok(c, cur(c), "expected const literal");
    return false;
  }
  push_const(c, k);
  accept(c, TOK_NEWLINE);
  return true;
}

static bool parse_struct_decl(Compiler* c) {
  size_t decl_tok = c->i;
  uint32_t mod_id = (decl_tok < c->ntoks) ? c->toks[decl_tok]._pad : 0;
  if (!expect(c, TOK_KW_STRUCT, "`struct`")) return false;
  if (cur(c)->kind != TOK_IDENT) {
    error_at_tok(c, cur(c), "expected identifier after `struct`");
    return false;
  }
  const char* name = tok_ptr(c, cur(c));
  size_t name_len = tok_len(cur(c));
  if (find_struct(c, name, name_len)) {
    error_at_tok(c, cur(c), "duplicate struct name");
    return false;
  }
  c->i++;
  if (!expect(c, TOK_NEWLINE, "newline")) return false;
  if (!expect(c, TOK_INDENT, "indent")) return false;

  StructDef* s = (StructDef*)xmalloc(sizeof(StructDef));
  memset(s, 0, sizeof(*s));
  s->name = name;
  s->name_len = name_len;
  s->module_id = mod_id;

  size_t fields_cap = 8;
  s->fields = (Field*)xmalloc(sizeof(Field) * fields_cap);
  s->field_count = 0;

  while (cur(c)->kind != TOK_DEDENT && cur(c)->kind != TOK_EOF) {
    skip_newlines(c);
    if (cur(c)->kind == TOK_DEDENT) break;
    if (!expect(c, TOK_KW_VAR, "`var`")) return false;
    if (cur(c)->kind != TOK_IDENT) {
      error_at_tok(c, cur(c), "expected identifier after `var`");
      return false;
    }
    const char* fname = tok_ptr(c, cur(c));
    size_t fname_len = tok_len(cur(c));
    c->i++;
    if (!expect(c, TOK_KW_IS, "`is`")) return false;
    Type* fty = NULL;
    if (!parse_type(c, &fty)) return false;
    accept(c, TOK_NEWLINE);
    if (s->field_count == fields_cap) {
      fields_cap *= 2;
      s->fields = (Field*)xrealloc(s->fields, sizeof(Field) * fields_cap);
    }
    s->fields[s->field_count++] = (Field){.name = fname, .name_len = fname_len, .type = fty, .offset = 0};
  }
  if (!expect(c, TOK_DEDENT, "dedent")) return false;

  // Layout (C-like).
  size_t off = 0;
  size_t align = 1;
  for (size_t i = 0; i < s->field_count; i++) {
    size_t fa = ty_align(s->fields[i].type);
    size_t fs = ty_size(s->fields[i].type);
    if (fa > align) align = fa;
    off = (off + fa - 1) & ~(fa - 1);
    s->fields[i].offset = off;
    off += fs;
  }
  s->align = align;
  s->size = (off + align - 1) & ~(align - 1);

  push_struct(c, s);
  accept(c, TOK_NEWLINE);
  return true;
}

static bool parse_params(Compiler* c, Param** out_params, size_t* out_n) {
  if (!expect(c, TOK_LPAREN, "`(`")) return false;
  Param* params = NULL;
  size_t n = 0, cap = 0;
  if (cur(c)->kind != TOK_RPAREN) {
    for (;;) {
      // Allow a few keyword tokens to be used as names (bench code uses `ptr`).
      if (cur(c)->kind != TOK_IDENT && cur(c)->kind != TOK_KW_PTR) {
        error_at_tok(c, cur(c), "expected parameter name");
        return false;
      }
      const char* pname = tok_ptr(c, cur(c));
      size_t pname_len = tok_len(cur(c));
      c->i++;
      if (!expect(c, TOK_KW_IS, "`is`")) return false;
      Type* pty = NULL;
      if (!parse_type(c, &pty)) return false;
      if (n == cap) {
        cap = cap ? cap * 2 : 8;
        params = (Param*)xrealloc(params, cap * sizeof(Param));
      }
      params[n++] = (Param){.name = pname, .name_len = pname_len, .type = pty};
      if (accept(c, TOK_COMMA)) continue;
      break;
    }
  }
  if (!expect(c, TOK_RPAREN, "`)`")) return false;
  *out_params = params;
  *out_n = n;
  return true;
}

static bool is_varargs_name(const char* name, size_t name_len) {
  return str_eq(name, name_len, "printf") || str_eq(name, name_len, "open") || str_eq(name, name_len, "openat");
}

static bool parse_extern_decl(Compiler* c) {
  size_t decl_tok = c->i;
  uint32_t mod_id = (decl_tok < c->ntoks) ? c->toks[decl_tok]._pad : 0;
  if (!expect(c, TOK_KW_EXTERN, "`extern`")) return false;
  if (!expect(c, TOK_KW_DEF, "`def`")) return false;
  if (cur(c)->kind != TOK_IDENT) {
    error_at_tok(c, cur(c), "expected identifier after `def`");
    return false;
  }
  const char* name = tok_ptr(c, cur(c));
  size_t name_len = tok_len(cur(c));
  if (find_func_in_mod(c, mod_id, name, name_len)) {
    error_at_tok(c, cur(c), "duplicate function in module");
    return false;
  }
  c->i++;

  Param* params = NULL;
  size_t nparams = 0;
  if (!parse_params(c, &params, &nparams)) return false;

  Type* ret = ty_void();
  if (accept(c, TOK_KW_RETURNS)) {
    if (!parse_type(c, &ret)) return false;
  }
  accept(c, TOK_NEWLINE);

  FuncDef* f = (FuncDef*)xmalloc(sizeof(FuncDef));
  memset(f, 0, sizeof(*f));
  f->name = name;
  f->name_len = name_len;
  f->module_id = mod_id;
  f->ir_name = name;
  f->ir_name_len = name_len;
  f->ret = ret;
  f->params = params;
  f->param_count = nparams;
  f->is_extern = true;
  f->is_varargs = is_varargs_name(name, name_len);
  f->decl_tok = decl_tok;
  push_func(c, f);
  return true;
}

static bool parse_def_decl(Compiler* c) {
  size_t decl_tok = c->i;
  uint32_t mod_id = (decl_tok < c->ntoks) ? c->toks[decl_tok]._pad : 0;
  bool is_noalloc = accept(c, TOK_KW_NOALLOC);
  if (!expect(c, TOK_KW_DEF, "`def`")) return false;
  if (cur(c)->kind != TOK_IDENT) {
    error_at_tok(c, cur(c), "expected identifier after `def`");
    return false;
  }
  const char* name = tok_ptr(c, cur(c));
  size_t name_len = tok_len(cur(c));
  c->i++;

  Param* params = NULL;
  size_t nparams = 0;
  if (!parse_params(c, &params, &nparams)) return false;

  Type* ret = ty_void();
  if (accept(c, TOK_KW_RETURNS)) {
    if (!parse_type(c, &ret)) return false;
  }

  if (!expect(c, TOK_NEWLINE, "newline")) return false;
  if (!expect(c, TOK_INDENT, "indent")) return false;

  size_t body_start = c->i;
  int depth = 1;
  while (c->i < c->ntoks && depth > 0) {
    if (c->toks[c->i].kind == TOK_INDENT) depth++;
    else if (c->toks[c->i].kind == TOK_DEDENT) depth--;
    c->i++;
  }
  if (depth != 0) {
    error_at_tok(c, &c->toks[decl_tok], "unterminated function body (indent/dedent mismatch)");
    return false;
  }
  size_t body_end = c->i - 1; // exclude closing DEDENT

  FuncDef* f = (FuncDef*)xmalloc(sizeof(FuncDef));
  memset(f, 0, sizeof(*f));
  f->name = name;
  f->name_len = name_len;
  f->module_id = mod_id;
  f->ret = ret;
  f->params = params;
  f->param_count = nparams;
  f->is_extern = false;
  f->is_noalloc = is_noalloc;
  f->decl_tok = decl_tok;
  f->body_start = body_start;
  f->body_end = body_end;
  push_func(c, f);
  accept(c, TOK_NEWLINE);
  return true;
}

static bool lex_all(const uint8_t* src, size_t len, AsterTok** out_toks, size_t* out_ntoks) {
  AsterLex lex;
  (void)aster_lex__init(&lex, src, (uint64_t)len);
  size_t cap = 4096;
  size_t n = 0;
  AsterTok* toks = (AsterTok*)xmalloc(sizeof(AsterTok) * cap);
  for (;;) {
    AsterTok t;
    (void)aster_lex__next(&lex, &t);
    if (n == cap) {
      cap *= 2;
      toks = (AsterTok*)xrealloc(toks, sizeof(AsterTok) * cap);
    }
    toks[n++] = t;
    if (t.kind == TOK_EOF) break;
  }
  *out_toks = toks;
  *out_ntoks = n;
  return true;
}

static char* dup_bytes0(const char* s, size_t n) {
  char* out = (char*)xmalloc(n + 1);
  if (n) memcpy(out, s, n);
  out[n] = 0;
  return out;
}

static bool meta_parse_mid(const uint8_t* line, size_t line_len, const char* prefix, const char* suffix,
                           const char** out_mid, size_t* out_mid_len) {
  size_t pfx_len = strlen(prefix);
  size_t sfx_len = strlen(suffix);
  if (line_len < pfx_len + sfx_len) return false;
  if (memcmp(line, prefix, pfx_len) != 0) return false;
  if (memcmp(line + (line_len - sfx_len), suffix, sfx_len) != 0) return false;
  *out_mid = (const char*)line + pfx_len;
  *out_mid_len = line_len - pfx_len - sfx_len;
  return true;
}

static char* module_name_from_rel_path(const char* rel_path) {
  if (!rel_path) return dup_bytes0("main", 4);
  size_t n = strlen(rel_path);
  size_t end = n;
  if (end >= 3 && rel_path[end - 3] == '.' && rel_path[end - 2] == 'a' && rel_path[end - 1] == 's') {
    end -= 3;
  }
  size_t start = 0;
  const char* pref = NULL;
  size_t pref_len = 0;

  // Root package modules: src/foo/bar.as -> foo.bar
  if (end >= 4 && rel_path[0] == 's' && rel_path[1] == 'r' && rel_path[2] == 'c' && rel_path[3] == '/') {
    start = 4;
  } else if (end >= 10 && memcmp(rel_path, "libraries/", 10) == 0) {
    // Lockfile deps (workspace-local): libraries/<dep>/src/<path>.as -> <dep>.<path>
    size_t j = 10;
    while (j < end && rel_path[j] != '/') j++;
    if (j < end && rel_path[j] == '/' && (j + 5) <= end && memcmp(rel_path + j, "/src/", 5) == 0) {
      pref = rel_path + 10;
      pref_len = j - 10;
      start = j + 5;
    }
  }

  if (start >= end) return dup_bytes0("main", 4);
  size_t rest_len = end - start;

  // dep root module: libraries/<dep>/src/lib.as is imported as `use <dep>`
  if (pref && pref_len && rest_len == 3 && memcmp(rel_path + start, "lib", 3) == 0) {
    return dup_bytes0(pref, pref_len);
  }

  size_t out_len = rest_len + (pref ? (pref_len + 1) : 0);
  char* out = (char*)xmalloc(out_len + 1);
  size_t o = 0;
  if (pref && pref_len) {
    memcpy(out + o, pref, pref_len);
    o += pref_len;
    out[o++] = '.';
  }
  for (size_t i = 0; i < rest_len; i++) {
    char ch = rel_path[start + i];
    if (ch == '/') ch = '.';
    out[o++] = ch;
  }
  out[o] = 0;
  return out;
}

static ssize_t mod_find_by_name(const Compiler* c, const char* name, size_t name_len, bool file_only) {
  size_t n = file_only ? c->nfile_mods : c->nmods;
  for (size_t i = 0; i < n; i++) {
    const ModInfo* m = &c->mods[i];
    if (m->name_len == name_len && memcmp(m->name, name, name_len) == 0) return (ssize_t)i;
  }
  return -1;
}

static void mod_add_use(ModInfo* m, const char* mod, size_t mod_len) {
  if (!m) return;
  char** nuses = (char**)xrealloc(m->uses, sizeof(char*) * (m->nuses + 1));
  m->uses = nuses;
  m->uses[m->nuses++] = dup_bytes0(mod, mod_len);
}

static void compiler_scan_unit_meta(Compiler* c) {
  c->mods = NULL;
  c->nmods = 0;
  c->nfile_mods = 0;
  c->entry_mod = 0;

  size_t cap = 0;
  const uint8_t* src = c->src;
  size_t len = c->src_len;

  size_t off = 0;
  while (off < len) {
    size_t line_start = off;
    while (off < len && src[off] != '\n') off++;
    size_t line_end = off;
    if (off < len && src[off] == '\n') off++;

    const uint8_t* line = src + line_start;
    size_t line_len = line_end - line_start;

    const char* mid = NULL;
    size_t mid_len = 0;
    if (meta_parse_mid(line, line_len, "# --- module: ", " ---", &mid, &mid_len)) {
      if (c->nmods == cap) {
        cap = cap ? cap * 2 : 16;
        c->mods = (ModInfo*)xrealloc(c->mods, cap * sizeof(ModInfo));
      }
      ModInfo* m = &c->mods[c->nmods++];
      memset(m, 0, sizeof(*m));
      m->rel_path = dup_bytes0(mid, mid_len);
      m->name = module_name_from_rel_path(m->rel_path);
      m->name_len = strlen(m->name);
      m->unit_start = off; // start of the next line
      m->is_namespace = false;
      continue;
    }
    if (meta_parse_mid(line, line_len, "# --- use: ", " ---", &mid, &mid_len)) {
      if (c->nmods == 0) continue;
      mod_add_use(&c->mods[c->nmods - 1], mid, mid_len);
      continue;
    }
  }

  if (c->nmods == 0) {
    cap = 1;
    c->mods = (ModInfo*)xrealloc(c->mods, cap * sizeof(ModInfo));
    ModInfo* m = &c->mods[0];
    memset(m, 0, sizeof(*m));
    m->rel_path = dup_bytes0("input.as", 8);
    m->name = dup_bytes0("main", 4);
    m->name_len = 4;
    m->unit_start = 0;
    m->is_namespace = false;
    c->nmods = 1;
  }

  c->nfile_mods = c->nmods;
  c->entry_mod = (uint32_t)(c->nfile_mods - 1);

  // Resolve import module ids (file modules only).
  for (size_t mi = 0; mi < c->nfile_mods; mi++) {
    ModInfo* m = &c->mods[mi];
    if (!m->nuses) continue;
    m->use_ids = (uint32_t*)xmalloc(sizeof(uint32_t) * m->nuses);
    m->nuse_ids = 0;
    for (size_t ui = 0; ui < m->nuses; ui++) {
      const char* uname = m->uses[ui];
      size_t uname_len = strlen(uname);
      ssize_t id = mod_find_by_name(c, uname, uname_len, true);
      if (id >= 0) {
        m->use_ids[m->nuse_ids++] = (uint32_t)id;
      }
    }
  }

  // Add namespace modules for prefix qualification (e.g. `core.io.println`).
  for (size_t mi = 0; mi < c->nfile_mods; mi++) {
    const ModInfo* fm = &c->mods[mi];
    const char* nm = fm->name;
    size_t nm_len = fm->name_len;
    // Create each prefix segment up to (but excluding) the full module name.
    for (size_t i = 0; i < nm_len; i++) {
      if (nm[i] != '.') continue;
      const char* pref = nm;
      size_t pref_len = i;
      if (pref_len == 0) continue;
      if (mod_find_by_name(c, pref, pref_len, false) >= 0) continue;
      if (c->nmods == cap) {
        cap = cap ? cap * 2 : 16;
        c->mods = (ModInfo*)xrealloc(c->mods, cap * sizeof(ModInfo));
      }
      ModInfo* m = &c->mods[c->nmods++];
      memset(m, 0, sizeof(*m));
      m->name = dup_bytes0(pref, pref_len);
      m->name_len = pref_len;
      m->rel_path = NULL;
      m->unit_start = 0;
      m->is_namespace = true;
    }
  }
}

static void assign_tok_modules(Compiler* c) {
  if (!c->toks || c->ntoks == 0) return;
  // Default: everything in the entry module.
  if (!c->mods || c->nfile_mods == 0) {
    for (size_t i = 0; i < c->ntoks; i++) c->toks[i]._pad = 0;
    return;
  }

  uint32_t cur_mod = 0;
  for (size_t ti = 0; ti < c->ntoks; ti++) {
    AsterTok* t = &c->toks[ti];
    size_t start = (size_t)t->start;
    while ((cur_mod + 1) < (uint32_t)c->nfile_mods && start >= c->mods[cur_mod + 1].unit_start) {
      cur_mod++;
    }
    t->_pad = cur_mod;
  }
}

static bool is_mangle_ident_char(char c) {
  return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || (c == '_');
}

static char* mangle_ir_sym(const Compiler* c, uint32_t mod_id, const char* name, size_t name_len) {
  const char* mname = "unit";
  size_t mname_len = 4;
  if (c && c->mods && mod_id < c->nmods && c->mods[mod_id].name) {
    mname = c->mods[mod_id].name;
    mname_len = c->mods[mod_id].name_len;
  }

  // `aster_<module>__<symbol>` with module '.' -> '_', and conservative
  // sanitization for any non-identifier chars.
  size_t out_len = 6 + mname_len + 2 + name_len; // "aster_" + m + "__" + sym
  char* out = (char*)xmalloc(out_len + 1);
  size_t o = 0;
  memcpy(out + o, "aster_", 6);
  o += 6;
  for (size_t i = 0; i < mname_len; i++) {
    char ch = mname[i];
    if (ch == '.') ch = '_';
    if (!is_mangle_ident_char(ch)) ch = '_';
    out[o++] = ch;
  }
  out[o++] = '_';
  out[o++] = '_';
  for (size_t i = 0; i < name_len; i++) {
    char ch = name[i];
    if (!is_mangle_ident_char(ch)) ch = '_';
    out[o++] = ch;
  }
  out[o] = 0;
  return out;
}

static void assign_ir_names(Compiler* c) {
  for (size_t i = 0; i < c->nfuncs; i++) {
    FuncDef* f = c->funcs[i];
    if (f->is_extern) {
      if (!f->ir_name) {
        f->ir_name = f->name;
        f->ir_name_len = f->name_len;
      }
      continue;
    }
    // Preserve the canonical program entrypoint: `def main()` in the entry module.
    if (f->module_id == c->entry_mod && str_eq(f->name, f->name_len, "main")) {
      f->ir_name = "main";
      f->ir_name_len = 4;
      continue;
    }
    if (!f->ir_name) {
      f->ir_name = mangle_ir_sym(c, f->module_id, f->name, f->name_len);
      f->ir_name_len = strlen(f->ir_name);
    }
  }
}

// IR helpers
static int new_temp(FuncCtx* f) { return f->next_temp++; }
static int new_label(FuncCtx* f) { return f->next_label++; }

static void emit_ssa(FILE* out, char kind, int id) {
  fprintf(out, "%%%c%d", kind, id);
}

static void emit_label(FILE* out, int id) {
  fprintf(out, "bb%d:\n", id);
}

typedef struct {
  Type* type;
  bool is_lvalue;
  bool is_assignable; // lvalue may be read-only (e.g. `ref` deref, `let` locals)
  enum { V_CONST_INT, V_CONST_FLOAT, V_NULL, V_SSA_TEMP, V_SSA_PARAM, V_SSA_LOCAL, V_FUNC, V_MODULE } kind;
  union {
    uint64_t u;
    struct { const char* text; size_t len; } ftxt;
    int id;
    FuncDef* fn;
    uint32_t mod;
  } v;
} Value;

static void emit_value(FILE* out, Value v) {
  switch (v.kind) {
    case V_CONST_INT:
      if ((v.type && (v.type->kind == TY_PTR || v.type->kind == TY_STRUCT)) && v.v.u == 0) {
        // Avoid invalid `ptr 0` constants in LLVM IR; treat as null pointer.
        fprintf(out, "null");
        break;
      }
      fprintf(out, "%" PRIu64, v.v.u);
      break;
    case V_CONST_FLOAT:
      fwrite(v.v.ftxt.text, 1, v.v.ftxt.len, out);
      break;
    case V_NULL:
      fprintf(out, "null");
      break;
    case V_SSA_TEMP:
      emit_ssa(out, 't', v.v.id);
      break;
    case V_SSA_PARAM:
      emit_ssa(out, 'p', v.v.id);
      break;
    case V_SSA_LOCAL:
      emit_ssa(out, 'l', v.v.id);
      break;
    case V_FUNC:
      if (v.v.fn->ir_name) fprintf(out, "@%.*s", (int)v.v.fn->ir_name_len, v.v.fn->ir_name);
      else fprintf(out, "@%.*s", (int)v.v.fn->name_len, v.v.fn->name);
      break;
    case V_MODULE:
      // Module values are compile-time only (used for qualified name resolution).
      fprintf(out, "null");
      break;
  }
}

static void error_generic(FuncCtx* f, const char* fmt, ...) {
  f->c->had_error = true;
  fprintf(stderr, "asterc: error: ");
  va_list ap;
  va_start(ap, fmt);
  vfprintf(stderr, fmt, ap);
  va_end(ap);
  fputc('\n', stderr);
}

static Value load_if_needed(FuncCtx* f, Value v) {
  if (!v.is_lvalue) return v;
  // Struct rvalue loads are not supported in MVP.
  if (v.type->kind == TY_STRUCT) {
    error_generic(f, "unsupported struct rvalue load");
    return (Value){.type = ty_i32(), .kind = V_CONST_INT, .v.u = 0};
  }
  int t = new_temp(f);
  fprintf(f->c->out, "  ");
  emit_ssa(f->c->out, 't', t);
  fprintf(f->c->out, " = load %s, ptr ", llvm_ty(v.type));
  Value ptrv = v;
  ptrv.is_lvalue = false;
  emit_value(f->c->out, ptrv);
  fprintf(f->c->out, ", align %zu\n", ty_align(v.type));
  return (Value){.type = v.type, .kind = V_SSA_TEMP, .v.id = t};
}

static Value cast_to(FuncCtx* f, Type* dst, Value v) {
  static const char ZERO_F64[] = "0.0";

  if (!dst || !v.type) {
    error_generic(f, "internal: cast with null type");
    return (Value){.type = dst ? dst : ty_i32(), .kind = V_CONST_INT, .v.u = 0};
  }

  if (dst->kind == TY_STRUCT) {
    // Struct values are represented by their storage (lvalues) in MVP.
    if (v.type->kind != TY_STRUCT || !dst->sdef || !v.type->sdef || v.type->sdef != dst->sdef) {
      error_generic(f, "type mismatch: cannot cast `%s` to `%s`", llvm_ty(v.type), llvm_ty(dst));
      return (Value){.type = dst, .kind = V_CONST_INT, .v.u = 0};
    }
    v.type = dst;
    return v;
  }

  v = load_if_needed(f, v);

  // Pointer casts (opaque pointers in IR; allow pointee mismatch).
  if (dst->kind == TY_PTR) {
    if (v.type->kind == TY_PTR || v.kind == V_NULL) {
      // Allow mut -> immut, but not immut -> mut (except null).
      if (v.type->kind == TY_PTR && !v.type->is_mut && dst->is_mut && v.kind != V_NULL) {
        error_generic(f, "type mismatch: cannot cast immutable pointer to mutable pointer");
        return (Value){.type = dst, .kind = V_NULL};
      }
      v.type = dst;
      return v;
    }
    error_generic(f, "type mismatch: cannot cast `%s` to `%s`", llvm_ty(v.type), llvm_ty(dst));
    return (Value){.type = dst, .kind = V_NULL};
  }

  // Bool casts.
  if (dst->kind == TY_BOOL) {
    if (v.type->kind == TY_BOOL) return v;
    int t = new_temp(f);
    fprintf(f->c->out, "  ");
    emit_ssa(f->c->out, 't', t);
    if (v.type->kind == TY_PTR) {
      fprintf(f->c->out, " = icmp ne ptr ");
      emit_value(f->c->out, v);
      fprintf(f->c->out, ", null\n");
      return (Value){.type = ty_bool(), .kind = V_SSA_TEMP, .v.id = t};
    }
    if (v.type->kind == TY_FLOAT) {
      fprintf(f->c->out, " = fcmp one %s ", llvm_ty(v.type));
      emit_value(f->c->out, v);
      fprintf(f->c->out, ", %s\n", ZERO_F64);
      return (Value){.type = ty_bool(), .kind = V_SSA_TEMP, .v.id = t};
    }
    if (v.type->kind == TY_INT) {
      fprintf(f->c->out, " = icmp ne %s ", llvm_ty(v.type));
      emit_value(f->c->out, v);
      fprintf(f->c->out, ", 0\n");
      return (Value){.type = ty_bool(), .kind = V_SSA_TEMP, .v.id = t};
    }
    error_generic(f, "type mismatch: cannot cast `%s` to `%s`", llvm_ty(v.type), llvm_ty(dst));
    return (Value){.type = ty_bool(), .kind = V_CONST_INT, .v.u = 0};
  }

  // Integer casts.
  if (dst->kind == TY_INT) {
    if (v.type->kind == TY_BOOL) {
      int t = new_temp(f);
      fprintf(f->c->out, "  ");
      emit_ssa(f->c->out, 't', t);
      fprintf(f->c->out, " = zext i1 ");
      emit_value(f->c->out, v);
      fprintf(f->c->out, " to %s\n", llvm_ty(dst));
      return (Value){.type = dst, .kind = V_SSA_TEMP, .v.id = t};
    }
    if (v.type->kind == TY_INT) {
      if (dst->bits == v.type->bits) {
        v.type = dst;
        return v;
      }
      int t = new_temp(f);
      const char* op =
          (dst->bits > v.type->bits) ? (v.type->is_signed ? "sext" : "zext") : "trunc";
      fprintf(f->c->out, "  ");
      emit_ssa(f->c->out, 't', t);
      fprintf(f->c->out, " = %s %s ", op, llvm_ty(v.type));
      emit_value(f->c->out, v);
      fprintf(f->c->out, " to %s\n", llvm_ty(dst));
      return (Value){.type = dst, .kind = V_SSA_TEMP, .v.id = t};
    }
    if (v.type->kind == TY_FLOAT) {
      int t = new_temp(f);
      fprintf(f->c->out, "  ");
      emit_ssa(f->c->out, 't', t);
      fprintf(f->c->out, " = %s %s ", dst->is_signed ? "fptosi" : "fptoui", llvm_ty(v.type));
      emit_value(f->c->out, v);
      fprintf(f->c->out, " to %s\n", llvm_ty(dst));
      return (Value){.type = dst, .kind = V_SSA_TEMP, .v.id = t};
    }
    error_generic(f, "type mismatch: cannot cast `%s` to `%s`", llvm_ty(v.type), llvm_ty(dst));
    return (Value){.type = dst, .kind = V_CONST_INT, .v.u = 0};
  }

  // Float casts.
  if (dst->kind == TY_FLOAT) {
    if (v.type->kind == TY_FLOAT) {
      if (dst->bits == v.type->bits) {
        v.type = dst;
        return v;
      }
      int t = new_temp(f);
      fprintf(f->c->out, "  ");
      emit_ssa(f->c->out, 't', t);
      fprintf(f->c->out, " = %s %s ", (dst->bits > v.type->bits) ? "fpext" : "fptrunc", llvm_ty(v.type));
      emit_value(f->c->out, v);
      fprintf(f->c->out, " to %s\n", llvm_ty(dst));
      return (Value){.type = dst, .kind = V_SSA_TEMP, .v.id = t};
    }
    if (v.type->kind == TY_INT) {
      int t = new_temp(f);
      fprintf(f->c->out, "  ");
      emit_ssa(f->c->out, 't', t);
      fprintf(f->c->out, " = %sitofp %s ", v.type->is_signed ? "s" : "u", llvm_ty(v.type));
      emit_value(f->c->out, v);
      fprintf(f->c->out, " to %s\n", llvm_ty(dst));
      return (Value){.type = dst, .kind = V_SSA_TEMP, .v.id = t};
    }
    if (v.type->kind == TY_BOOL) {
      Value iv = cast_to(f, ty_u8(), v);
      return cast_to(f, dst, iv);
    }
    error_generic(f, "type mismatch: cannot cast `%s` to `%s`", llvm_ty(v.type), llvm_ty(dst));
    return (Value){.type = dst, .kind = V_CONST_FLOAT, .v.ftxt = {ZERO_F64, 3}};
  }

  error_generic(f, "type mismatch: cannot cast `%s` to `%s`", llvm_ty(v.type), llvm_ty(dst));
  return (Value){.type = dst, .kind = V_CONST_INT, .v.u = 0};
}

static Local* find_local(FuncCtx* f, const char* name, size_t name_len) {
  for (size_t i = 0; i < f->nlocals; i++) {
    if (f->locals[i].name_len == name_len && memcmp(f->locals[i].name, name, name_len) == 0) return &f->locals[i];
  }
  return NULL;
}

static int find_param(FuncDef* fn, const char* name, size_t name_len) {
  for (size_t i = 0; i < fn->param_count; i++) {
    if (fn->params[i].name_len == name_len && memcmp(fn->params[i].name, name, name_len) == 0) return (int)i;
  }
  return -1;
}

static Field* struct_field(StructDef* s, const char* name, size_t name_len) {
  for (size_t i = 0; i < s->field_count; i++) {
    if (s->fields[i].name_len == name_len && memcmp(s->fields[i].name, name, name_len) == 0) return &s->fields[i];
  }
  return NULL;
}

static void emit_struct_copy(FuncCtx* f, Value dst_lv, Value src_lv) {
  Compiler* c = f->c;
  if (!dst_lv.is_lvalue || !src_lv.is_lvalue) {
    error_generic(f, "unsupported struct copy (non-lvalue)");
    return;
  }
  if (dst_lv.type->kind != TY_STRUCT || src_lv.type->kind != TY_STRUCT || !dst_lv.type->sdef || !src_lv.type->sdef) {
    error_generic(f, "unsupported struct copy (non-struct)");
    return;
  }
  if (dst_lv.type->sdef->size != src_lv.type->sdef->size) {
    error_generic(f, "unsupported struct copy (size mismatch)");
    return;
  }

  // Use libc memcpy for a simple by-value copy of the struct bytes.
  fprintf(c->out, "  call ptr @memcpy(ptr ");
  Value dptr = dst_lv;
  dptr.is_lvalue = false;
  emit_value(c->out, dptr);
  fprintf(c->out, ", ptr ");
  Value sptr = src_lv;
  sptr.is_lvalue = false;
  emit_value(c->out, sptr);
  fprintf(c->out, ", i64 %zu)\n", dst_lv.type->sdef->size);
}

// Forward declarations for expression parsing.
static Value parse_expr(FuncCtx* f, size_t* io_i, int min_prec);
static Value parse_addressable(FuncCtx* f, size_t* io_i);
static Value parse_assignable(FuncCtx* f, size_t* io_i);

static int tok_prec(uint32_t kind) {
  switch (kind) {
    case TOK_KW_OR: return 1;
    case TOK_KW_AND: return 2;
    case TOK_EQEQ:
    case TOK_NEQ:
    case TOK_KW_IS: return 3;
    case TOK_LT:
    case TOK_LTE:
    case TOK_GT:
    case TOK_GTE: return 4;
    case TOK_BAR: return 5;
    case TOK_CARET: return 6;
    case TOK_AMP: return 7;
    case TOK_SHL:
    case TOK_SHR: return 8;
    case TOK_PLUS:
    case TOK_MINUS: return 9;
    case TOK_STAR:
    case TOK_SLASH: return 10;
    default: return 0;
  }
}

static Value parse_primary(FuncCtx* f, size_t* io_i) {
  Compiler* c = f->c;
  size_t i = *io_i;
  AsterTok* t = &c->toks[i];
  if (t->kind == TOK_INT) {
    uint64_t v = parse_uint_lit(tok_ptr(c, t), tok_len(t));
    *io_i = i + 1;
    return (Value){.type = ty_i64(), .kind = V_CONST_INT, .v.u = v};
  }
  if (t->kind == TOK_FLOAT) {
    *io_i = i + 1;
    return (Value){.type = ty_f64(), .kind = V_CONST_FLOAT, .v.ftxt = {tok_ptr(c, t), tok_len(t)}};
  }
  if (t->kind == TOK_STRING) {
    const char* sp = tok_ptr(c, t);
    size_t slen = tok_len(t);
    uint8_t* bytes = NULL;
    size_t blen = 0;
    if (!unescape_string(sp, slen, &bytes, &blen)) {
      error_at_tok(c, t, "invalid string literal");
      *io_i = i + 1;
      return (Value){.type = ptr_to(c, ty_u8(), true), .kind = V_NULL};
    }
    StrConst* sc = new_str_const(c, bytes, blen);
    free(bytes);
    int tmp = new_temp(f);
    fprintf(c->out, "  ");
    emit_ssa(c->out, 't', tmp);
    fprintf(c->out, " = getelementptr inbounds [%zu x i8], ptr @.str%zu, i64 0, i64 0\n", sc->len, sc->id);
    *io_i = i + 1;
    return (Value){.type = ptr_to(c, ty_u8(), true), .kind = V_SSA_TEMP, .v.id = tmp};
  }
  if (t->kind == TOK_CHAR) {
    const char* cp = tok_ptr(c, t);
    size_t clen = tok_len(t);
    uint8_t b = 0;
    if (!unescape_char_lit(cp, clen, &b)) {
      error_at_tok(c, t, "invalid char literal");
      *io_i = i + 1;
      return (Value){.type = ty_u8(), .kind = V_CONST_INT, .v.u = 0};
    }
    *io_i = i + 1;
    return (Value){.type = ty_u8(), .kind = V_CONST_INT, .v.u = (uint64_t)b};
  }
  if (t->kind == TOK_KW_NULL) {
    *io_i = i + 1;
    return (Value){.type = ptr_to(c, ty_void(), false), .kind = V_NULL};
  }
  if (t->kind == TOK_KW_TRUE || t->kind == TOK_KW_FALSE) {
    *io_i = i + 1;
    return (Value){.type = ty_bool(), .kind = V_CONST_INT, .v.u = (t->kind == TOK_KW_TRUE) ? 1 : 0};
  }
  if (t->kind == TOK_LPAREN) {
    i++;
    Value v = parse_expr(f, &i, 1);
    if (c->toks[i].kind == TOK_RPAREN) i++;
    *io_i = i;
    return v;
  }
  if (t->kind == TOK_IDENT) {
    const char* name = tok_ptr(c, t);
    size_t name_len = tok_len(t);
    *io_i = i + 1;
    Local* loc = find_local(f, name, name_len);
    if (loc) {
      return (Value){.type = loc->type, .is_lvalue = true, .is_assignable = loc->is_mut, .kind = V_SSA_LOCAL, .v.id = (int)loc->slot};
    }
    int pidx = find_param(f->f, name, name_len);
    if (pidx >= 0) {
      return (Value){.type = f->f->params[pidx].type, .kind = V_SSA_PARAM, .v.id = pidx};
    }
    uint32_t cur_mod = f->f ? f->f->module_id : c->entry_mod;

    // Const resolution: current module, then direct imports.
    ConstDef* k = find_const_in_mod(c, cur_mod, name, name_len);
    if (!k && c->mods && cur_mod < c->nfile_mods) {
      ModInfo* m = &c->mods[cur_mod];
      for (size_t ui = 0; ui < m->nuse_ids; ui++) {
        uint32_t imp = m->use_ids[ui];
        ConstDef* kk = find_const_in_mod(c, imp, name, name_len);
        if (!kk) continue;
        if (k && kk != k) {
          error_at_tok(c, t, "ambiguous identifier (const) across imported modules");
          return (Value){.type = ty_i32(), .kind = V_CONST_INT, .v.u = 0};
        }
        k = kk;
      }
    }
    if (k) {
      if (k->kind == CONST_INT) return (Value){.type = k->type, .kind = V_CONST_INT, .v.u = k->v.u};
      if (k->kind == CONST_FLOAT) return (Value){.type = k->type, .kind = V_CONST_FLOAT, .v.ftxt = {k->v.ftxt.text, k->v.ftxt.len}};
      if (k->kind == CONST_STRING) {
        int tmp = new_temp(f);
        fprintf(c->out, "  ");
        emit_ssa(c->out, 't', tmp);
        fprintf(c->out, " = getelementptr inbounds [%zu x i8], ptr @.str%zu, i64 0, i64 0\n", k->v.str->len, k->v.str->id);
        return (Value){.type = ptr_to(c, ty_u8(), true), .kind = V_SSA_TEMP, .v.id = tmp};
      }
    }

    // Func resolution: current module, then direct imports.
    FuncDef* fn = find_func_in_mod(c, cur_mod, name, name_len);
    if (!fn && c->mods && cur_mod < c->nfile_mods) {
      ModInfo* m = &c->mods[cur_mod];
      for (size_t ui = 0; ui < m->nuse_ids; ui++) {
        uint32_t imp = m->use_ids[ui];
        FuncDef* ff = find_func_in_mod(c, imp, name, name_len);
        if (!ff) continue;
        if (fn && ff != fn) {
          error_at_tok(c, t, "ambiguous identifier (func) across imported modules");
          return (Value){.type = ty_i32(), .kind = V_CONST_INT, .v.u = 0};
        }
        fn = ff;
      }
    }
    if (!fn && str_eq(name, name_len, "calloc")) {
      static FuncDef calloc_fn = {.id = (size_t)-1, .name = "calloc", .name_len = 6, .param_count = 2, .is_extern = true};
      fn = &calloc_fn;
    } else if (!fn && str_eq(name, name_len, "memcpy")) {
      static FuncDef memcpy_fn = {.id = (size_t)-1, .name = "memcpy", .name_len = 6, .param_count = 3, .is_extern = true};
      fn = &memcpy_fn;
    }
    if (fn) return (Value){.kind = V_FUNC, .v.fn = fn};

    Type* bty = NULL;
    uint64_t bu = 0;
    if (builtin_const(name, name_len, &bty, &bu)) {
      return (Value){.type = bty, .kind = V_CONST_INT, .v.u = bu};
    }

    // Module root qualification: allow `core.io.println` etc when `core.*`
    // is imported via a `use` preamble.
    if (c->mods && cur_mod < c->nfile_mods) {
      ModInfo* m = &c->mods[cur_mod];
      for (size_t ui = 0; ui < m->nuse_ids; ui++) {
        uint32_t imp = m->use_ids[ui];
        const char* imp_name = c->mods[imp].name;
        size_t imp_len = c->mods[imp].name_len;
        size_t root_len = 0;
        while (root_len < imp_len && imp_name[root_len] != '.') root_len++;
        if (root_len == name_len && memcmp(imp_name, name, name_len) == 0) {
          ssize_t mid = mod_find_by_name(c, name, name_len, false);
          if (mid >= 0) return (Value){.kind = V_MODULE, .v.mod = (uint32_t)mid};
        }
      }
    }

    error_at_tok(c, t, "unknown identifier");
    return (Value){.type = ty_i32(), .kind = V_CONST_INT, .v.u = 0};
  }
  *io_i = i + 1;
  return (Value){.type = ty_i32(), .kind = V_CONST_INT, .v.u = 0};
}

static Value parse_postfix(FuncCtx* f, size_t* io_i, Value base) {
  Compiler* c = f->c;
  size_t i = *io_i;
  for (;;) {
    uint32_t k = c->toks[i].kind;
    if (k == TOK_LPAREN) {
      // call
      if (base.kind != V_FUNC) break;
      size_t call_i = i;
      i++; // '('
      Value args[32];
      size_t nargs = 0;
      if (c->toks[i].kind != TOK_RPAREN) {
        for (;;) {
          Value a = parse_expr(f, &i, 1);
          if (nargs >= 32) {
            error_at_tok(c, &c->toks[call_i], "too many call arguments");
            break;
          }
          args[nargs++] = load_if_needed(f, a);
          if (c->toks[i].kind == TOK_COMMA) {
            i++;
            continue;
          }
          break;
        }
      }
      if (c->toks[i].kind == TOK_RPAREN) i++;

      FuncDef* fn = base.v.fn;
      // Record call graph edges for `noalloc` analysis.
      if (is_known_alloc_fn(fn->name, fn->name_len)) {
        f->f->direct_alloc = true;
      } else if (fn->id != (size_t)-1) {
        record_call(f->f, fn);
      }
      Type* ret = fn->ret ? fn->ret : ty_void();
      if (!fn->ret && str_eq(fn->name, fn->name_len, "calloc")) ret = ptr_to(c, ty_void(), true);
      if (!fn->ret && str_eq(fn->name, fn->name_len, "memcpy")) ret = ptr_to(c, ty_void(), true);

      // Arity checks.
      if (fn->is_varargs) {
        size_t min_args = fn->param_count;
        if (str_eq(fn->name, fn->name_len, "printf")) min_args = 1;
        if (nargs < min_args) {
          error_at_tok(c, &c->toks[call_i], "call arity mismatch: expected at least %zu args, got %zu", min_args, nargs);
          if (ret->kind == TY_PTR) base = (Value){.type = ret, .kind = V_NULL};
          else if (ret->kind == TY_FLOAT) base = (Value){.type = ret, .kind = V_CONST_FLOAT, .v.ftxt = {"0.0", 3}};
          else base = (Value){.type = ret, .kind = V_CONST_INT, .v.u = 0};
          base.is_lvalue = false;
          continue;
        }
      } else {
        if (nargs != fn->param_count) {
          error_at_tok(c, &c->toks[call_i], "call arity mismatch: expected %zu args, got %zu", fn->param_count, nargs);
          if (ret->kind == TY_PTR) base = (Value){.type = ret, .kind = V_NULL};
          else if (ret->kind == TY_FLOAT) base = (Value){.type = ret, .kind = V_CONST_FLOAT, .v.ftxt = {"0.0", 3}};
          else base = (Value){.type = ret, .kind = V_CONST_INT, .v.u = 0};
          base.is_lvalue = false;
          continue;
        }
      }

      // cast fixed args to declared signature (or builtin signature)
      if (fn->params && fn->param_count) {
        for (size_t ai = 0; ai < nargs && ai < fn->param_count; ai++) {
          args[ai] = cast_to(f, fn->params[ai].type, args[ai]);
        }
      } else if (str_eq(fn->name, fn->name_len, "calloc")) {
        if (nargs >= 1) args[0] = cast_to(f, ty_i64(), args[0]);
        if (nargs >= 2) args[1] = cast_to(f, ty_i64(), args[1]);
      } else if (str_eq(fn->name, fn->name_len, "memcpy")) {
        if (nargs >= 1) args[0] = cast_to(f, ptr_to(c, ty_void(), true), args[0]);  // dst
        if (nargs >= 2) args[1] = cast_to(f, ptr_to(c, ty_void(), false), args[1]); // src
        if (nargs >= 3) args[2] = cast_to(f, ty_i64(), args[2]);
      }

      int t = -1;
      if (ret->kind != TY_VOID) t = new_temp(f);
      fprintf(c->out, "  ");
      if (t >= 0) {
        emit_ssa(c->out, 't', t);
        fprintf(c->out, " = ");
      }
      if (fn->is_varargs) {
        fprintf(c->out, "call %s (", llvm_ty(ret));
        if (str_eq(fn->name, fn->name_len, "printf")) {
          fprintf(c->out, "ptr, ...");
        } else {
          for (size_t pi = 0; pi < fn->param_count; pi++) {
            if (pi) fprintf(c->out, ", ");
            fprintf(c->out, "%s", llvm_ty(fn->params[pi].type));
          }
          if (fn->param_count) fprintf(c->out, ", ");
          fprintf(c->out, "...");
        }
        const char* irn = fn->ir_name ? fn->ir_name : fn->name;
        size_t irn_len = fn->ir_name ? fn->ir_name_len : fn->name_len;
        fprintf(c->out, ") @%.*s(", (int)irn_len, irn);
      } else {
        const char* irn = fn->ir_name ? fn->ir_name : fn->name;
        size_t irn_len = fn->ir_name ? fn->ir_name_len : fn->name_len;
        fprintf(c->out, "call %s @%.*s(", llvm_ty(ret), (int)irn_len, irn);
      }
      for (size_t ai = 0; ai < nargs; ai++) {
        if (ai) fprintf(c->out, ", ");
        fprintf(c->out, "%s ", llvm_ty(args[ai].type));
        emit_value(c->out, args[ai]);
      }
      fprintf(c->out, ")\n");
      if (t >= 0) base = (Value){.type = ret, .kind = V_SSA_TEMP, .v.id = t};
      else base = (Value){.type = ret, .kind = V_CONST_INT, .v.u = 0};
      base.is_lvalue = false;
      continue;
    }
    if (k == TOK_LBRACK) {
      // index
      size_t lb_i = i;
      i++; // '['
      Value idxv = parse_expr(f, &i, 1);
      idxv = cast_to(f, ty_i64(), idxv);
      if (c->toks[i].kind == TOK_RBRACK) i++;
      if (!base.type || base.type->kind != TY_PTR) {
        error_at_tok(c, &c->toks[lb_i], "indexing requires pointer/slice type");
        base = (Value){.type = ty_i32(), .kind = V_CONST_INT, .v.u = 0};
        continue;
      }
      bool elem_mut = base.type->is_mut;
      Type* elem = base.type->pointee ? base.type->pointee : ty_u8();
      Value ptr = load_if_needed(f, base);
      // Fast-path: `p[0]` is just `*p` (no GEP needed).
      if (idxv.kind == V_CONST_INT && idxv.v.u == 0) {
        base = (Value){.type = elem, .is_lvalue = true, .is_assignable = elem_mut, .kind = ptr.kind, .v = ptr.v};
        continue;
      }
      if (elem->kind == TY_STRUCT && elem->sdef) {
        // Struct elements are byte-addressed in this MVP. Use i8 GEP with
        // explicit scaling by struct size, otherwise we'd incorrectly scale by
        // pointer size (because llvm_ty(TY_STRUCT) == "ptr").
        int ts = new_temp(f);
        fprintf(c->out, "  ");
        emit_ssa(c->out, 't', ts);
        fprintf(c->out, " = mul i64 ");
        emit_value(c->out, idxv);
        fprintf(c->out, ", %zu\n", elem->sdef->size);

        int t = new_temp(f);
        fprintf(c->out, "  ");
        emit_ssa(c->out, 't', t);
        fprintf(c->out, " = getelementptr inbounds i8, ptr ");
        emit_value(c->out, ptr);
        fprintf(c->out, ", i64 ");
        emit_ssa(c->out, 't', ts);
        fprintf(c->out, "\n");
        base = (Value){.type = elem, .is_lvalue = true, .is_assignable = elem_mut, .kind = V_SSA_TEMP, .v.id = t};
        continue;
      }
      int t = new_temp(f);
      fprintf(c->out, "  ");
      emit_ssa(c->out, 't', t);
      fprintf(c->out, " = getelementptr inbounds %s, ptr ", llvm_ty(elem));
      emit_value(c->out, ptr);
      fprintf(c->out, ", i64 ");
      emit_value(c->out, idxv);
      fprintf(c->out, "\n");
      base = (Value){.type = elem, .is_lvalue = true, .is_assignable = elem_mut, .kind = V_SSA_TEMP, .v.id = t};
      continue;
    }
    if (k == TOK_DOT) {
      size_t dot_i = i;
      i++;
      if (c->toks[i].kind != TOK_IDENT) {
        error_at_tok(c, &c->toks[dot_i], "expected field name after `.`");
        base = (Value){.type = ty_i32(), .kind = V_CONST_INT, .v.u = 0};
        continue;
      }
      const char* fname = tok_ptr(c, &c->toks[i]);
      size_t fname_len = tok_len(&c->toks[i]);
      i++;

      // Qualified module access: `core.io.println`, etc.
      if (base.kind == V_MODULE) {
        uint32_t bm = base.v.mod;
        if (!c->mods || bm >= c->nmods || !c->mods[bm].name) {
          error_at_tok(c, &c->toks[dot_i], "internal: invalid module value");
          base = (Value){.type = ty_i32(), .kind = V_CONST_INT, .v.u = 0};
          continue;
        }
        const char* bname = c->mods[bm].name;
        size_t bname_len = c->mods[bm].name_len;

        // First, try submodule lookup: "<base>.<segment>".
        size_t full_len = bname_len + 1 + fname_len;
        char* full = (char*)xmalloc(full_len + 1);
        memcpy(full, bname, bname_len);
        full[bname_len] = '.';
        memcpy(full + bname_len + 1, fname, fname_len);
        full[full_len] = 0;
        ssize_t mid = mod_find_by_name(c, full, full_len, false);
        free(full);
        if (mid >= 0) {
          base = (Value){.kind = V_MODULE, .v.mod = (uint32_t)mid};
          continue;
        }

        // Otherwise, resolve a symbol within the module.
        ConstDef* ck = find_const_in_mod(c, bm, fname, fname_len);
        if (ck) {
          if (ck->kind == CONST_INT) {
            base = (Value){.type = ck->type, .kind = V_CONST_INT, .v.u = ck->v.u};
          } else if (ck->kind == CONST_FLOAT) {
            base = (Value){.type = ck->type, .kind = V_CONST_FLOAT, .v.ftxt = {ck->v.ftxt.text, ck->v.ftxt.len}};
          } else if (ck->kind == CONST_STRING) {
            int tmp = new_temp(f);
            fprintf(c->out, "  ");
            emit_ssa(c->out, 't', tmp);
            fprintf(c->out, " = getelementptr inbounds [%zu x i8], ptr @.str%zu, i64 0, i64 0\n", ck->v.str->len, ck->v.str->id);
            base = (Value){.type = ptr_to(c, ty_u8(), true), .kind = V_SSA_TEMP, .v.id = tmp};
          } else {
            base = (Value){.type = ty_i32(), .kind = V_CONST_INT, .v.u = 0};
          }
          base.is_lvalue = false;
          continue;
        }
        FuncDef* ff = find_func_in_mod(c, bm, fname, fname_len);
        if (ff) {
          base = (Value){.kind = V_FUNC, .v.fn = ff};
          base.is_lvalue = false;
          continue;
        }

        error_at_tok(c, &c->toks[dot_i], "unknown module member");
        base = (Value){.type = ty_i32(), .kind = V_CONST_INT, .v.u = 0};
        continue;
      }

      if (!base.is_lvalue || !base.type || base.type->kind != TY_STRUCT || !base.type->sdef) {
        error_at_tok(c, &c->toks[dot_i], "field access requires struct lvalue");
        base = (Value){.type = ty_i32(), .kind = V_CONST_INT, .v.u = 0};
        continue;
      }
      Field* fld = struct_field(base.type->sdef, fname, fname_len);
      if (!fld) {
        error_at_tok(c, &c->toks[dot_i], "unknown struct field");
        base = (Value){.type = ty_i32(), .kind = V_CONST_INT, .v.u = 0};
        continue;
      }
      int t = new_temp(f);
      fprintf(c->out, "  ");
      emit_ssa(c->out, 't', t);
      fprintf(c->out, " = getelementptr inbounds i8, ptr ");
      Value ptr = base;
      ptr.is_lvalue = false;
      emit_value(c->out, ptr);
      fprintf(c->out, ", i64 %zu\n", fld->offset);
      base = (Value){.type = fld->type, .is_lvalue = true, .is_assignable = base.is_assignable, .kind = V_SSA_TEMP, .v.id = t};
      continue;
    }
    break;
  }
  *io_i = i;
  return base;
}

static Value parse_unary(FuncCtx* f, size_t* io_i) {
  Compiler* c = f->c;
  size_t i = *io_i;
  uint32_t k = c->toks[i].kind;
  if (k == TOK_MINUS) {
    i++;
    Value v = parse_unary(f, &i);
    v = load_if_needed(f, v);
    int t = new_temp(f);
    fprintf(c->out, "  ");
    emit_ssa(c->out, 't', t);
    if (v.type->kind == TY_FLOAT) {
      // Match clang's default `-ffp-contract=on` behavior by allowing
      // contraction (e.g. fmul+fadd -> fma) without enabling full fast-math.
      fprintf(c->out, " = fneg contract %s ", llvm_ty(v.type));
      emit_value(c->out, v);
      fprintf(c->out, "\n");
      *io_i = i;
      return (Value){.type = v.type, .kind = V_SSA_TEMP, .v.id = t};
    }
    fprintf(c->out, " = sub %s 0, ", llvm_ty(v.type));
    emit_value(c->out, v);
    fprintf(c->out, "\n");
    *io_i = i;
    return (Value){.type = v.type, .kind = V_SSA_TEMP, .v.id = t};
  }
  if (k == TOK_AMP) {
    i++;
    Value lv = parse_addressable(f, &i);
    // address-of yields pointer rvalue
    *io_i = i;
    return (Value){.type = ptr_to(c, lv.type, lv.is_assignable), .kind = lv.kind, .v = lv.v};
  }
  if (k == TOK_STAR) {
    i++;
    Value pv = parse_unary(f, &i);
    pv = load_if_needed(f, pv);
    if (!pv.type || pv.type->kind != TY_PTR) {
      error_at_tok(c, (i < c->ntoks) ? &c->toks[i - 1] : NULL, "dereference requires pointer type");
      *io_i = i;
      return (Value){.type = ty_i32(), .kind = V_CONST_INT, .v.u = 0};
    }
    Type* elem = pv.type->pointee ? pv.type->pointee : ty_u8();
    *io_i = i;
    return (Value){.type = elem, .is_lvalue = true, .is_assignable = pv.type->is_mut, .kind = pv.kind, .v = pv.v};
  }
  if (k == TOK_KW_NOT) {
    i++;
    Value v = parse_unary(f, &i);
    v = cast_to(f, ty_bool(), v);
    int t = new_temp(f);
    fprintf(c->out, "  ");
    emit_ssa(c->out, 't', t);
    fprintf(c->out, " = xor i1 ");
    emit_value(c->out, v);
    fprintf(c->out, ", true\n");
    *io_i = i;
    return (Value){.type = ty_bool(), .kind = V_SSA_TEMP, .v.id = t};
  }
  Value base = parse_primary(f, &i);
  base = parse_postfix(f, &i, base);
  *io_i = i;
  return base;
}

static Value emit_binop(FuncCtx* f, uint32_t op, Value a, Value b) {
  Compiler* c = f->c;
  a = load_if_needed(f, a);
  b = load_if_needed(f, b);

  // pointer comparisons
  if ((op == TOK_EQEQ || op == TOK_NEQ || op == TOK_KW_IS) && a.type->kind == TY_PTR && b.type->kind == TY_PTR) {
    int t = new_temp(f);
    fprintf(c->out, "  ");
    emit_ssa(c->out, 't', t);
    fprintf(c->out, " = icmp %s ptr ", (op == TOK_NEQ) ? "ne" : "eq");
    emit_value(c->out, a);
    fprintf(c->out, ", ");
    emit_value(c->out, b);
    fprintf(c->out, "\n");
    return (Value){.type = ty_bool(), .kind = V_SSA_TEMP, .v.id = t};
  }

  bool floaty = (a.type->kind == TY_FLOAT) || (b.type->kind == TY_FLOAT);
  if (floaty) {
    Type* dst = ty_f32();
    if ((a.type->kind == TY_FLOAT && a.type->bits == 64) || (b.type->kind == TY_FLOAT && b.type->bits == 64)) dst = ty_f64();
    a = cast_to(f, dst, a);
    b = cast_to(f, dst, b);
  } else if (a.type->kind == TY_INT && b.type->kind == TY_INT) {
    // widen to max bits
    Type* dst = (a.type->bits >= b.type->bits) ? a.type : b.type;
    a = cast_to(f, dst, a);
    b = cast_to(f, dst, b);
  }

  const char* aty = llvm_ty(a.type);

  if (op == TOK_PLUS || op == TOK_MINUS || op == TOK_STAR || op == TOK_SLASH) {
    // Pointer difference: ptr - ptr -> isize (ptrdiff_t), in units of the pointee type.
    if (op == TOK_MINUS && a.type->kind == TY_PTR && b.type->kind == TY_PTR) {
      Type* aelem = a.type->pointee ? a.type->pointee : ty_u8();
      Type* belem = b.type->pointee ? b.type->pointee : ty_u8();
      if (aelem != belem) {
        error_generic(f, "pointer subtraction requires matching element types");
        return (Value){.type = ty_isize(), .kind = V_CONST_INT, .v.u = 0};
      }
      size_t elem_sz = ty_size(aelem);
      if (elem_sz == 0) elem_sz = 1;

      Value ap = load_if_needed(f, a);
      Value bp = load_if_needed(f, b);

      int ta = new_temp(f);
      fprintf(c->out, "  ");
      emit_ssa(c->out, 't', ta);
      fprintf(c->out, " = ptrtoint ptr ");
      emit_value(c->out, ap);
      fprintf(c->out, " to i64\n");

      int tb = new_temp(f);
      fprintf(c->out, "  ");
      emit_ssa(c->out, 't', tb);
      fprintf(c->out, " = ptrtoint ptr ");
      emit_value(c->out, bp);
      fprintf(c->out, " to i64\n");

      int td = new_temp(f);
      fprintf(c->out, "  ");
      emit_ssa(c->out, 't', td);
      fprintf(c->out, " = sub i64 ");
      emit_ssa(c->out, 't', ta);
      fprintf(c->out, ", ");
      emit_ssa(c->out, 't', tb);
      fprintf(c->out, "\n");

      if (elem_sz == 1) {
        return (Value){.type = ty_isize(), .kind = V_SSA_TEMP, .v.id = td};
      }

      int te = new_temp(f);
      fprintf(c->out, "  ");
      emit_ssa(c->out, 't', te);
      fprintf(c->out, " = sdiv i64 ");
      emit_ssa(c->out, 't', td);
      fprintf(c->out, ", %zu\n", elem_sz);
      return (Value){.type = ty_isize(), .kind = V_SSA_TEMP, .v.id = te};
    }

    if (a.type->kind == TY_PTR && b.type->kind == TY_INT && (op == TOK_PLUS || op == TOK_MINUS)) {
      Type* elem = a.type->pointee ? a.type->pointee : ty_u8();
      Value idx = cast_to(f, ty_i64(), b);
      if (op == TOK_MINUS) {
        // ptr - n == ptr + (-n)
        idx = load_if_needed(f, idx);
        int nt = new_temp(f);
        fprintf(c->out, "  ");
        emit_ssa(c->out, 't', nt);
        fprintf(c->out, " = sub i64 0, ");
        emit_value(c->out, idx);
        fprintf(c->out, "\n");
        idx = (Value){.type = ty_i64(), .kind = V_SSA_TEMP, .v.id = nt};
      }
      int t = new_temp(f);
      fprintf(c->out, "  ");
      emit_ssa(c->out, 't', t);
      fprintf(c->out, " = getelementptr inbounds %s, ptr ", llvm_ty(elem));
      emit_value(c->out, a);
      fprintf(c->out, ", i64 ");
      emit_value(c->out, idx);
      fprintf(c->out, "\n");
      return (Value){.type = a.type, .kind = V_SSA_TEMP, .v.id = t};
    }
    const char* opstr = NULL;
    if (a.type->kind == TY_FLOAT) {
      opstr = (op == TOK_PLUS) ? "fadd" : (op == TOK_MINUS) ? "fsub" : (op == TOK_STAR) ? "fmul" : "fdiv";
    } else {
      opstr = (op == TOK_PLUS) ? "add" : (op == TOK_MINUS) ? "sub" : (op == TOK_STAR) ? "mul" : (a.type->is_signed ? "sdiv" : "udiv");
    }
    int t = new_temp(f);
    fprintf(c->out, "  ");
    emit_ssa(c->out, 't', t);
    if (a.type->kind == TY_FLOAT) {
      fprintf(c->out, " = %s contract %s ", opstr, aty);
    } else {
      fprintf(c->out, " = %s %s ", opstr, aty);
    }
    emit_value(c->out, a);
    fprintf(c->out, ", ");
    emit_value(c->out, b);
    fprintf(c->out, "\n");
    return (Value){.type = a.type, .kind = V_SSA_TEMP, .v.id = t};
  }

  if (op == TOK_SHL || op == TOK_SHR) {
    const char* opstr = (op == TOK_SHL) ? "shl" : (a.type->is_signed ? "ashr" : "lshr");
    int t = new_temp(f);
    fprintf(c->out, "  ");
    emit_ssa(c->out, 't', t);
    fprintf(c->out, " = %s %s ", opstr, aty);
    emit_value(c->out, a);
    fprintf(c->out, ", ");
    b = cast_to(f, a.type, b);
    emit_value(c->out, b);
    fprintf(c->out, "\n");
    return (Value){.type = a.type, .kind = V_SSA_TEMP, .v.id = t};
  }

  if (op == TOK_AMP || op == TOK_BAR || op == TOK_CARET) {
    const char* opstr = (op == TOK_AMP) ? "and" : (op == TOK_BAR) ? "or" : "xor";
    int t = new_temp(f);
    fprintf(c->out, "  ");
    emit_ssa(c->out, 't', t);
    fprintf(c->out, " = %s %s ", opstr, aty);
    emit_value(c->out, a);
    fprintf(c->out, ", ");
    emit_value(c->out, b);
    fprintf(c->out, "\n");
    return (Value){.type = a.type, .kind = V_SSA_TEMP, .v.id = t};
  }

  // comparisons
  if (op == TOK_LT || op == TOK_LTE || op == TOK_GT || op == TOK_GTE || op == TOK_EQEQ || op == TOK_NEQ || op == TOK_KW_IS) {
    int t = new_temp(f);
    fprintf(c->out, "  ");
    emit_ssa(c->out, 't', t);
    const char* pred = "eq";
    if (op == TOK_EQEQ || op == TOK_KW_IS) pred = "eq";
    else if (op == TOK_NEQ) pred = "ne";
    else if (op == TOK_LT) pred = a.type->is_signed ? "slt" : "ult";
    else if (op == TOK_LTE) pred = a.type->is_signed ? "sle" : "ule";
    else if (op == TOK_GT) pred = a.type->is_signed ? "sgt" : "ugt";
    else if (op == TOK_GTE) pred = a.type->is_signed ? "sge" : "uge";
    if (a.type->kind == TY_FLOAT) {
      // ordered comparisons
      const char* fpred = "oeq";
      if (op == TOK_EQEQ || op == TOK_KW_IS) fpred = "oeq";
      else if (op == TOK_NEQ) fpred = "one";
      else if (op == TOK_LT) fpred = "olt";
      else if (op == TOK_LTE) fpred = "ole";
      else if (op == TOK_GT) fpred = "ogt";
      else if (op == TOK_GTE) fpred = "oge";
      fprintf(c->out, " = fcmp %s %s ", fpred, aty);
    } else {
      fprintf(c->out, " = icmp %s %s ", pred, aty);
    }
    emit_value(c->out, a);
    fprintf(c->out, ", ");
    emit_value(c->out, b);
    fprintf(c->out, "\n");
    return (Value){.type = ty_bool(), .kind = V_SSA_TEMP, .v.id = t};
  }

  // boolean ops (non-short-circuit in value context)
  if (op == TOK_KW_AND || op == TOK_KW_OR) {
    a = cast_to(f, ty_bool(), a);
    b = cast_to(f, ty_bool(), b);
    int t = new_temp(f);
    fprintf(c->out, "  ");
    emit_ssa(c->out, 't', t);
    const char* opstr = (op == TOK_KW_AND) ? "and" : "or";
    fprintf(c->out, " = %s i1 ", opstr);
    emit_value(c->out, a);
    fprintf(c->out, ", ");
    emit_value(c->out, b);
    fprintf(c->out, "\n");
    return (Value){.type = ty_bool(), .kind = V_SSA_TEMP, .v.id = t};
  }

  // fallback
  {
    int t = new_temp(f);
    fprintf(c->out, "  ");
    emit_ssa(c->out, 't', t);
    fprintf(c->out, " = add %s 0, 0\n", aty);
    return (Value){.type = a.type, .kind = V_SSA_TEMP, .v.id = t};
  }
}

static Value parse_expr(FuncCtx* f, size_t* io_i, int min_prec) {
  Compiler* c = f->c;
  size_t i = *io_i;
  Value lhs = parse_unary(f, &i);
  for (;;) {
    uint32_t op = c->toks[i].kind;
    // handle `is not`
    if (op == TOK_KW_IS && c->toks[i + 1].kind == TOK_KW_NOT) {
      // treat as !=
      op = TOK_NEQ;
    }
    int prec = tok_prec(op);
    if (prec < min_prec || prec == 0) break;
    // consume operator tokens
    if (c->toks[i].kind == TOK_KW_IS && c->toks[i + 1].kind == TOK_KW_NOT) {
      i += 2;
    } else {
      i += 1;
    }
    Value rhs = parse_expr(f, &i, prec + 1);
    lhs = emit_binop(f, op, lhs, rhs);
  }
  *io_i = i;
  return lhs;
}

static Value parse_addressable(FuncCtx* f, size_t* io_i) {
  size_t i = *io_i;
  Value v = parse_unary(f, &i);
  if (!v.is_lvalue) {
    Compiler* c = f->c;
    error_at_tok(c, (*io_i < c->ntoks) ? &c->toks[*io_i] : NULL, "expected addressable lvalue");
    *io_i = i;
    return (Value){.type = ty_i32(), .kind = V_CONST_INT, .v.u = 0};
  }
  *io_i = i;
  return v;
}

static Value parse_assignable(FuncCtx* f, size_t* io_i) {
  size_t i = *io_i;
  Value v = parse_addressable(f, &i);
  if (!v.is_lvalue) {
    *io_i = i;
    return v;
  }
  if (!v.is_assignable) {
    Compiler* c = f->c;
    error_at_tok(c, (*io_i < c->ntoks) ? &c->toks[*io_i] : NULL, "expected mutable lvalue");
    *io_i = i;
    return (Value){.type = ty_i32(), .kind = V_CONST_INT, .v.u = 0};
  }
  *io_i = i;
  return v;
}

static bool line_has_assign_eq(const Compiler* c, size_t i, size_t end) {
  int par = 0, br = 0;
  for (size_t j = i; j < end && c->toks[j].kind != TOK_NEWLINE; j++) {
    uint32_t k = c->toks[j].kind;
    if (k == TOK_LPAREN) par++;
    else if (k == TOK_RPAREN) par--;
    else if (k == TOK_LBRACK) br++;
    else if (k == TOK_RBRACK) br--;
    else if (k == TOK_EQ && par == 0 && br == 0) return true;
  }
  return false;
}

// Short-circuit condition emission: parses until THEN/DO (caller decides).
static void emit_cond_or(FuncCtx* f, size_t* io_i, int true_bb, int false_bb);

static void emit_cond_atom(FuncCtx* f, size_t* io_i, int true_bb, int false_bb) {
  Compiler* c = f->c;
  size_t i = *io_i;
  Value v = parse_expr(f, &i, 3); // stop before AND/OR
  v = cast_to(f, ty_bool(), v);
  fprintf(c->out, "  br i1 ");
  emit_value(c->out, v);
  fprintf(c->out, ", label %%bb%d, label %%bb%d\n", true_bb, false_bb);
  f->terminated = true;
  *io_i = i;
}

static void emit_cond_not(FuncCtx* f, size_t* io_i, int true_bb, int false_bb) {
  Compiler* c = f->c;
  size_t i = *io_i;
  if (c->toks[i].kind == TOK_KW_NOT) {
    i++;
    emit_cond_not(f, &i, false_bb, true_bb);
    *io_i = i;
    return;
  }
  emit_cond_atom(f, &i, true_bb, false_bb);
  *io_i = i;
}

static void emit_cond_and(FuncCtx* f, size_t* io_i, int true_bb, int false_bb) {
  Compiler* c = f->c;
  size_t i = *io_i;
  int next_true = new_label(f);
  emit_cond_not(f, &i, next_true, false_bb);
  while (c->toks[i].kind == TOK_KW_AND) {
    emit_label(c->out, next_true);
    f->terminated = false;
    i++;
    next_true = new_label(f);
    emit_cond_not(f, &i, next_true, false_bb);
  }
  emit_label(c->out, next_true);
  f->terminated = false;
  fprintf(c->out, "  br label %%bb%d\n", true_bb);
  f->terminated = true;
  *io_i = i;
}

static void emit_cond_or(FuncCtx* f, size_t* io_i, int true_bb, int false_bb) {
  Compiler* c = f->c;
  size_t i = *io_i;
  int next_false = new_label(f);
  emit_cond_and(f, &i, true_bb, next_false);
  while (c->toks[i].kind == TOK_KW_OR) {
    emit_label(c->out, next_false);
    f->terminated = false;
    i++;
    next_false = new_label(f);
    emit_cond_and(f, &i, true_bb, next_false);
  }
  emit_label(c->out, next_false);
  f->terminated = false;
  fprintf(c->out, "  br label %%bb%d\n", false_bb);
  f->terminated = true;
  *io_i = i;
}

static bool scan_locals(FuncCtx* f, size_t start, size_t end) {
  Compiler* c = f->c;
  size_t i = start;
  while (i < end) {
    uint32_t k = c->toks[i].kind;
    if (k == TOK_KW_VAR || k == TOK_KW_LET) {
      size_t kw_i = i;
      i++;
      if (i >= end || c->toks[i].kind != TOK_IDENT) {
        error_at_tok(c, (kw_i < c->ntoks) ? &c->toks[kw_i] : NULL, "expected identifier after `var`/`let`");
        return false;
      }
      const char* name = tok_ptr(c, &c->toks[i]);
      size_t name_len = tok_len(&c->toks[i]);
      i++;
      Type* ty = NULL;
      if (i < end && c->toks[i].kind == TOK_KW_IS) {
        i++;
        ty = parse_type_at(c, &i);
        if (!ty) {
          error_at_tok(c, (i < c->ntoks) ? &c->toks[i] : &c->toks[c->ntoks - 1], "expected type");
          return false;
        }
      } else if (i < end && c->toks[i].kind == TOK_EQ) {
        // Type inference from initializer expression (post-MVP).
        i++; // consume '='
        FILE* saved_out = c->out;
        FILE* sink = tmpfile();
        if (!sink) sink = fopen("/dev/null", "w");
        c->out = sink ? sink : saved_out;
        FuncCtx tf = *f;
        tf.next_temp = 0;
        tf.next_label = 0;
        tf.loop_depth = 0;
        tf.terminated = false;
        Value rhs = parse_expr(&tf, &i, 1);
        if (sink) fclose(sink);
        c->out = saved_out;
        ty = rhs.type;
        if (!ty) {
          error_at_tok(c, &c->toks[kw_i], "failed to infer local type");
          return false;
        }
      } else {
        error_at_tok(c, &c->toks[i - 1], "expected `is <Type>` or `= <Expr>` after local name");
        return false;
      }
      // record
      if (!find_local(f, name, name_len)) {
        if (f->nlocals == f->caplocals) {
          f->caplocals = f->caplocals ? f->caplocals * 2 : 64;
          f->locals = (Local*)xrealloc(f->locals, f->caplocals * sizeof(Local));
        }
        size_t slot = f->nlocals;
        f->locals[slot] = (Local){.name = name, .name_len = name_len, .type = ty, .is_mut = (k == TOK_KW_VAR), .slot = slot};
        f->nlocals++;
      }
      continue;
    }
    i++;
  }
  return true;
}

static void compile_stmt_list(FuncCtx* f, size_t* io_i, size_t end);

static void compile_if(FuncCtx* f, size_t* io_i, size_t end) {
  Compiler* c = f->c;
  size_t i = *io_i;
  i++; // consume if
  int then_bb = new_label(f);
  int else_bb = new_label(f);
  int end_bb = new_label(f);

  emit_cond_or(f, &i, then_bb, else_bb);
  if (c->toks[i].kind == TOK_KW_THEN) i++;

  // then block
  if (c->toks[i].kind == TOK_NEWLINE) i++;
  if (c->toks[i].kind == TOK_INDENT) i++;
  emit_label(c->out, then_bb);
  f->terminated = false;
  compile_stmt_list(f, &i, end);
  if (c->toks[i].kind == TOK_DEDENT) i++;
  if (!f->terminated) {
    fprintf(c->out, "  br label %%bb%d\n", end_bb);
  }

  // else / else-if / no-else
  emit_label(c->out, else_bb);
  f->terminated = false;

  if (c->toks[i].kind == TOK_KW_ELSE) {
    i++;
    if (c->toks[i].kind == TOK_KW_IF) {
      // else if chain: compile nested if as a statement in this block
      compile_if(f, &i, end);
    } else {
      if (c->toks[i].kind == TOK_NEWLINE) i++;
      if (c->toks[i].kind == TOK_INDENT) i++;
      compile_stmt_list(f, &i, end);
      if (c->toks[i].kind == TOK_DEDENT) i++;
    }
  }
  if (!f->terminated) fprintf(c->out, "  br label %%bb%d\n", end_bb);

  emit_label(c->out, end_bb);
  f->terminated = false;
  *io_i = i;
}

static void compile_while(FuncCtx* f, size_t* io_i, size_t end) {
  Compiler* c = f->c;
  size_t i = *io_i;
  i++; // consume while
  // Detect `while 1 do` (hashmap uses this). We'll compile it as an infinite
  // loop with no fallthrough block, so a trailing `return` is not required.
  bool infinite = false;
  if (c->toks[i].kind == TOK_INT) {
    uint64_t v = parse_uint_lit(tok_ptr(c, &c->toks[i]), tok_len(&c->toks[i]));
    if (v == 1 && c->toks[i + 1].kind == TOK_KW_DO) infinite = true;
  }

  int cond_bb = new_label(f);
  int body_bb = new_label(f);
  int end_bb = infinite ? -1 : new_label(f);

  fprintf(c->out, "  br label %%bb%d\n", cond_bb);
  emit_label(c->out, cond_bb);
  f->terminated = false;
  if (infinite) {
    i++; // consume literal
    fprintf(c->out, "  br label %%bb%d\n", body_bb);
    f->terminated = true;
  } else {
    emit_cond_or(f, &i, body_bb, end_bb);
  }
  if (c->toks[i].kind == TOK_KW_DO) i++;
  if (c->toks[i].kind == TOK_NEWLINE) i++;
  if (c->toks[i].kind == TOK_INDENT) i++;

  emit_label(c->out, body_bb);
  f->terminated = false;
  // push loop context
  f->loop_cond[f->loop_depth] = cond_bb;
  f->loop_end[f->loop_depth] = (end_bb < 0) ? cond_bb : end_bb;
  f->loop_depth++;

  compile_stmt_list(f, &i, end);
  if (c->toks[i].kind == TOK_DEDENT) i++;
  f->loop_depth--;

  if (!f->terminated) fprintf(c->out, "  br label %%bb%d\n", cond_bb);

  if (!infinite) {
    emit_label(c->out, end_bb);
    f->terminated = false;
  } else {
    // No fallthrough: the loop is treated as terminating the current control flow.
    f->terminated = true;
  }
  *io_i = i;
}

static void compile_stmt_list(FuncCtx* f, size_t* io_i, size_t end) {
  Compiler* c = f->c;
  size_t i = *io_i;
  while (i < end && c->toks[i].kind != TOK_DEDENT && c->toks[i].kind != TOK_EOF) {
    if (c->toks[i].kind == TOK_NEWLINE) {
      i++;
      continue;
    }
    // If the prior statement terminated the current block (return/break/continue),
    // start a fresh (possibly unreachable) basic block so any following statements
    // still produce valid LLVM IR.
    if (f->terminated) {
      int lbl = new_label(f);
      fprintf(c->out, "bb%d:\n", lbl);
      f->terminated = false;
    }
    uint32_t k = c->toks[i].kind;
    if (k == TOK_KW_VAR || k == TOK_KW_LET) {
      size_t kw_i = i;
      i++;
      if (i >= end || c->toks[i].kind != TOK_IDENT) {
        error_at_tok(c, (kw_i < c->ntoks) ? &c->toks[kw_i] : NULL, "expected identifier after `var`/`let`");
        return;
      }
      const char* name = tok_ptr(c, &c->toks[i]);
      size_t name_len = tok_len(&c->toks[i]);
      i++;
      bool inferred = false;
      if (i < end && c->toks[i].kind == TOK_KW_IS) {
        i++;
        if (!parse_type_at(c, &i)) {
          error_at_tok(c, (i < c->ntoks) ? &c->toks[i] : &c->toks[c->ntoks - 1], "expected type");
          return;
        }
      } else {
        inferred = true;
      }
      Local* loc = find_local(f, name, name_len);
      if (!loc) {
        error_at_tok(c, &c->toks[i - 1], "internal error: local not recorded in scan_locals");
        return;
      }
      if (inferred && c->toks[i].kind != TOK_EQ) {
        error_at_tok(c, &c->toks[i - 1], "inferred locals require an initializer: use `var x = <Expr>`");
        return;
      }
      if (c->toks[i].kind == TOK_EQ) {
        i++;
        Value rhs = parse_expr(f, &i, 1);
        if (loc) rhs = cast_to(f, loc->type, rhs);
        if (loc) {
          if (loc->type->kind == TY_STRUCT) {
            Value dst = (Value){.type = loc->type, .is_lvalue = true, .kind = V_SSA_LOCAL, .v.id = (int)loc->slot};
            emit_struct_copy(f, dst, rhs);
          } else {
            fprintf(c->out, "  store %s ", llvm_ty(loc->type));
            rhs = load_if_needed(f, rhs);
            emit_value(c->out, rhs);
            fprintf(c->out, ", ptr ");
            emit_ssa(c->out, 'l', (int)loc->slot);
            fprintf(c->out, ", align %zu\n", ty_align(loc->type));
          }
        }
      }
      if (c->toks[i].kind == TOK_NEWLINE) i++;
      continue;
    }
    if (k == TOK_KW_IF) {
      compile_if(f, &i, end);
      continue;
    }
    if (k == TOK_KW_WHILE) {
      compile_while(f, &i, end);
      continue;
    }
    if (k == TOK_KW_RETURN) {
      i++;
      if (c->toks[i].kind == TOK_NEWLINE) {
        fprintf(c->out, "  ret void\n");
        f->terminated = true;
        i++;
        continue;
      }
      Value v = parse_expr(f, &i, 1);
      v = cast_to(f, f->f->ret, v);
      v = load_if_needed(f, v);
      fprintf(c->out, "  ret %s ", llvm_ty(f->f->ret));
      emit_value(c->out, v);
      fprintf(c->out, "\n");
      f->terminated = true;
      if (c->toks[i].kind == TOK_NEWLINE) i++;
      continue;
    }
    if (k == TOK_KW_BREAK) {
      i++;
      if (f->loop_depth > 0) fprintf(c->out, "  br label %%bb%d\n", f->loop_end[f->loop_depth - 1]);
      f->terminated = true;
      if (c->toks[i].kind == TOK_NEWLINE) i++;
      continue;
    }
    if (k == TOK_KW_CONTINUE) {
      i++;
      if (f->loop_depth > 0) fprintf(c->out, "  br label %%bb%d\n", f->loop_cond[f->loop_depth - 1]);
      f->terminated = true;
      if (c->toks[i].kind == TOK_NEWLINE) i++;
      continue;
    }

    bool is_assign = line_has_assign_eq(c, i, end);
    if (is_assign) {
      Value lv = parse_assignable(f, &i);
      if (c->toks[i].kind == TOK_EQ) i++;
      Value rhs = parse_expr(f, &i, 1);
      rhs = cast_to(f, lv.type, rhs);
      if (lv.type->kind == TY_STRUCT) {
        emit_struct_copy(f, lv, rhs);
      } else {
        rhs = load_if_needed(f, rhs);
        fprintf(c->out, "  store %s ", llvm_ty(lv.type));
        emit_value(c->out, rhs);
        fprintf(c->out, ", ptr ");
        Value ptr = lv;
        ptr.is_lvalue = false;
        emit_value(c->out, ptr);
        fprintf(c->out, ", align %zu\n", ty_align(lv.type));
      }
      if (c->toks[i].kind == TOK_NEWLINE) i++;
      continue;
    }

    // expression statement
    Value v = parse_expr(f, &i, 1);
    (void)load_if_needed(f, v);
    if (c->toks[i].kind == TOK_NEWLINE) i++;
  }
  *io_i = i;
}

static void emit_extern_decl(Compiler* c, FuncDef* f) {
  // Some libc functions are truly variadic with a *single* fixed prefix even if the
  // Aster source spells out the common call shape. Declare them as real varargs.
  if (f->is_varargs && str_eq(f->name, f->name_len, "printf")) {
    fprintf(c->out, "declare %s @printf(ptr, ...)\n", llvm_ty(f->ret));
    return;
  }
  // Provide aliasing info for common allocators so clang can optimize Aster IR
  // similarly to C/C++ frontends (e.g., recognize distinct malloc results).
  if (f->ret && f->ret->kind == TY_PTR && str_eq(f->name, f->name_len, "malloc") && f->param_count == 1) {
    fprintf(c->out, "declare noalias %s @malloc(%s)\n", llvm_ty(f->ret), llvm_ty(f->params[0].type));
    return;
  }
  if (f->ret && f->ret->kind == TY_PTR && str_eq(f->name, f->name_len, "calloc") && f->param_count == 2) {
    fprintf(c->out, "declare noalias %s @calloc(%s, %s)\n", llvm_ty(f->ret), llvm_ty(f->params[0].type), llvm_ty(f->params[1].type));
    return;
  }
  const char* irn = f->ir_name ? f->ir_name : f->name;
  size_t irn_len = f->ir_name ? f->ir_name_len : f->name_len;
  fprintf(c->out, "declare %s @%.*s(", llvm_ty(f->ret), (int)irn_len, irn);
  for (size_t i = 0; i < f->param_count; i++) {
    if (i) fprintf(c->out, ", ");
    fprintf(c->out, "%s", llvm_ty(f->params[i].type));
  }
  if (f->is_varargs) {
    if (f->param_count) fprintf(c->out, ", ");
    fprintf(c->out, "...");
  }
  fprintf(c->out, ")\n");
}

static void emit_string_globals(Compiler* c) {
  for (size_t i = 0; i < c->nstrings; i++) {
    StrConst* s = c->strings[i];
    fprintf(c->out, "@.str%zu = private constant [%zu x i8] c\"", s->id, s->len);
    for (size_t j = 0; j < s->len; j++) {
      fprintf(c->out, "\\%02X", (unsigned)s->bytes[j]);
    }
    fprintf(c->out, "\", align 1\n");
  }
}

static void dump_ty(FILE* fp, Type* t) {
  if (!t) {
    fprintf(fp, "<null>");
    return;
  }
  switch (t->kind) {
    case TY_VOID: fprintf(fp, "void"); return;
    case TY_BOOL: fprintf(fp, "bool"); return;
    case TY_FLOAT: fprintf(fp, "f%u", (unsigned)t->bits); return;
    case TY_INT:
      fprintf(fp, "%c%u", t->is_signed ? 'i' : 'u', (unsigned)t->bits);
      return;
    case TY_PTR:
      fprintf(fp, "%sref ", t->is_mut ? "mut " : "");
      dump_ty(fp, t->pointee);
      return;
    case TY_STRUCT:
      if (t->sdef && t->sdef->name) {
        fprintf(fp, "%.*s", (int)t->sdef->name_len, t->sdef->name);
      } else {
        fprintf(fp, "<struct>");
      }
      return;
  }
  fprintf(fp, "<ty>");
}

static FILE* open_dump(const char* env_name, bool* out_should_close) {
  if (out_should_close) *out_should_close = false;
  const char* v = getenv(env_name);
  if (!v || !v[0]) return NULL;
  if (v[0] == '0' && v[1] == 0) return NULL;
  if (v[0] == '1' && v[1] == 0) {
    if (out_should_close) *out_should_close = false;
    return stderr;
  }
  FILE* fp = fopen(v, "wb");
  if (!fp) return NULL;
  if (out_should_close) *out_should_close = true;
  return fp;
}

static void dump_ast(const Compiler* c, FILE* fp) {
  fprintf(fp, "aster_ast v1\n");
  fprintf(fp, "file_modules %zu\n", c->nfile_mods);
  for (size_t i = 0; i < c->nfile_mods; i++) {
    const ModInfo* m = &c->mods[i];
    fprintf(fp, "module %zu name=%.*s path=%s\n", i, (int)m->name_len, m->name, m->rel_path ? m->rel_path : "");
    for (size_t ui = 0; ui < m->nuses; ui++) {
      const char* u = m->uses[ui];
      if (!u) continue;
      fprintf(fp, "  use %s\n", u);
    }
  }

  fprintf(fp, "structs %zu\n", c->nstructs);
  for (size_t i = 0; i < c->nstructs; i++) {
    const StructDef* s = c->structs[i];
    fprintf(fp, "struct %.*s mod=%u size=%zu align=%zu fields=%zu\n", (int)s->name_len, s->name, (unsigned)s->module_id,
            s->size, s->align, s->field_count);
    for (size_t fi = 0; fi < s->field_count; fi++) {
      const Field* f = &s->fields[fi];
      fprintf(fp, "  field %.*s off=%zu ty=", (int)f->name_len, f->name, f->offset);
      dump_ty(fp, f->type);
      fputc('\n', fp);
    }
  }

  fprintf(fp, "consts %zu\n", c->nconsts);
  for (size_t i = 0; i < c->nconsts; i++) {
    const ConstDef* k = c->consts[i];
    fprintf(fp, "const %.*s mod=%u ty=", (int)k->name_len, k->name, (unsigned)k->module_id);
    dump_ty(fp, k->type);
    fprintf(fp, " kind=%d ", (int)k->kind);
    if (k->kind == CONST_INT) {
      fprintf(fp, "u=%" PRIu64, k->v.u);
    } else if (k->kind == CONST_FLOAT) {
      fprintf(fp, "f=%.*s", (int)k->v.ftxt.len, k->v.ftxt.text);
    } else if (k->kind == CONST_STRING) {
      size_t slen = k->v.str ? k->v.str->len : 0;
      fprintf(fp, "str_len=%zu", slen);
    }
    fputc('\n', fp);
  }

  fprintf(fp, "funcs %zu\n", c->nfuncs);
  for (size_t i = 0; i < c->nfuncs; i++) {
    const FuncDef* f = c->funcs[i];
    fprintf(fp, "func %.*s mod=%u extern=%d noalloc=%d ret=", (int)f->name_len, f->name, (unsigned)f->module_id,
            (int)f->is_extern, (int)f->is_noalloc);
    dump_ty(fp, f->ret);
    fprintf(fp, " params=%zu", f->param_count);
    for (size_t pi = 0; pi < f->param_count; pi++) {
      fprintf(fp, " ");
      fprintf(fp, "%.*s:", (int)f->params[pi].name_len, f->params[pi].name);
      dump_ty(fp, f->params[pi].type);
    }
    if (!f->is_extern) {
      fprintf(fp, " body_toks=[%zu,%zu)", f->body_start, f->body_end);
    }
    fputc('\n', fp);
  }
}

static void dump_hir(const Compiler* c, FILE* fp) {
  fprintf(fp, "aster_hir v1\n");
  fprintf(fp, "funcs %zu\n", c->nfuncs);
  for (size_t i = 0; i < c->nfuncs; i++) {
    const FuncDef* f = c->funcs[i];
    const char* irn = f->ir_name ? f->ir_name : f->name;
    size_t irn_len = f->ir_name ? f->ir_name_len : f->name_len;
    fprintf(fp, "func %.*s ir=@%.*s mod=%u extern=%d noalloc=%d\n", (int)f->name_len, f->name, (int)irn_len, irn,
            (unsigned)f->module_id, (int)f->is_extern, (int)f->is_noalloc);
  }
}

static bool compile_func(Compiler* c, FuncDef* fn) {
  FuncCtx f = {.c = c, .f = fn, .next_temp = 0, .next_label = 0, .loop_depth = 0, .terminated = false};
  if (!scan_locals(&f, fn->body_start, fn->body_end)) {
    free(f.locals);
    return false;
  }

  // define header
  const char* irn = fn->ir_name ? fn->ir_name : fn->name;
  size_t irn_len = fn->ir_name ? fn->ir_name_len : fn->name_len;
  fprintf(c->out, "define %s @%.*s(", llvm_ty(fn->ret), (int)irn_len, irn);
  for (size_t i = 0; i < fn->param_count; i++) {
    if (i) fprintf(c->out, ", ");
    fprintf(c->out, "%s ", llvm_ty(fn->params[i].type));
    emit_ssa(c->out, 'p', (int)i);
  }
  fprintf(c->out, ") {\n");
  fprintf(c->out, "entry:\n");

  // allocas
  for (size_t i = 0; i < f.nlocals; i++) {
    Local* l = &f.locals[i];
    fprintf(c->out, "  ");
    emit_ssa(c->out, 'l', (int)l->slot);
    if (l->type->kind == TY_STRUCT && l->type->sdef) {
      fprintf(c->out, " = alloca [%zu x i8], align %zu\n", l->type->sdef->size, l->type->sdef->align);
    } else {
      fprintf(c->out, " = alloca %s, align %zu\n", llvm_ty(l->type), ty_align(l->type));
    }
  }

  size_t i = fn->body_start;
  compile_stmt_list(&f, &i, fn->body_end);

  if (c->had_error) {
    free(f.locals);
    return false;
  }

  if (!f.terminated) {
    if (fn->ret->kind == TY_VOID) fprintf(c->out, "  ret void\n");
    else {
      fprintf(stderr, "asterc: missing return in function %.*s\n", (int)fn->name_len, fn->name);
      free(f.locals);
      return false;
    }
  }
  fprintf(c->out, "}\n\n");
  free(f.locals);
  return true;
}

int asterc1__compile_real(uint8_t* src, size_t len, FILE* out) {
  Compiler c = {0};
  c.src = src;
  c.src_len = len;
  c.out = out;

  add_builtin_structs(&c);

  compiler_scan_unit_meta(&c);

  if (!lex_all(src, len, &c.toks, &c.ntoks)) return 1;
  assign_tok_modules(&c);
  c.i = 0;

  // parse module
  while (cur(&c)->kind != TOK_EOF) {
    skip_newlines(&c);
    if (cur(&c)->kind == TOK_EOF) break;
    uint32_t k = cur(&c)->kind;
    if (k == TOK_KW_CONST) {
      if (!parse_const_decl(&c)) return 1;
      continue;
    }
    if (k == TOK_KW_EXTERN) {
      if (!parse_extern_decl(&c)) return 1;
      continue;
    }
    if (k == TOK_KW_STRUCT) {
      if (!parse_struct_decl(&c)) return 1;
      continue;
    }
    if (k == TOK_KW_DEF || k == TOK_KW_NOALLOC) {
      if (!parse_def_decl(&c)) return 1;
      continue;
    }
    fprintf(stderr, "asterc: parse error: unexpected token kind %u\n", k);
    return 1;
  }

  if (c.had_error) return 1;

  bool ast_close = false;
  FILE* ast_fp = open_dump("ASTER_DUMP_AST", &ast_close);
  if (ast_fp) {
    dump_ast(&c, ast_fp);
    if (ast_close) fclose(ast_fp);
  }

  assign_ir_names(&c);

  bool hir_close = false;
  FILE* hir_fp = open_dump("ASTER_DUMP_HIR", &hir_close);
  if (hir_fp) {
    dump_hir(&c, hir_fp);
    if (hir_close) fclose(hir_fp);
  }

  // emit module
  fprintf(out, "; ModuleID = 'aster'\nsource_filename = \"aster\"\n\n");
  // builtins (bench code calls these without extern decls)
  bool have_calloc = false;
  bool have_memcpy = false;
  for (size_t i = 0; i < c.nfuncs; i++) {
    FuncDef* f = c.funcs[i];
    if (!f->is_extern) continue;
    if (str_eq(f->name, f->name_len, "calloc")) have_calloc = true;
    if (str_eq(f->name, f->name_len, "memcpy")) have_memcpy = true;
  }
  if (!have_calloc) fprintf(out, "declare noalias ptr @calloc(i64, i64)\n");
  if (!have_memcpy) fprintf(out, "declare ptr @memcpy(ptr, ptr, i64)\n");
  fprintf(out, "\n");

  for (size_t i = 0; i < c.nfuncs; i++) {
    if (c.funcs[i]->is_extern) emit_extern_decl(&c, c.funcs[i]);
  }
  fprintf(out, "\n");

  for (size_t i = 0; i < c.nfuncs; i++) {
    if (!c.funcs[i]->is_extern) {
      if (!compile_func(&c, c.funcs[i])) return 1;
    }
  }

  analyze_noalloc(&c);
  if (c.had_error) return 1;

  emit_string_globals(&c);
  return 0;
}

// -----------------------------
// Module system (Aster1, include-style) + deterministic build cache.
//
// This is intentionally minimal: `use foo.bar` in the leading preamble is
// treated as a compile-time include of:
//   <aster_root>/src/foo/bar.as
//
// The resulting compilation unit is a deterministic concatenation of modules
// in dependency order (DFS postorder), with all `use` lines stripped.
//
// A content-hash cache (opt-in via ASTER_CACHE=1) stores the final executable
// and `.ll` output under a key derived from:
// - compiler binary hash
// - unit hash (the preprocessed concatenated source)
// - link-mode flags (ASTER_LINK_OBJ / ASTER_LINK_ACCELERATE)
// -----------------------------

typedef struct {
  uint8_t* src;      // preprocessed compilation unit (NUL-terminated)
  size_t len;        // byte length (excluding NUL)
  uint8_t sha256[32]; // hash of `src[0:len]`
  char* root_abs;    // absolute project root (dir containing aster.toml)
  uint32_t flags;    // UNIT_FLAG_*
  uint32_t _pad_flags;
  char* net_obj_abs; // absolute path to net tls helper object (when needed)
  char* metal_obj_abs; // absolute path to metal helper object (when needed)
} AsterUnit;

enum {
  UNIT_FLAG_NET = 1u << 0, // unit imports core.net/core.http
  UNIT_FLAG_METAL = 1u << 1, // unit imports aster_ml.runtime.ops_metal
};

// sha256 (minimal, portable)
typedef struct {
  uint32_t h[8];
  uint64_t nbytes;
  uint8_t block[64];
  uint32_t block_len;
} Sha256;

static uint32_t rotr32(uint32_t x, uint32_t n) { return (x >> n) | (x << (32 - n)); }

static void sha256_init(Sha256* s) {
  s->h[0] = 0x6a09e667u;
  s->h[1] = 0xbb67ae85u;
  s->h[2] = 0x3c6ef372u;
  s->h[3] = 0xa54ff53au;
  s->h[4] = 0x510e527fu;
  s->h[5] = 0x9b05688cu;
  s->h[6] = 0x1f83d9abu;
  s->h[7] = 0x5be0cd19u;
  s->nbytes = 0;
  s->block_len = 0;
}

static void sha256_compress(Sha256* s, const uint8_t block[64]) {
  static const uint32_t k[64] = {
      0x428a2f98u, 0x71374491u, 0xb5c0fbcfu, 0xe9b5dba5u, 0x3956c25bu, 0x59f111f1u, 0x923f82a4u,
      0xab1c5ed5u, 0xd807aa98u, 0x12835b01u, 0x243185beu, 0x550c7dc3u, 0x72be5d74u, 0x80deb1feu,
      0x9bdc06a7u, 0xc19bf174u, 0xe49b69c1u, 0xefbe4786u, 0x0fc19dc6u, 0x240ca1ccu, 0x2de92c6fu,
      0x4a7484aau, 0x5cb0a9dcu, 0x76f988dau, 0x983e5152u, 0xa831c66du, 0xb00327c8u, 0xbf597fc7u,
      0xc6e00bf3u, 0xd5a79147u, 0x06ca6351u, 0x14292967u, 0x27b70a85u, 0x2e1b2138u, 0x4d2c6dfcu,
      0x53380d13u, 0x650a7354u, 0x766a0abbu, 0x81c2c92eu, 0x92722c85u, 0xa2bfe8a1u, 0xa81a664bu,
      0xc24b8b70u, 0xc76c51a3u, 0xd192e819u, 0xd6990624u, 0xf40e3585u, 0x106aa070u, 0x19a4c116u,
      0x1e376c08u, 0x2748774cu, 0x34b0bcb5u, 0x391c0cb3u, 0x4ed8aa4au, 0x5b9cca4fu, 0x682e6ff3u,
      0x748f82eeu, 0x78a5636fu, 0x84c87814u, 0x8cc70208u, 0x90befffau, 0xa4506cebu, 0xbef9a3f7u,
      0xc67178f2u,
  };

  uint32_t w[64];
  for (uint32_t i = 0; i < 16; i++) {
    uint32_t j = i * 4;
    w[i] = ((uint32_t)block[j] << 24) | ((uint32_t)block[j + 1] << 16) | ((uint32_t)block[j + 2] << 8) |
           ((uint32_t)block[j + 3]);
  }
  for (uint32_t i = 16; i < 64; i++) {
    uint32_t s0 = rotr32(w[i - 15], 7) ^ rotr32(w[i - 15], 18) ^ (w[i - 15] >> 3);
    uint32_t s1 = rotr32(w[i - 2], 17) ^ rotr32(w[i - 2], 19) ^ (w[i - 2] >> 10);
    w[i] = w[i - 16] + s0 + w[i - 7] + s1;
  }

  uint32_t a = s->h[0], b = s->h[1], c = s->h[2], d = s->h[3];
  uint32_t e = s->h[4], f = s->h[5], g = s->h[6], h = s->h[7];

  for (uint32_t i = 0; i < 64; i++) {
    uint32_t S1 = rotr32(e, 6) ^ rotr32(e, 11) ^ rotr32(e, 25);
    uint32_t ch = (e & f) ^ ((~e) & g);
    uint32_t temp1 = h + S1 + ch + k[i] + w[i];
    uint32_t S0 = rotr32(a, 2) ^ rotr32(a, 13) ^ rotr32(a, 22);
    uint32_t maj = (a & b) ^ (a & c) ^ (b & c);
    uint32_t temp2 = S0 + maj;

    h = g;
    g = f;
    f = e;
    e = d + temp1;
    d = c;
    c = b;
    b = a;
    a = temp1 + temp2;
  }

  s->h[0] += a;
  s->h[1] += b;
  s->h[2] += c;
  s->h[3] += d;
  s->h[4] += e;
  s->h[5] += f;
  s->h[6] += g;
  s->h[7] += h;
}

static void sha256_update(Sha256* s, const void* data, size_t len) {
  const uint8_t* p = (const uint8_t*)data;
  s->nbytes += (uint64_t)len;
  while (len > 0) {
    uint32_t space = 64u - s->block_len;
    uint32_t n = (len < (size_t)space) ? (uint32_t)len : space;
    memcpy(&s->block[s->block_len], p, n);
    s->block_len += n;
    p += n;
    len -= n;
    if (s->block_len == 64u) {
      sha256_compress(s, s->block);
      s->block_len = 0;
    }
  }
}

static void sha256_final(Sha256* s, uint8_t out[32]) {
  uint64_t bitlen = s->nbytes * 8u;
  // append 0x80
  uint8_t b = 0x80;
  sha256_update(s, &b, 1);
  // pad with zeros until 56 mod 64
  uint8_t z = 0;
  while (s->block_len != 56u) {
    sha256_update(s, &z, 1);
  }
  uint8_t lenbuf[8];
  for (int i = 0; i < 8; i++) {
    lenbuf[7 - i] = (uint8_t)((bitlen >> (i * 8)) & 0xffu);
  }
  sha256_update(s, lenbuf, 8);

  for (int i = 0; i < 8; i++) {
    out[i * 4 + 0] = (uint8_t)((s->h[i] >> 24) & 0xffu);
    out[i * 4 + 1] = (uint8_t)((s->h[i] >> 16) & 0xffu);
    out[i * 4 + 2] = (uint8_t)((s->h[i] >> 8) & 0xffu);
    out[i * 4 + 3] = (uint8_t)(s->h[i] & 0xffu);
  }
}

static void sha256_one(const void* data, size_t len, uint8_t out[32]) {
  Sha256 s;
  sha256_init(&s);
  sha256_update(&s, data, len);
  sha256_final(&s, out);
}

typedef struct {
  uint8_t* data;
  size_t len;
  size_t cap;
} ByteBuf;

static void bb_reserve(ByteBuf* b, size_t extra) {
  size_t need = b->len + extra;
  if (need <= b->cap) return;
  size_t ncap = b->cap ? b->cap : 4096;
  while (ncap < need) ncap *= 2;
  b->data = (uint8_t*)xrealloc(b->data, ncap);
  b->cap = ncap;
}

static void bb_append(ByteBuf* b, const void* data, size_t n) {
  bb_reserve(b, n);
  memcpy(b->data + b->len, data, n);
  b->len += n;
}

static void bb_append_cstr(ByteBuf* b, const char* s) { bb_append(b, s, strlen(s)); }

static char* xstrndup(const char* s, size_t n) {
  char* out = (char*)xmalloc(n + 1);
  memcpy(out, s, n);
  out[n] = 0;
  return out;
}

static char* xstrdup0(const char* s) { return xstrndup(s, strlen(s)); }

static bool file_exists(const char* path) {
  struct stat st;
  return stat(path, &st) == 0 && S_ISREG(st.st_mode);
}

static bool dir_exists(const char* path) {
  struct stat st;
  return stat(path, &st) == 0 && S_ISDIR(st.st_mode);
}

static char* path_dirname_dup(const char* path) {
  size_t n = strlen(path);
  if (n == 0) return xstrdup0(".");
  // strip trailing slashes
  while (n > 1 && path[n - 1] == '/') n--;
  size_t i = n;
  while (i > 0 && path[i - 1] != '/') i--;
  if (i == 0) return xstrdup0(".");
  if (i == 1) return xstrdup0("/");
  return xstrndup(path, i - 1);
}

static char* path_join3(const char* a, const char* b, const char* c) {
  size_t na = strlen(a), nb = strlen(b), nc = strlen(c);
  bool b_abs = (nb > 0 && b[0] == '/');
  bool c_abs = (nc > 0 && c[0] == '/');

  bool need_slash1 = false;
  if (na > 0 && nb > 0) {
    if (a[na - 1] != '/' && !b_abs) need_slash1 = true;
    if (a[na - 1] == '/' && b_abs) na--; // avoid double slash
  }

  bool need_slash2 = false;
  if (nc > 0 && nb > 0) {
    if (b[nb - 1] != '/' && !c_abs) need_slash2 = true;
    if (b[nb - 1] == '/' && c_abs) nb--; // avoid double slash
  }

  size_t out_len = na + (need_slash1 ? 1 : 0) + nb + (need_slash2 ? 1 : 0) + nc;
  char* out = (char*)xmalloc(out_len + 1);
  size_t o = 0;
  if (na) memcpy(out + o, a, na);
  o += na;
  if (need_slash1) out[o++] = '/';
  if (nb) memcpy(out + o, b, nb);
  o += nb;
  if (need_slash2) out[o++] = '/';
  if (nc) memcpy(out + o, c, nc);
  o += nc;
  out[o] = 0;
  return out;
}

static char* path_join2(const char* a, const char* b) { return path_join3(a, b, ""); }

static char* realpath_dup(const char* path) {
  char* rp = realpath(path, NULL);
  if (rp) return rp;
  return NULL;
}

static char* find_aster_root_abs(const char* start_dir_abs) {
  // Walk upward from start_dir looking for aster.toml.
  char* d = xstrdup0(start_dir_abs);
  for (;;) {
    char* toml = path_join3(d, "aster.toml", "");
    bool ok = file_exists(toml);
    free(toml);
    if (ok) return d;
    if (strcmp(d, "/") == 0) break;
    // parent
    char* parent = path_dirname_dup(d);
    free(d);
    d = parent;
    if (!dir_exists(d)) break;
  }
  // fallback: current working directory if possible, else start dir
  char* cwd = getcwd(NULL, 0);
  if (cwd) {
    free(d);
    return cwd;
  }
  return d;
}

typedef struct {
  char* name;     // package name (module root segment)
  char* root_abs; // absolute filesystem path to dep root
} DepSpec;

static bool is_ident_start(char c) { return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || c == '_'; }
static bool is_ident_cont(char c) { return is_ident_start(c) || (c >= '0' && c <= '9'); }

static bool parse_use_line(const uint8_t* line, size_t line_len, const char** out_mod, size_t* out_mod_len) {
  // line is without trailing newline.
  size_t i = 0;
  while (i < line_len && (line[i] == ' ' || line[i] == '\t')) i++;
  if (i >= line_len) return false;
  if (line[i] == '#') return false;
  // must start with "use"
  if (i + 3 > line_len) return false;
  if (line[i] != 'u' || line[i + 1] != 's' || line[i + 2] != 'e') return false;
  i += 3;
  if (i >= line_len || !(line[i] == ' ' || line[i] == '\t')) return false;
  while (i < line_len && (line[i] == ' ' || line[i] == '\t')) i++;
  if (i >= line_len) return false;
  size_t mod_start = i;
  // parse ident(.ident)*
  if (!is_ident_start((char)line[i])) return false;
  i++;
  while (i < line_len) {
    char c = (char)line[i];
    if (is_ident_cont(c)) {
      i++;
      continue;
    }
    if (c == '.') {
      i++;
      if (i >= line_len) return false;
      if (!is_ident_start((char)line[i])) return false;
      i++;
      continue;
    }
    break;
  }
  size_t mod_end = i;
  while (i < line_len && (line[i] == ' ' || line[i] == '\t')) i++;
  if (i != line_len) return false;
  *out_mod = (const char*)line + mod_start;
  *out_mod_len = mod_end - mod_start;
  return true;
}

typedef struct ModNode {
  char* abs_path;
  uint8_t* src;
  size_t len;
  char** uses;
  size_t nuses;
} ModNode;

typedef struct {
  const char* root_abs;
  DepSpec* deps;
  size_t ndeps;
  ModNode** visited;
  size_t nvis, capvis;
  ModNode** order;
  size_t norder, caporder;
} ModGraph;

static DepSpec* graph_find_dep(ModGraph* g, const char* name, size_t name_len) {
  if (!g || !name || !name_len) return NULL;
  for (size_t i = 0; i < g->ndeps; i++) {
    DepSpec* d = &g->deps[i];
    if (!d->name) continue;
    if (strlen(d->name) == name_len && memcmp(d->name, name, name_len) == 0) return d;
  }
  return NULL;
}

static bool graph_add_dep(ModGraph* g, const char* name, size_t name_len, const char* path, size_t path_len) {
  if (!g || !name || !path) return true;
  if (!name_len || !path_len) return true;
  if (graph_find_dep(g, name, name_len)) return true;
  char* name0 = xstrndup(name, name_len);
  char* rel0 = xstrndup(path, path_len);
  char* abs = NULL;
  // deps are resolved relative to the workspace root for determinism
  if (rel0[0] == '/') abs = realpath_dup(rel0);
  else {
    char* joined = path_join3(g->root_abs, rel0, "");
    abs = realpath_dup(joined);
    free(joined);
  }
  if (!abs) {
    fprintf(stderr, "asterc: lockfile dep path not found: dep %s %s\n", name0, rel0);
    free(name0);
    free(rel0);
    return false;
  }
  g->deps = (DepSpec*)xrealloc(g->deps, sizeof(DepSpec) * (g->ndeps + 1));
  g->deps[g->ndeps++] = (DepSpec){.name = name0, .root_abs = abs};
  free(rel0);
  return true;
}

static bool graph_scan_lock_deps(ModGraph* g) {
  if (!g || !g->root_abs) return true;
  // Minimal lockfile parser.
  //
  // Supported:
  //   lock_version = 0|1
  //   dep <name> <path>
  char* lock = path_join3(g->root_abs, "aster.lock", "");
  FILE* fp = fopen(lock, "rb");
  free(lock);
  if (!fp) return true;

  int lock_ver = -1;
  bool saw_dep = false;
  char line[4096];
  while (fgets(line, sizeof(line), fp)) {
    // strip trailing newline
    size_t n = strlen(line);
    while (n && (line[n - 1] == '\n' || line[n - 1] == '\r')) line[--n] = 0;
    // trim leading space
    size_t i = 0;
    while (i < n && (line[i] == ' ' || line[i] == '\t')) i++;
    if (i >= n) continue;
    if (line[i] == '#') continue;

    // lock_version = N
    if (line[i] == 'l' && (i + 12) <= n && memcmp(line + i, "lock_version", 12) == 0) {
      size_t j = i + 12;
      while (j < n && (line[j] == ' ' || line[j] == '\t')) j++;
      if (j >= n || line[j] != '=') {
        fprintf(stderr, "asterc: invalid aster.lock line (expected `lock_version = N`)\n");
        fclose(fp);
        return false;
      }
      j++;
      while (j < n && (line[j] == ' ' || line[j] == '\t')) j++;
      if (j >= n || line[j] < '0' || line[j] > '9') {
        fprintf(stderr, "asterc: invalid aster.lock lock_version\n");
        fclose(fp);
        return false;
      }
      int v = 0;
      while (j < n && (line[j] >= '0' && line[j] <= '9')) {
        v = v * 10 + (line[j] - '0');
        j++;
      }
      while (j < n && (line[j] == ' ' || line[j] == '\t')) j++;
      if (j != n) {
        fprintf(stderr, "asterc: invalid aster.lock lock_version (trailing junk)\n");
        fclose(fp);
        return false;
      }
      lock_ver = v;
      continue;
    }

    if (line[i] != 'd' || i + 3 >= n) continue;
    if (line[i + 1] != 'e' || line[i + 2] != 'p') continue;
    if (!(line[i + 3] == ' ' || line[i + 3] == '\t')) continue;
    i += 4;
    while (i < n && (line[i] == ' ' || line[i] == '\t')) i++;
    size_t name_start = i;
    while (i < n && !(line[i] == ' ' || line[i] == '\t')) i++;
    size_t name_end = i;
    while (i < n && (line[i] == ' ' || line[i] == '\t')) i++;
    size_t path_start = i;
    size_t path_end = n;
    if (name_end > name_start && path_end > path_start) {
      saw_dep = true;
      if (!graph_add_dep(g, line + name_start, name_end - name_start, line + path_start, path_end - path_start)) {
        fclose(fp);
        return false;
      }
    }
  }

  fclose(fp);
  if (lock_ver < 0) lock_ver = 0;
  if (lock_ver > 1) {
    fprintf(stderr, "asterc: unsupported aster.lock lock_version=%d\n", lock_ver);
    return false;
  }
  if (saw_dep && lock_ver < 1) {
    fprintf(stderr, "asterc: aster.lock has `dep` entries but lock_version=%d (need >=1)\n", lock_ver);
    return false;
  }
  return true;
}

static char* mod_to_file(ModGraph* g, const char* mod) {
  // Root package:
  //   use foo.bar -> <root>/src/foo/bar.as
  //
  // Lockfile deps (optional; aster.lock v1):
  //   dep foo libraries/foo
  // allows:
  //   use foo.bar -> <dep_root>/src/bar.as
  //   use foo -> <dep_root>/src/lib.as
  if (!g || !g->root_abs || !mod) return NULL;
  const char* dot = strchr(mod, '.');
  size_t root_len = dot ? (size_t)(dot - mod) : strlen(mod);
  DepSpec* dep = graph_find_dep(g, mod, root_len);

  const char* base = dep ? dep->root_abs : g->root_abs;
  const char* sub = NULL;
  if (dep) {
    sub = dot ? (dot + 1) : NULL;
  } else {
    sub = mod;
  }

  ByteBuf b = {0};
  bb_append_cstr(&b, base);
  bb_append_cstr(&b, "/src/");

  if (dep && (!sub || !sub[0])) {
    bb_append_cstr(&b, "lib");
  } else {
    size_t n = strlen(sub);
    for (size_t i = 0; i < n; i++) {
      char ch = sub[i];
      if (ch == '.') ch = '/';
      bb_append(&b, &ch, 1);
    }
  }

  bb_append_cstr(&b, ".as");
  bb_append(&b, "\0", 1);
  return (char*)b.data;
}

static ModNode* graph_find(ModGraph* g, const char* abs_path) {
  for (size_t i = 0; i < g->nvis; i++) {
    ModNode* n = g->visited[i];
    if (strcmp(n->abs_path, abs_path) == 0) return n;
  }
  return NULL;
}

static void graph_push_node(ModGraph* g, ModNode* n) {
  if (g->nvis == g->capvis) {
    g->capvis = g->capvis ? g->capvis * 2 : 32;
    g->visited = (ModNode**)xrealloc(g->visited, g->capvis * sizeof(ModNode*));
  }
  g->visited[g->nvis++] = n;
}

static void graph_push_order(ModGraph* g, ModNode* n) {
  if (g->norder == g->caporder) {
    g->caporder = g->caporder ? g->caporder * 2 : 32;
    g->order = (ModNode**)xrealloc(g->order, g->caporder * sizeof(ModNode*));
  }
  g->order[g->norder++] = n;
}

static bool read_entire_file(const char* path, uint8_t** out_buf, size_t* out_len) {
  FILE* fp = fopen(path, "rb");
  if (!fp) return false;
  if (fseek(fp, 0, SEEK_END) != 0) {
    fclose(fp);
    return false;
  }
  long n = ftell(fp);
  if (n < 0) {
    fclose(fp);
    return false;
  }
  if (fseek(fp, 0, SEEK_SET) != 0) {
    fclose(fp);
    return false;
  }
  size_t len = (size_t)n;
  uint8_t* buf = (uint8_t*)xmalloc(len + 1);
  size_t got = fread(buf, 1, len, fp);
  fclose(fp);
  if (got != len) {
    free(buf);
    return false;
  }
  buf[len] = 0;
  *out_buf = buf;
  *out_len = len;
  return true;
}

static bool scan_use_preamble(ModGraph* g, const uint8_t* src, size_t len, char*** out_mods, size_t* out_nmods) {
  (void)g;
  size_t cap = 0;
  size_t nmods = 0;
  char** mods = NULL;

  bool in_preamble = true;
  size_t i = 0;
  while (i < len && in_preamble) {
    size_t line_start = i;
    while (i < len && src[i] != '\n') i++;
    size_t line_end = i;
    if (i < len && src[i] == '\n') i++;

    // trim leading whitespace
    size_t t = line_start;
    while (t < line_end && (src[t] == ' ' || src[t] == '\t')) t++;
    if (t == line_end) continue;
    if (src[t] == '#') continue;

    const char* mod = NULL;
    size_t mod_len = 0;
    if (parse_use_line(src + line_start, line_end - line_start, &mod, &mod_len)) {
      if (nmods == cap) {
        cap = cap ? cap * 2 : 8;
        mods = (char**)xrealloc(mods, cap * sizeof(char*));
      }
      mods[nmods++] = xstrndup(mod, mod_len);
      continue;
    }
    in_preamble = false;
  }

  *out_mods = mods;
  *out_nmods = nmods;
  return true;
}

static bool graph_dfs(ModGraph* g, const char* abs_path, const uint8_t* src_override, size_t len_override) {
  if (graph_find(g, abs_path)) return true;

  ModNode* n = (ModNode*)xmalloc(sizeof(ModNode));
  memset(n, 0, sizeof(*n));
  n->abs_path = xstrdup0(abs_path);
  if (src_override) {
    n->src = (uint8_t*)src_override;
    n->len = len_override;
  } else {
    if (!read_entire_file(abs_path, &n->src, &n->len)) {
      fprintf(stderr, "asterc: failed to read module: %s\n", abs_path);
      return false;
    }
  }

  graph_push_node(g, n);

  char** mods = NULL;
  size_t nmods = 0;
  if (!scan_use_preamble(g, n->src, n->len, &mods, &nmods)) return false;
  n->uses = mods;
  n->nuses = nmods;

  for (size_t i = 0; i < n->nuses; i++) {
    char* mod = n->uses[i];
    if (!mod) continue;
    char* dep_rel = mod_to_file(g, mod);
    char* dep_abs = realpath_dup(dep_rel);
    if (!dep_abs) {
      fprintf(stderr, "asterc: module not found: use %s -> %s\n", mod, dep_rel);
      free(dep_rel);
      return false;
    }
    free(dep_rel);
    if (!graph_dfs(g, dep_abs, NULL, 0)) {
      free(dep_abs);
      return false;
    }
    free(dep_abs);
  }

  graph_push_order(g, n);
  return true;
}

static void bb_append_strip_use(ByteBuf* out, Sha256* h, const uint8_t* src, size_t len) {
  bool in_preamble = true;
  size_t i = 0;
  while (i < len) {
    size_t line_start = i;
    while (i < len && src[i] != '\n') i++;
    size_t line_end = i;
    bool has_nl = (i < len && src[i] == '\n');
    if (has_nl) i++;

    if (in_preamble) {
      size_t t = line_start;
      while (t < line_end && (src[t] == ' ' || src[t] == '\t')) t++;
      if (t == line_end || src[t] == '#') {
        // keep blank/comment lines
        size_t n = (line_end - line_start) + (has_nl ? 1 : 0);
        bb_append(out, src + line_start, n);
        if (h) sha256_update(h, src + line_start, n);
        continue;
      }

      const char* mod = NULL;
      size_t mod_len = 0;
      if (parse_use_line(src + line_start, line_end - line_start, &mod, &mod_len)) {
        // drop `use` line (including newline)
        continue;
      }

      // first real code line: stop stripping
      in_preamble = false;
    }

    // once past preamble, copy remainder (including this line) in one go
    size_t n = len - line_start;
    bb_append(out, src + line_start, n);
    if (h) sha256_update(h, src + line_start, n);
    break;
  }
}

AsterUnit* asterc1__unit_from_entry(const char* in_path, const uint8_t* entry_src, size_t entry_len) {
  if (!in_path || !entry_src) return NULL;

  // Determine root.
  char* in_dir = path_dirname_dup(in_path);
  char* in_dir_abs = realpath_dup(in_dir);
  if (!in_dir_abs) in_dir_abs = xstrdup0(in_dir);
  free(in_dir);
  char* root_abs = find_aster_root_abs(in_dir_abs);
  free(in_dir_abs);

  // Canonicalize entry path for visited keys.
  char* entry_abs = realpath_dup(in_path);
  if (!entry_abs) entry_abs = xstrdup0(in_path);

  ModGraph g = {0};
  g.root_abs = root_abs;
  if (!graph_scan_lock_deps(&g)) {
    free(entry_abs);
    free(root_abs);
    return NULL;
  }
  if (!graph_dfs(&g, entry_abs, entry_src, entry_len)) {
    free(entry_abs);
    free(root_abs);
    return NULL;
  }
  free(entry_abs);

  ByteBuf out = {0};
  Sha256 hu;
  sha256_init(&hu);
  bool needs_net = false;
  bool needs_metal = false;

  for (size_t i = 0; i < g.norder; i++) {
    ModNode* n = g.order[i];
    const char* rel = n->abs_path;
    size_t root_len = strlen(root_abs);
    if (strncmp(n->abs_path, root_abs, root_len) == 0 && n->abs_path[root_len] == '/') {
      rel = n->abs_path + root_len + 1;
    }

    // Link helpers based on imported stdlib modules.
    if (strcmp(rel, "src/core/net.as") == 0 || strcmp(rel, "src/core/http.as") == 0) {
      needs_net = true;
    }
    if (strcmp(rel, "src/aster_ml/runtime/ops_metal.as") == 0) {
      needs_metal = true;
    }

    bb_append_cstr(&out, "# --- module: ");
    sha256_update(&hu, "# --- module: ", 13);
    bb_append(&out, rel, strlen(rel));
    sha256_update(&hu, rel, strlen(rel));
    bb_append_cstr(&out, " ---\n");
    sha256_update(&hu, " ---\n", 5);

    // Preserve the original import list for this module (even though `use`
    // lines are stripped from the concatenated source) so the compiler can
    // build a real symbol table/module namespace layer.
    for (size_t ui = 0; ui < n->nuses; ui++) {
      const char* um = n->uses[ui];
      if (!um) continue;
      bb_append_cstr(&out, "# --- use: ");
      sha256_update(&hu, "# --- use: ", 10);
      bb_append(&out, um, strlen(um));
      sha256_update(&hu, um, strlen(um));
      bb_append_cstr(&out, " ---\n");
      sha256_update(&hu, " ---\n", 5);
    }

    bb_append_strip_use(&out, &hu, n->src, n->len);
    bb_append_cstr(&out, "\n\n");
    sha256_update(&hu, "\n\n", 2);
  }

  uint8_t unit_hash[32];
  sha256_final(&hu, unit_hash);

  // Ensure NUL termination for safety (driver previously did this).
  bb_append(&out, "\0", 1);

  AsterUnit* u = (AsterUnit*)xmalloc(sizeof(AsterUnit));
  memset(u, 0, sizeof(*u));
  u->src = out.data;
  u->len = out.len ? (out.len - 1) : 0;
  memcpy(u->sha256, unit_hash, 32);
  u->root_abs = root_abs;
  u->flags = 0;
  if (needs_net) u->flags |= UNIT_FLAG_NET;
  if (needs_metal) u->flags |= UNIT_FLAG_METAL;
  u->net_obj_abs = needs_net ? path_join3(root_abs, "tools/build/out/net_tls_rt.o", "") : NULL;
  u->metal_obj_abs = needs_metal ? path_join3(root_abs, "tools/build/out/ml_metal_rt.o", "") : NULL;
  return u;
}

static bool env_enabled(const char* name) {
  const char* v = getenv(name);
  if (!v || !v[0]) return false;
  if (v[0] == '0' && v[1] == 0) return false;
  return true;
}

static bool sha256_file(const char* path, uint8_t out[32]) {
  FILE* fp = fopen(path, "rb");
  if (!fp) return false;
  Sha256 s;
  sha256_init(&s);
  uint8_t buf[64 * 1024];
  for (;;) {
    size_t n = fread(buf, 1, sizeof(buf), fp);
    if (n) sha256_update(&s, buf, n);
    if (n < sizeof(buf)) break;
  }
  bool ok = !ferror(fp);
  fclose(fp);
  if (!ok) return false;
  sha256_final(&s, out);
  return true;
}

static char* self_exe_path(void) {
#ifdef __APPLE__
  uint32_t cap = 0;
  (void)_NSGetExecutablePath(NULL, &cap);
  if (cap == 0) return NULL;
  char* tmp = (char*)xmalloc(cap + 1);
  if (_NSGetExecutablePath(tmp, &cap) != 0) {
    free(tmp);
    return NULL;
  }
  tmp[cap] = 0;
  char* rp = realpath_dup(tmp);
  if (rp) {
    free(tmp);
    return rp;
  }
  return tmp;
#else
  // Linux: /proc/self/exe (best-effort)
  char buf[PATH_MAX];
  ssize_t n = readlink("/proc/self/exe", buf, sizeof(buf) - 1);
  if (n <= 0) return NULL;
  buf[n] = 0;
  return xstrdup0(buf);
#endif
}

static void sha256_to_hex(const uint8_t h[32], char out_hex[65]) {
  static const char* hexd = "0123456789abcdef";
  for (int i = 0; i < 32; i++) {
    out_hex[i * 2 + 0] = hexd[(h[i] >> 4) & 0xF];
    out_hex[i * 2 + 1] = hexd[h[i] & 0xF];
  }
  out_hex[64] = 0;
}

static bool mkdir_p(const char* path) {
  if (!path || !path[0]) return false;
  char* p = xstrdup0(path);
  size_t n = strlen(p);
  if (n == 0) {
    free(p);
    return false;
  }
  // strip trailing slash
  while (n > 1 && p[n - 1] == '/') p[--n] = 0;
  for (size_t i = 1; i < n; i++) {
    if (p[i] == '/') {
      p[i] = 0;
      if (mkdir(p, 0777) != 0 && errno != EEXIST) {
        p[i] = '/';
        free(p);
        return false;
      }
      p[i] = '/';
    }
  }
  if (mkdir(p, 0777) != 0 && errno != EEXIST) {
    free(p);
    return false;
  }
  free(p);
  return true;
}

static bool copy_file_preserve_mode(const char* src, const char* dst) {
  int in = -1, out = -1;
  bool ok = false;
  struct stat st;
  if (stat(src, &st) != 0) return false;

  in = open(src, O_RDONLY);
  if (in < 0) goto done;
  out = open(dst, O_CREAT | O_TRUNC | O_WRONLY, (mode_t)(st.st_mode & 0777));
  if (out < 0) goto done;
  (void)fchmod(out, (mode_t)(st.st_mode & 0777));

  uint8_t buf[64 * 1024];
  for (;;) {
    ssize_t n = read(in, buf, sizeof(buf));
    if (n < 0) goto done;
    if (n == 0) break;
    uint8_t* p = buf;
    ssize_t left = n;
    while (left > 0) {
      ssize_t w = write(out, p, (size_t)left);
      if (w <= 0) goto done;
      p += w;
      left -= w;
    }
  }
  ok = true;

done:
  if (in >= 0) close(in);
  if (out >= 0) close(out);
  return ok;
}

static char* default_cache_dir(const AsterUnit* u) {
  // <root>/.context/build/cache
  return path_join3(u->root_abs, ".context/build/cache", "");
}

static void cache_key_add_file_hash(Sha256* s, const char* label, const char* path) {
  if (!s || !label || !path || !path[0]) return;
  sha256_update(s, label, strlen(label));
  sha256_update(s, path, strlen(path));
  sha256_update(s, "\n", 1);
  uint8_t h[32];
  if (sha256_file(path, h)) {
    sha256_update(s, h, 32);
  } else {
    sha256_update(s, "missing", 7);
  }
  sha256_update(s, "\n", 1);
}

static void unit_cache_key(const AsterUnit* u, uint8_t out_key[32]) {
  // key = sha256( "aster_cache_v1" || unit_sha || self_sha || link flags )
  uint8_t selfh[32] = {0};
  char* self = self_exe_path();
  if (self) {
    (void)sha256_file(self, selfh);
    free(self);
  }

  Sha256 s;
  sha256_init(&s);
  const char* tag = "aster_cache_v1\n";
  sha256_update(&s, tag, strlen(tag));
  sha256_update(&s, u->sha256, 32);
  sha256_update(&s, selfh, 32);

  const char* obj = getenv("ASTER_LINK_OBJ");
  if (obj && obj[0] && !(obj[0] == '0' && obj[1] == 0)) {
    cache_key_add_file_hash(&s, "obj=", obj);
  }
  if (env_enabled("ASTER_LINK_ACCELERATE")) {
    sha256_update(&s, "accel=1\n", 8);
  } else {
    sha256_update(&s, "accel=0\n", 8);
  }

  if (env_enabled("ASTER_DEBUG")) {
    sha256_update(&s, "dbg=1\n", 6);
  } else {
    sha256_update(&s, "dbg=0\n", 6);
  }

  // Match the driver flag selection for clang.
  int olevel = 3;
  if (env_enabled("ASTER_DEBUG")) {
    olevel = 0;
  } else {
    const char* ov = getenv("ASTER_OLEVEL");
    if (ov && ov[0]) {
      if (ov[0] == '0') olevel = 0;
      else if (ov[0] == '2') olevel = 2;
      else if (ov[0] == '3') olevel = 3;
    }
  }
  if (olevel == 0) sha256_update(&s, "O=0\n", 4);
  else if (olevel == 2) sha256_update(&s, "O=2\n", 4);
  else sha256_update(&s, "O=3\n", 4);

  if (env_enabled("ASTER_NATIVE")) {
    sha256_update(&s, "native=1\n", 9);
  } else {
    sha256_update(&s, "native=0\n", 9);
  }

  if (env_enabled("ASTER_FAST_MATH")) {
    sha256_update(&s, "fastmath=1\n", 11);
  } else {
    sha256_update(&s, "fastmath=0\n", 11);
  }

  if (u->flags & UNIT_FLAG_NET) {
    sha256_update(&s, "net=1\n", 6);
    if (u->net_obj_abs) cache_key_add_file_hash(&s, "net_obj=", u->net_obj_abs);
  } else {
    sha256_update(&s, "net=0\n", 6);
  }
  if (u->flags & UNIT_FLAG_METAL) {
    sha256_update(&s, "metal=1\n", 8);
    if (u->metal_obj_abs) cache_key_add_file_hash(&s, "metal_obj=", u->metal_obj_abs);
  } else {
    sha256_update(&s, "metal=0\n", 8);
  }

  sha256_final(&s, out_key);
}

int asterc1__cache_try(AsterUnit* u, const char* out_path, const char* ll_path) {
  if (!u || !out_path || !ll_path) return 0;
  if (!env_enabled("ASTER_CACHE")) return 0;

  const char* cache_root = getenv("ASTER_CACHE_DIR");
  char* cache_dir = NULL;
  if (cache_root && cache_root[0]) cache_dir = xstrdup0(cache_root);
  else cache_dir = default_cache_dir(u);
  if (!mkdir_p(cache_dir)) {
    free(cache_dir);
    return 0;
  }

  uint8_t key[32];
  unit_cache_key(u, key);
  char hex[65];
  sha256_to_hex(key, hex);

  char* ent = path_join3(cache_dir, hex, "");
  free(cache_dir);
  char* bin_cache = path_join3(ent, "out", "");
  char* ll_cache = path_join3(ent, "out.ll", "");

  struct stat st;
  if (stat(bin_cache, &st) == 0 && (st.st_mode & S_IXUSR)) {
    bool ok_bin = copy_file_preserve_mode(bin_cache, out_path);
    bool ok_ll = true;
    if (file_exists(ll_cache)) ok_ll = copy_file_preserve_mode(ll_cache, ll_path);
    free(ent);
    free(bin_cache);
    free(ll_cache);
    return (ok_bin && ok_ll) ? 1 : 0;
  }

  free(ent);
  free(bin_cache);
  free(ll_cache);
  return 0;
}

int asterc1__cache_store(AsterUnit* u, const char* out_path, const char* ll_path) {
  if (!u || !out_path || !ll_path) return 0;
  if (!env_enabled("ASTER_CACHE")) return 0;

  const char* cache_root = getenv("ASTER_CACHE_DIR");
  char* cache_dir = NULL;
  if (cache_root && cache_root[0]) cache_dir = xstrdup0(cache_root);
  else cache_dir = default_cache_dir(u);
  if (!mkdir_p(cache_dir)) {
    free(cache_dir);
    return 0;
  }

  uint8_t key[32];
  unit_cache_key(u, key);
  char hex[65];
  sha256_to_hex(key, hex);

  char* ent = path_join3(cache_dir, hex, "");
  free(cache_dir);
  if (!mkdir_p(ent)) {
    free(ent);
    return 0;
  }
  char* bin_cache = path_join3(ent, "out", "");
  char* ll_cache = path_join3(ent, "out.ll", "");

  // best-effort: ignore failures
  (void)copy_file_preserve_mode(out_path, bin_cache);
  if (file_exists(ll_path)) (void)copy_file_preserve_mode(ll_path, ll_cache);

  free(ent);
  free(bin_cache);
  free(ll_cache);
  return 0;
}
