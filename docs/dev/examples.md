# Examples (Apps + Small Programs)

Runnable examples live under `aster/apps/`.

Most examples can be run either:

1. Via the project CLI (`tools/aster/aster`), which supports `ASTER_CACHE=1`.
2. By compiling directly with `tools/build/asterc.sh`.

## Hello World

Source: `aster/apps/hello/hello.as`

```bash
ASTER_CACHE=1 tools/aster/aster run aster/apps/hello/hello.as
```

Or:

```bash
bash tools/build/build.sh asm/driver/asterc.S
tools/build/asterc.sh aster/apps/hello/hello.as /tmp/hello
/tmp/hello
```

## Filesystem Traversal

Count files and dirs (fts traversal):

Source: `aster/apps/fs_count/fs_count.as`

```bash
FS_ROOT=. ASTER_CACHE=1 tools/aster/aster run aster/apps/fs_count/fs_count.as
```

## HTTPS GET

Fetch `llms.txt` (TLS+HTTP client):

Source: `aster/apps/http_get_llms_txt/http_get_llms_txt.as`

```bash
ASTER_CACHE=1 tools/aster/aster run aster/apps/http_get_llms_txt/http_get_llms_txt.as
```

## OpenAI-Style Streaming Demo

Streaming SSE client example:

Source: `aster/apps/openai_chat_stream/openai_chat_stream.as`

This app expects environment configuration (API keys, etc.). Read the header
comment in the source for the current knobs.

## ML Bring-Up

ML is under `src/aster_ml/` with tests under `aster/tests/pass/` and a
deterministic golden-vector harness:

```bash
bash tools/ml/run.sh
bash tools/ml/bench/run.sh
```

See `docs/ml/README.md`.

## Writing Your Own Small Program

If you want to write a single-file program that uses stdlib modules:

```aster
use core.io

def main() returns i32
    println("ok")
    return 0
```

Compile and run:

```bash
tools/build/asterc.sh /path/to/main.as /tmp/a
/tmp/a
```

