# Aster assembly conventions

This document defines the conventions for assembly code and macro usage in the
compiler, runtime, and tooling.

## 1. File layout

- Assembly source: `.S` (preprocessed assembly via clang)
- Macro includes: `.inc`
- One module per file; file name matches module path.
- Macros live under `asm/macros` and are included explicitly.

## 2. Naming and labels

- Global symbols use `aster_<module>__<symbol>`.
- Local labels use `.L<name>` and are never exported.
- Runtime entry points use `aster_rt__<name>`.
- v1 macros assume Mach-O symbol prefixing (leading underscore); ELF support will use separate includes.

## 3. Macro naming

- Macros are uppercase: `FUNC_BEGIN`, `FUNC_END`, `ALIGN`, `EXPORT`.
- Macros are side-effect free except for the documented clobbers.
- Each macro documents required registers and stack usage.

## 4. Register aliases

- Use macro aliases for argument and return registers: `ARG0`, `ARG1`, `RET0`.
- The arch-specific include maps aliases to physical registers.

## 5. Stack discipline

- Stack is 16-byte aligned at all call boundaries.
- Prologue and epilogue use macros to ensure consistent frame layout.
- Leaf functions may omit frame pointers when safe.

## 6. Sections and data

- Use macros to switch sections: `SECTION_TEXT`, `SECTION_RODATA`.
- String literals use `STRZ` for null-terminated data.
- All data uses explicit alignment via `ALIGN`.

## 7. Arch-specific includes

- `asm/macros/abi_x86_64.inc` maps argument and callee-saved registers.
- `asm/macros/abi_arm64.inc` maps argument and callee-saved registers.
- Shared macros are defined in `asm/macros/base.inc`.
