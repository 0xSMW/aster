#!/usr/bin/env python3
import argparse
import hashlib
import json
import os
import pathlib
import subprocess
import sys
from typing import Dict, List, Set

ROOT = pathlib.Path(__file__).resolve().parents[2]

USE_RE = r"^use\s+([A-Za-z0-9_\.]+)"


def find_project_root(start: pathlib.Path) -> pathlib.Path:
    cur = start.resolve()
    if cur.is_file():
        cur = cur.parent
    for _ in range(8):
        if (cur / "aster.toml").exists():
            return cur
        if cur.parent == cur:
            break
        cur = cur.parent
    return start.resolve()


def module_to_path(root: pathlib.Path, module: str) -> pathlib.Path:
    rel = pathlib.Path("src") / pathlib.Path(module.replace(".", "/") + ".as")
    cand = root / rel
    if cand.exists():
        return cand
    alt = root / (module.replace(".", "/") + ".as")
    return alt


def read_deps(path: pathlib.Path) -> List[str]:
    deps: List[str] = []
    try:
        for line in path.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if line.startswith("use "):
                mod = line.split(None, 1)[1]
                deps.append(mod.strip())
    except FileNotFoundError:
        pass
    return deps


def file_hash(path: pathlib.Path) -> str:
    h = hashlib.sha256()
    data = path.read_bytes()
    h.update(data)
    return h.hexdigest()


def topo_sort(entry: str, root: pathlib.Path) -> List[str]:
    visited: Set[str] = set()
    temp: Set[str] = set()
    order: List[str] = []

    def visit(mod: str) -> None:
        if mod in visited:
            return
        if mod in temp:
            raise RuntimeError(f"cycle detected at {mod}")
        temp.add(mod)
        path = module_to_path(root, mod)
        for dep in read_deps(path):
            visit(dep)
        temp.remove(mod)
        visited.add(mod)
        order.append(mod)

    visit(entry)
    return order


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    parser.add_argument("--entry", required=True, help="module path like foo.bar")
    parser.add_argument("--out", default=".aster_build")
    parser.add_argument("--backend", default=os.environ.get("ASTER_BACKEND", "c"))
    parser.add_argument("--cache", default="1")
    args = parser.parse_args()

    root = find_project_root(pathlib.Path(args.root))
    out_dir = pathlib.Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    cache_path = out_dir / ".aster_build_cache.json"
    cache: Dict[str, Dict[str, str]] = {}
    if cache_path.exists() and args.cache != "0":
        cache = json.loads(cache_path.read_text())

    order = topo_sort(args.entry, root)
    compiled: Dict[str, str] = {}

    for mod in order:
        src_path = module_to_path(root, mod)
        if not src_path.exists():
            print(f"missing module {mod} at {src_path}", file=sys.stderr)
            return 1

        deps = read_deps(src_path)
        dep_hashes = "".join(compiled.get(d, "") for d in deps)
        fhash = file_hash(src_path)
        combined = hashlib.sha256((fhash + dep_hashes).encode("utf-8")).hexdigest()

        cached = cache.get(mod, {})
        if args.cache != "0" and cached.get("hash") == combined:
            compiled[mod] = combined
            continue

        out_path = out_dir / (mod.replace(".", "__") + ".S")
        env = os.environ.copy()
        env["ASTER_BACKEND"] = args.backend
        rc = subprocess.run(
            [str(ROOT / "tools" / "build" / "asterc.py"), str(src_path), str(out_path)],
            env=env,
        )
        if rc.returncode != 0:
            return rc.returncode

        cache[mod] = {"hash": combined, "src": str(src_path), "out": str(out_path)}
        compiled[mod] = combined

    cache_path.write_text(json.dumps(cache, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
