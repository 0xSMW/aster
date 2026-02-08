# Aster Sample Apps

These are small, runnable Aster programs that exercise core language/runtime
capabilities.

## Run

Use the Aster CLI (recommended, handles `use` imports):
```bash
tools/aster/aster run aster/apps/hello/hello.as
tools/aster/aster run aster/apps/time_demo/time_demo.as
tools/aster/aster run aster/apps/panic_demo/panic_demo.as
FS_ROOT=. tools/aster/aster run aster/apps/fs_count/fs_count.as
tools/aster/aster run aster/apps/http_get_llms_txt/http_get_llms_txt.as
tools/aster/aster run aster/apps/openai_chat_stream/openai_chat_stream.as
```

## Apps

- `aster/apps/hello/hello.as`: minimal `use core.io` + `println`.
- `aster/apps/time_demo/time_demo.as`: monotonic time via `core.time`.
- `aster/apps/panic_demo/panic_demo.as`: panic path via `core.panic` (prints a best-effort stack trace).
- `aster/apps/fs_count/fs_count.as`: fts traversal via `core.fs` (counts files/dirs).
- `aster/apps/http_get_llms_txt/http_get_llms_txt.as`: HTTPS GET of `https://platform.openai.com/docs/llms.txt`.
- `aster/apps/openai_chat_stream/openai_chat_stream.as`: OpenAI-style streaming chat completions (SSE) over HTTPS (requires `OPENAI_API_KEY`).
