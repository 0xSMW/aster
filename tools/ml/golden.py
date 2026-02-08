#!/usr/bin/env python3
"""
Deterministic golden-vector generator using python tinygrad as the oracle.

This is NOT part of the Aster compiler/toolchain. It's an ML correctness harness.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
from dataclasses import dataclass
from typing import Any


def repo_root() -> str:
    return os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def add_tinygrad_to_path() -> None:
    # Use the repo-cloned reference tinygrad as the oracle.
    tg = os.path.join(repo_root(), "libraries", "tinygrad")
    sys.path.insert(0, tg)


def det_u32(seed: int, label: str, idx: int) -> int:
    b = f"{seed}:{label}:{idx}".encode("utf-8", errors="strict")
    h = hashlib.sha256(b).digest()
    return int.from_bytes(h[:4], "little", signed=False)


def det_f32(seed: int, label: str, idx: int) -> float:
    # Exactly-representable float32 values in [-1, +1] with step 1/1024.
    u = det_u32(seed, label, idx)
    v = int(u % 2049) - 1024  # [-1024, 1024]
    return float(v) / 1024.0


def flat_floats(seed: int, label: str, n: int) -> list[float]:
    return [det_f32(seed, label, i) for i in range(n)]


def reshape_2d(xs: list[float], r: int, c: int) -> list[list[float]]:
    assert len(xs) == r * c
    return [xs[i * c : (i + 1) * c] for i in range(r)]


@dataclass
class Case:
    name: str
    desc: str
    dtype: str
    x_shape: list[int]
    y_shape: list[int]
    x: Any
    y: Any
    out: Any
    x_grad: Any
    y_grad: Any


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--out", type=str, default=os.path.join(repo_root(), ".context", "ml", "golden.json"))
    ap.add_argument("--fuzz-cases", type=int, default=0)
    args = ap.parse_args()

    os.makedirs(os.path.dirname(args.out), exist_ok=True)

    # Some environments set DEBUG=true which breaks tinygrad's getenv(int) casts.
    for k in ("DEBUG", "IMAGE", "BEAM", "NOOPT"):
        v = os.environ.get(k)
        if v is None:
            os.environ[k] = "0"
        else:
            vv = v.strip()
            if not vv or any(ch not in "0123456789" for ch in vv):
                os.environ[k] = "0"

    add_tinygrad_to_path()
    from tinygrad import Tensor  # type: ignore
    from tinygrad.dtype import dtypes  # type: ignore

    cases: list[Case] = []

    # Case 1: add + sum (grad)
    {
        "name": "add_f32_2x3",
        "dtype": "float32",
        "shape": (2, 3),
    }
    x0 = reshape_2d(flat_floats(args.seed, "add:x", 6), 2, 3)
    y0 = reshape_2d(flat_floats(args.seed, "add:y", 6), 2, 3)
    x = Tensor(x0, dtype=dtypes.float32, requires_grad=True)
    y = Tensor(y0, dtype=dtypes.float32, requires_grad=True)
    z = (x + y).sum()
    z.backward()
    cases.append(
        Case(
            name="add_f32_2x3",
            desc="z=(x+y).sum(); grads should be ones",
            dtype="float32",
            x_shape=[2, 3],
            y_shape=[2, 3],
            x=x0,
            y=y0,
            out=z.item(),
            x_grad=x.grad.tolist() if x.grad is not None else None,
            y_grad=y.grad.tolist() if y.grad is not None else None,
        )
    )

    # Case 2: matmul + sum (grad)
    a0 = reshape_2d(flat_floats(args.seed, "matmul:a", 6), 2, 3)
    b0 = reshape_2d(flat_floats(args.seed, "matmul:b", 12), 3, 4)
    a = Tensor(a0, dtype=dtypes.float32, requires_grad=True)
    b = Tensor(b0, dtype=dtypes.float32, requires_grad=True)
    m = a.matmul(b).sum()
    m.backward()
    cases.append(
        Case(
            name="matmul_f32_2x3_3x4",
            desc="m=a.matmul(b).sum()",
            dtype="float32",
            x_shape=[2, 3],
            y_shape=[3, 4],
            x=a0,
            y=b0,
            out=m.item(),
            x_grad=a.grad.tolist() if a.grad is not None else None,
            y_grad=b.grad.tolist() if b.grad is not None else None,
        )
    )

    # Case 3: reshape + permute + sum (grad)
    t0 = flat_floats(args.seed, "permute:t", 24)
    t = Tensor(t0, dtype=dtypes.float32, requires_grad=True).reshape(2, 3, 4)
    u = t.permute(2, 0, 1).sum()
    u.backward()
    cases.append(
        Case(
            name="permute_f32_2x3x4",
            desc="u=t.reshape(2,3,4).permute(2,0,1).sum()",
            dtype="float32",
            x_shape=[2, 3, 4],
            y_shape=[],
            x=Tensor(t0, dtype=dtypes.float32, requires_grad=False).reshape(2, 3, 4).tolist(),
            y=None,
            out=u.item(),
            x_grad=t.grad.tolist() if t.grad is not None else None,
            y_grad=None,
        )
    )

    # Case 4: mul + sum (grad)
    x0 = reshape_2d(flat_floats(args.seed, "mul:x", 6), 2, 3)
    y0 = reshape_2d(flat_floats(args.seed, "mul:y", 6), 2, 3)
    x = Tensor(x0, dtype=dtypes.float32, requires_grad=True)
    y = Tensor(y0, dtype=dtypes.float32, requires_grad=True)
    z = (x * y).sum()
    z.backward()
    cases.append(
        Case(
            name="mul_f32_2x3",
            desc="z=(x*y).sum()",
            dtype="float32",
            x_shape=[2, 3],
            y_shape=[2, 3],
            x=x0,
            y=y0,
            out=z.item(),
            x_grad=x.grad.tolist() if x.grad is not None else None,
            y_grad=y.grad.tolist() if y.grad is not None else None,
        )
    )

    # Case 5: relu + sum (grad)
    t0 = reshape_2d(flat_floats(args.seed, "relu:t", 6), 2, 3)
    t = Tensor(t0, dtype=dtypes.float32, requires_grad=True)
    r = t.relu().sum()
    r.backward()
    cases.append(
        Case(
            name="relu_f32_2x3",
            desc="r=relu(t).sum()",
            dtype="float32",
            x_shape=[2, 3],
            y_shape=[],
            x=t0,
            y=None,
            out=r.item(),
            x_grad=t.grad.tolist() if t.grad is not None else None,
            y_grad=None,
        )
    )

    # Fuzz (shape-only for now; deterministic from seed)
    for fi in range(max(0, int(args.fuzz_cases))):
        # add (2D)
        r = 1 + (det_u32(args.seed, "fuzz:add:r", fi) % 4)
        c = 1 + (det_u32(args.seed, "fuzz:add:c", fi) % 4)
        x0 = reshape_2d(flat_floats(args.seed, f"fuzz:add:{fi}:x", r * c), r, c)
        y0 = reshape_2d(flat_floats(args.seed, f"fuzz:add:{fi}:y", r * c), r, c)
        x = Tensor(x0, dtype=dtypes.float32, requires_grad=True)
        y = Tensor(y0, dtype=dtypes.float32, requires_grad=True)
        z = (x + y).sum()
        z.backward()
        cases.append(
            Case(
                name=f"add_f32_{r}x{c}_fuzz{fi}",
                desc="fuzz: z=(x+y).sum()",
                dtype="float32",
                x_shape=[r, c],
                y_shape=[r, c],
                x=x0,
                y=y0,
                out=z.item(),
                x_grad=x.grad.tolist() if x.grad is not None else None,
                y_grad=y.grad.tolist() if y.grad is not None else None,
            )
        )

        # mul (2D)
        x0 = reshape_2d(flat_floats(args.seed, f"fuzz:mul:{fi}:x", r * c), r, c)
        y0 = reshape_2d(flat_floats(args.seed, f"fuzz:mul:{fi}:y", r * c), r, c)
        x = Tensor(x0, dtype=dtypes.float32, requires_grad=True)
        y = Tensor(y0, dtype=dtypes.float32, requires_grad=True)
        z = (x * y).sum()
        z.backward()
        cases.append(
            Case(
                name=f"mul_f32_{r}x{c}_fuzz{fi}",
                desc="fuzz: z=(x*y).sum()",
                dtype="float32",
                x_shape=[r, c],
                y_shape=[r, c],
                x=x0,
                y=y0,
                out=z.item(),
                x_grad=x.grad.tolist() if x.grad is not None else None,
                y_grad=y.grad.tolist() if y.grad is not None else None,
            )
        )

        # matmul (2D)
        m = 1 + (det_u32(args.seed, "fuzz:mm:m", fi) % 4)
        k = 1 + (det_u32(args.seed, "fuzz:mm:k", fi) % 4)
        n = 1 + (det_u32(args.seed, "fuzz:mm:n", fi) % 4)
        a0 = reshape_2d(flat_floats(args.seed, f"fuzz:mm:{fi}:a", m * k), m, k)
        b0 = reshape_2d(flat_floats(args.seed, f"fuzz:mm:{fi}:b", k * n), k, n)
        a = Tensor(a0, dtype=dtypes.float32, requires_grad=True)
        b = Tensor(b0, dtype=dtypes.float32, requires_grad=True)
        mm = a.matmul(b).sum()
        mm.backward()
        cases.append(
            Case(
                name=f"matmul_f32_{m}x{k}_{k}x{n}_fuzz{fi}",
                desc="fuzz: mm=a.matmul(b).sum()",
                dtype="float32",
                x_shape=[m, k],
                y_shape=[k, n],
                x=a0,
                y=b0,
                out=mm.item(),
                x_grad=a.grad.tolist() if a.grad is not None else None,
                y_grad=b.grad.tolist() if b.grad is not None else None,
            )
        )

        # relu (2D)
        t0 = reshape_2d(flat_floats(args.seed, f"fuzz:relu:{fi}:t", r * c), r, c)
        t = Tensor(t0, dtype=dtypes.float32, requires_grad=True)
        rr = t.relu().sum()
        rr.backward()
        cases.append(
            Case(
                name=f"relu_f32_{r}x{c}_fuzz{fi}",
                desc="fuzz: relu(t).sum()",
                dtype="float32",
                x_shape=[r, c],
                y_shape=[],
                x=t0,
                y=None,
                out=rr.item(),
                x_grad=t.grad.tolist() if t.grad is not None else None,
                y_grad=None,
            )
        )

        # permute (3D) with fixed axes (2,0,1)
        d0 = 1 + (det_u32(args.seed, "fuzz:perm:d0", fi) % 4)
        d1 = 1 + (det_u32(args.seed, "fuzz:perm:d1", fi) % 4)
        d2 = 1 + (det_u32(args.seed, "fuzz:perm:d2", fi) % 4)
        t0 = flat_floats(args.seed, f"fuzz:perm:{fi}:t", d0 * d1 * d2)
        t = Tensor(t0, dtype=dtypes.float32, requires_grad=True).reshape(d0, d1, d2)
        u = t.permute(2, 0, 1).sum()
        u.backward()
        cases.append(
            Case(
                name=f"permute_f32_{d0}x{d1}x{d2}_fuzz{fi}",
                desc="fuzz: t.reshape(...).permute(2,0,1).sum()",
                dtype="float32",
                x_shape=[d0, d1, d2],
                y_shape=[],
                x=Tensor(t0, dtype=dtypes.float32, requires_grad=False).reshape(d0, d1, d2).tolist(),
                y=None,
                out=u.item(),
                x_grad=t.grad.tolist() if t.grad is not None else None,
                y_grad=None,
            )
        )

    out = {
        "oracle": "python tinygrad",
        "seed": args.seed,
        "cases": [c.__dict__ for c in cases],
    }
    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(out, f, indent=2, sort_keys=True)

    print(args.out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
