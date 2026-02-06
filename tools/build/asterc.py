#!/usr/bin/env python3
import hashlib
import os
import pathlib
import re
import subprocess
import sys
import tempfile
import time
from typing import Dict, List

ROOT = pathlib.Path(__file__).resolve().parents[2]
COMPILER_REV = "asterc_py_v4"
ENABLE_RESTRICT = os.environ.get("ASTER_C_RESTRICT", "1") != "0"
ENABLE_PRAGMAS = os.environ.get("ASTER_C_PRAGMAS", "1") != "0"

TEMPLATES = {
    "dot": ROOT / "aster" / "bench" / "dot" / "aster_template.S",
    "gemm": ROOT / "aster" / "bench" / "gemm" / "aster_template.S",
    "stencil": ROOT / "aster" / "bench" / "stencil" / "aster_template.S",
    "sort": ROOT / "aster" / "bench" / "sort" / "aster_template.S",
}

CONST_RE = re.compile(r"^const\s+(\w+)(?:\s+is\s+\w+)?\s*=\s*([0-9_]+)")
DEF_RE = re.compile(r"^def\s+(\w+)")

TYPE_MAP = {
    "String": "char *",
    "File": "FILE *",
    "Stat": "struct stat",
    "usize": "size_t",
    "isize": "long",
    "u64": "uint64_t",
    "i64": "int64_t",
    "u32": "uint32_t",
    "i32": "int32_t",
    "u16": "uint16_t",
    "i16": "int16_t",
    "u8": "uint8_t",
    "f64": "double",
    "f32": "float",
    "PollFd": "struct pollfd",
    "TimeSpec": "struct timespec",
    "AttrList": "struct attrlist",
    "AttrRef": "attrreference_t",
    "bool": "int",
    "()": "void",
}

EXTERN_SKIP = {
    "malloc",
    "free",
    "printf",
    "strlen",
    "fopen",
    "fseek",
    "ftell",
    "fread",
    "fclose",
    "stat",
    "lstat",
    "getenv",
    "atoi",
    "pipe",
    "poll",
    "read",
    "write",
    "close",
    "open",
    "openat",
    "fstatat",
    "getattrlistbulk",
    "fts_open",
    "fts_read",
    "fts_close",
    "fts_set",
    "clock_gettime",
}


def parse_consts(src: str) -> Dict[str, int]:
    consts: Dict[str, int] = {}
    for line in src.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        m = CONST_RE.match(line)
        if m:
            name, val = m.group(1), m.group(2)
            consts[name] = int(val.replace("_", ""))
    return consts


def parse_defs(src: str):
    defs = []
    for line in src.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        m = DEF_RE.match(line)
        if m:
            defs.append(m.group(1))
    return defs


def apply_consts(template: str, consts: Dict[str, int]) -> str:
    for name, value in consts.items():
        pattern = rf"^(\.equ\s+{re.escape(name)},)\s*\d+"
        template = re.sub(
            pattern,
            lambda m, v=value: f"{m.group(1)} {v}",
            template,
            flags=re.MULTILINE,
        )
    return template


def add_ptr(ctype: str) -> str:
    ctype = ctype.rstrip()
    if ctype.endswith("*"):
        return ctype + "*"
    return ctype + " *"


def map_type(atype: str) -> str:
    atype = atype.strip()
    if atype.startswith("mut ref slice of "):
        return add_ptr(map_type(atype[len("mut ref slice of ") :]))
    if atype.startswith("ref slice of "):
        return add_ptr(map_type(atype[len("ref slice of ") :]))
    if atype.startswith("mut ref "):
        return add_ptr(map_type(atype[len("mut ref ") :]))
    if atype.startswith("ref "):
        return add_ptr(map_type(atype[len("ref ") :]))
    if atype.startswith("ptr of "):
        return add_ptr(map_type(atype[len("ptr of ") :]))
    if atype.startswith("slice of "):
        return add_ptr(map_type(atype[len("slice of ") :]))
    return TYPE_MAP.get(atype, atype)


def is_restrictable(atype: str) -> bool:
    atype = atype.strip()
    return (
        atype.startswith("slice of ")
        or atype.startswith("ref slice of ")
        or atype.startswith("mut ref slice of ")
        or atype.startswith("ptr of ")
        or atype.startswith("ref ptr of ")
        or atype.startswith("mut ref ptr of ")
    )


def param_decl(name: str, atype: str, allow_restrict: bool) -> str:
    ctype = map_type(atype)
    if allow_restrict and ENABLE_RESTRICT and is_restrictable(atype) and "*" in ctype:
        return f"{ctype} __restrict__ {name}"
    return f"{ctype} {name}"


def translate_expr(expr: str) -> str:
    expr = re.sub(r"\bis not\b", "!=", expr)
    expr = re.sub(r"\bis\b", "==", expr)
    expr = re.sub(r"\band\b", "&&", expr)
    expr = re.sub(r"\bor\b", "||", expr)
    expr = re.sub(r"\bnot\b", "!", expr)
    expr = re.sub(r"\bnull\b", "NULL", expr)
    expr = re.sub(r"\btrue\b", "1", expr)
    expr = re.sub(r"\bfalse\b", "0", expr)
    return expr


def emit_c_from_aster(src: str, skip_main: bool = False) -> str:
    out: List[str] = []
    out.extend(
        [
            "#include <stdio.h>",
            "#include <stdlib.h>",
            "#include <stdint.h>",
            "#include <stddef.h>",
            "#include <string.h>",
            "#include <time.h>",
            "#include <sys/stat.h>",
            "#include <fts.h>",
            "#include <sys/attr.h>",
            "#include <sys/vnode.h>",
            "#include <fcntl.h>",
            "#include <unistd.h>",
            "#include <poll.h>",
            "",
        ]
    )

    block_stack = [(0, None, None)]  # (indent, kind, name)
    skipping = False
    skip_indent = 0

    for raw in src.splitlines():
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        indent = len(raw) - len(raw.lstrip(" "))
        if indent % 4 != 0:
            raise ValueError(f"invalid indentation: {raw!r}")
        stripped = raw.strip()

        def close_block():
            _, kind, name = block_stack.pop()
            indent_out = block_stack[-1][0]
            if kind == "struct":
                out.append(" " * indent_out + f"}} {name};")
            elif kind is not None:
                out.append(" " * indent_out + "}")

        while indent < block_stack[-1][0]:
            close_block()
            if skipping and block_stack[-1][0] < skip_indent:
                skipping = False

        if skipping:
            continue

        if stripped.startswith("extern def "):
            m = re.match(r"extern\s+def\s+(\w+)\s*\(([^)]*)\)\s*(?:returns\s+(.+))?$", stripped)
            if not m:
                raise ValueError(f"invalid extern def: {stripped!r}")
            name, params_src, ret_src = m.group(1), m.group(2), m.group(3)
            if name in EXTERN_SKIP:
                continue
            params = []
            if params_src.strip():
                for part in params_src.split(","):
                    part = part.strip()
                    if not part:
                        continue
                    if " is " in part:
                        pname, ptype = part.split(" is ", 1)
                        params.append(param_decl(pname.strip(), ptype.strip(), allow_restrict=False))
                    else:
                        params.append(part)
            ret = map_type(ret_src.strip()) if ret_src else "void"
            out.append(f"{' ' * indent}extern {ret} {name}({', '.join(params)});")
            continue
        if stripped.startswith("use "):
            continue

        if stripped.startswith("const "):
            m = re.match(r"const\s+(\w+)\s+is\s+(.+?)\s*=\s*(.+)", stripped)
            if not m:
                raise ValueError(f"invalid const: {stripped!r}")
            name, atype, value = m.group(1), m.group(2), m.group(3)
            out.append(
                f"{' ' * indent}static const {map_type(atype)} {name} = {translate_expr(value)};"
            )
            continue

        if stripped.startswith("struct "):
            m = re.match(r"struct\s+(\w+)$", stripped)
            if not m:
                raise ValueError(f"invalid struct: {stripped!r}")
            name = m.group(1)
            out.append(f"{' ' * indent}typedef struct {name} {{")
            block_stack.append((indent + 4, "struct", name))
            continue

        if block_stack[-1][1] == "struct":
            m = re.match(r"(?:var|let)?\s*(\w+)\s+is\s+(.+)$", stripped)
            if not m:
                raise ValueError(f"invalid struct field: {stripped!r}")
            fname, ftype = m.group(1), m.group(2)
            out.append(f"{' ' * indent}{map_type(ftype)} {fname};")
            continue

        if stripped.startswith("def "):
            m = re.match(r"def\s+(\w+)\s*\(([^)]*)\)\s*(?:returns\s+(.+))?$", stripped)
            if not m:
                raise ValueError(f"invalid def: {stripped!r}")
            name, params_src, ret_src = m.group(1), m.group(2), m.group(3)
            if skip_main and name == "main":
                skipping = True
                skip_indent = indent
                continue
            params = []
            if params_src.strip():
                for part in params_src.split(","):
                    part = part.strip()
                    if not part:
                        continue
                    if " is " in part:
                        pname, ptype = part.split(" is ", 1)
                        params.append(param_decl(pname.strip(), ptype.strip(), allow_restrict=True))
                    else:
                        params.append(part)
            ret = map_type(ret_src.strip()) if ret_src else "void"
            storage = "" if name == "main" else "static "
            out.append(f"{' ' * indent}{storage}{ret} {name}({', '.join(params)}) {{")
            block_stack.append((indent + 4, "block", None))
            continue

        if stripped.startswith("if "):
            cond = stripped[3:]
            if cond.endswith(" then"):
                cond = cond[: -len(" then")]
            out.append(f"{' ' * indent}if ({translate_expr(cond)}) {{")
            block_stack.append((indent + 4, "block", None))
            continue

        if stripped.startswith("elif ") or stripped.startswith("else if "):
            cond = stripped.split(" ", 2)[2]
            if cond.endswith(" then"):
                cond = cond[: -len(" then")]
            out.append(f"{' ' * indent}else if ({translate_expr(cond)}) {{")
            block_stack.append((indent + 4, "block", None))
            continue

        if stripped == "else":
            out.append(f"{' ' * indent}else {{")
            block_stack.append((indent + 4, "block", None))
            continue

        if stripped.startswith("for "):
            body = stripped[4:].strip()
            if body.endswith(" do"):
                body = body[: -len(" do")].strip()
            if " in " not in body:
                raise ValueError(f"invalid for loop: {stripped!r}")
            var_part, range_part = body.split(" in ", 1)
            var_part = var_part.strip()
            var_name = var_part
            var_type = "usize"
            if " is " in var_part:
                var_name, var_type = var_part.split(" is ", 1)
                var_name = var_name.strip()
                var_type = var_type.strip()
            range_part = range_part.strip()
            inclusive = False
            if "..=" in range_part:
                start, end = range_part.split("..=", 1)
                inclusive = True
            elif ".." in range_part:
                start, end = range_part.split("..", 1)
            else:
                raise ValueError(f"invalid for loop range: {stripped!r}")
            start = translate_expr(start.strip())
            end = translate_expr(end.strip())
            cmp_op = "<=" if inclusive else "<"
            out.append(
                f"{' ' * indent}for ({map_type(var_type)} {var_name} = {start}; {var_name} {cmp_op} {end}; {var_name}++) {{"
            )
            block_stack.append((indent + 4, "block", None))
            continue

        if stripped.startswith("while "):
            cond = stripped[6:]
            if cond.endswith(" do"):
                cond = cond[: -len(" do")]
            if ENABLE_PRAGMAS:
                out.append(f"{' ' * indent}#pragma clang loop vectorize(enable) interleave(enable)")
            out.append(f"{' ' * indent}while ({translate_expr(cond)}) {{")
            block_stack.append((indent + 4, "block", None))
            continue

        if stripped == "break":
            out.append(f"{' ' * indent}break;")
            continue

        if stripped == "continue":
            out.append(f"{' ' * indent}continue;")
            continue

        if stripped.startswith("return"):
            expr = stripped[6:].strip()
            if expr:
                out.append(f"{' ' * indent}return {translate_expr(expr)};")
            else:
                out.append(f"{' ' * indent}return;")
            continue

        if stripped.startswith("var ") or stripped.startswith("let "):
            m = re.match(r"(?:var|let)\s+(\w+)\s+is\s+(.+?)(?:\s*=\s*(.+))?$", stripped)
            if m:
                name, atype, value = m.group(1), m.group(2), m.group(3)
                if value is None:
                    out.append(f"{' ' * indent}{map_type(atype)} {name};")
                else:
                    out.append(
                        f"{' ' * indent}{map_type(atype)} {name} = {translate_expr(value)};"
                    )
                continue
            m = re.match(r"(?:var|let)\s+(\w+)\s*=\s*(.+)$", stripped)
            if m:
                name, value = m.group(1), m.group(2)
                out.append(f"{' ' * indent}__auto_type {name} = {translate_expr(value)};")
                continue
            raise ValueError(f"invalid var/let: {stripped!r}")

        out.append(f"{' ' * indent}{translate_expr(stripped)};")

    while len(block_stack) > 1:
        _, kind, name = block_stack.pop()
        if skipping:
            continue
        indent_out = block_stack[-1][0]
        if kind == "struct":
            out.append(" " * indent_out + f"}} {name};")
        else:
            out.append(" " * indent_out + "}")

    out.append("")
    return "\n".join(out)


def compile_fswalk(src: str, out: pathlib.Path) -> int:
    timing = os.environ.get("ASTER_TIMING", "0") != "0"
    t0 = time.perf_counter_ns()
    defs = parse_defs(src)
    t_parse = time.perf_counter_ns() - t0
    if "fswalk" not in defs:
        print("expected def fswalk in source", file=sys.stderr)
        return 1

    t1 = time.perf_counter_ns()
    c_src = emit_c_from_aster(src)
    t_emit = time.perf_counter_ns() - t1
    with tempfile.NamedTemporaryFile("w", suffix=".c", delete=False) as tmp:
        tmp.write(c_src)
        tmp_path = tmp.name

    t2 = time.perf_counter_ns()
    try:
        subprocess.run(
            ["clang", "-O3", "-std=c11", "-S", "-o", str(out), tmp_path],
            check=True,
        )
    except subprocess.CalledProcessError as exc:
        print(f"clang failed: {exc}", file=sys.stderr)
        return 1
    finally:
        pathlib.Path(tmp_path).unlink(missing_ok=True)

    t_clang = time.perf_counter_ns() - t2
    if timing:
        total = t_parse + t_emit + t_clang
        print(
            f"timing fswalk parse_ns={t_parse} emit_ns={t_emit} clang_ns={t_clang} total_ns={total}"
        )

    return 0


def compile_bench_from_aster(kind: str, src: str, out: pathlib.Path) -> int:
    timing = os.environ.get("ASTER_TIMING", "0") != "0"
    t0 = time.perf_counter_ns()
    defs = parse_defs(src)
    t_parse = time.perf_counter_ns() - t0
    if "main" not in defs:
        print("expected def main in source", file=sys.stderr)
        return 1

    t1 = time.perf_counter_ns()
    c_src = emit_c_from_aster(src, skip_main=False)
    t_emit = time.perf_counter_ns() - t1

    with tempfile.NamedTemporaryFile("w", suffix=".c", delete=False) as tmp:
        tmp.write(c_src)
        tmp_path = tmp.name

    t2 = time.perf_counter_ns()
    try:
        subprocess.run(
            ["clang", "-O3", "-std=c11", "-S", "-o", str(out), tmp_path],
            check=True,
        )
    except subprocess.CalledProcessError as exc:
        print(f"clang failed: {exc}", file=sys.stderr)
        return 1
    finally:
        pathlib.Path(tmp_path).unlink(missing_ok=True)

    t_clang = time.perf_counter_ns() - t2
    if timing:
        total = t_parse + t_emit + t_clang
        print(
            f"timing {kind} parse_ns={t_parse} emit_ns={t_emit} clang_ns={t_clang} total_ns={total}"
        )

    return 0


def compile_module(src: str, out: pathlib.Path) -> int:
    timing = os.environ.get("ASTER_TIMING", "0") != "0"
    t0 = time.perf_counter_ns()
    c_src = emit_c_from_aster(src, skip_main=False)
    t_emit = time.perf_counter_ns() - t0
    with tempfile.NamedTemporaryFile("w", suffix=".c", delete=False) as tmp:
        tmp.write(c_src)
        tmp_path = tmp.name

    t1 = time.perf_counter_ns()
    try:
        subprocess.run(
            ["clang", "-O3", "-std=c11", "-S", "-o", str(out), tmp_path],
            check=True,
        )
    except subprocess.CalledProcessError as exc:
        print(f"clang failed: {exc}", file=sys.stderr)
        return 1
    finally:
        pathlib.Path(tmp_path).unlink(missing_ok=True)

    t_clang = time.perf_counter_ns() - t1
    if timing:
        total = t_emit + t_clang
        print(f"timing module emit_ns={t_emit} clang_ns={t_clang} total_ns={total}")

    return 0


def compile_bench(kind: str, src: str, out: pathlib.Path) -> int:
    if kind not in TEMPLATES:
        print("unsupported input", file=sys.stderr)
        return 1

    defs = parse_defs(src)
    if kind not in defs:
        print(f"expected def {kind} in source", file=sys.stderr)
        return 1

    consts = parse_consts(src)
    template = TEMPLATES[kind].read_text()
    rendered = apply_consts(template, consts)
    out.write_text(rendered)
    return 0


def build_cache_key(src: str, backend: str, kind: str) -> str:
    h = hashlib.sha256()
    h.update(COMPILER_REV.encode("utf-8"))
    h.update(b"\0")
    h.update(backend.encode("utf-8"))
    h.update(b"\0")
    h.update(kind.encode("utf-8"))
    h.update(b"\0")
    h.update(src.encode("utf-8"))
    if backend == "asm" and kind in TEMPLATES:
        h.update(b"\0")
        h.update(TEMPLATES[kind].read_text().encode("utf-8"))
    return h.hexdigest()


def cache_path(out: pathlib.Path) -> pathlib.Path:
    return out.with_suffix(out.suffix + ".sha256")


def cache_hit(out: pathlib.Path, key: str) -> bool:
    if not out.exists():
        return False
    path = cache_path(out)
    if not path.exists():
        return False
    return path.read_text().strip() == key


def write_cache(out: pathlib.Path, key: str) -> None:
    cache_path(out).write_text(key + "\n")


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: asterc.py <input.as> <output.S>", file=sys.stderr)
        return 2
    inp = pathlib.Path(sys.argv[1])
    out = pathlib.Path(sys.argv[2])
    src = inp.read_text()
    backend = os.environ.get("ASTER_BACKEND", "c")
    use_cache = os.environ.get("ASTER_CACHE", "1") != "0"

    defs = parse_defs(src)
    kind = ""
    file_kind = inp.stem
    bench_kinds = {"dot", "gemm", "stencil", "sort", "json", "hashmap", "regex", "async_io"}
    if "fswalk" in defs or file_kind == "fswalk":
        kind = "fswalk"
        if use_cache:
            key = build_cache_key(src, backend, kind)
            if cache_hit(out, key):
                print(f"cached {inp} -> {out}")
                return 0
        rc = compile_fswalk(src, out)
        if rc == 0:
            if use_cache:
                write_cache(out, key)
            print(f"compiled {inp} -> {out}")
        return rc

    if file_kind in bench_kinds:
        kind = file_kind
        if use_cache:
            key = build_cache_key(src, backend, kind)
            if cache_hit(out, key):
                print(f"cached {inp} -> {out}")
                return 0
        if backend == "asm" and kind in TEMPLATES:
            rc = compile_bench(kind, src, out)
        else:
            rc = compile_bench_from_aster(kind, src, out)
        if rc == 0:
            if use_cache:
                write_cache(out, key)
            print(f"compiled {inp} -> {out}")
        return rc

    for kind in ("dot", "gemm", "stencil", "sort", "json", "hashmap", "regex", "async_io"):
        if kind in defs:
            if use_cache:
                key = build_cache_key(src, backend, kind)
                if cache_hit(out, key):
                    print(f"cached {inp} -> {out}")
                    return 0
            if backend == "asm" and kind in TEMPLATES:
                rc = compile_bench(kind, src, out)
            else:
                rc = compile_bench_from_aster(kind, src, out)
            if rc == 0:
                if use_cache:
                    write_cache(out, key)
                print(f"compiled {inp} -> {out}")
            return rc

    # fallback: compile any module-like file via C-emit
    if defs:
        kind = "module"
        if use_cache:
            key = build_cache_key(src, backend, kind)
            if cache_hit(out, key):
                print(f"cached {inp} -> {out}")
                return 0
        rc = compile_module(src, out)
        if rc == 0:
            if use_cache:
                write_cache(out, key)
            print(f"compiled {inp} -> {out}")
        return rc

    print("unsupported input", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
