Build scripts and tooling for assembling and linking the compiler.

Key tools:
- `build.sh`: low-level asm build helper (compile+link an assembly entrypoint with the runtime/compiler objects).
- `asterc.sh`: wrapper that runs the real Aster compiler binary (`tools/build/out/asterc` by default).

The Aster compiler (`asterc`) is intended to be implemented in assembly under
`asm/driver/` and built to `tools/build/out/asterc`.
