Next steps (2026-01-31)

- Implement `aster_span` core types (FileId, Span, SourceMap) with line/column mapping.
- Implement `aster_diagnostics` (diagnostic structs, error codes, span rendering).
- Implement indentation-aware lexer with spans and INDENT/DEDENT handling.
- Implement CST parser with precedence and error recovery per EBNF.
- Implement `aster_ast` data model and CST->AST lowering.
- Add frontend tests for lexer/parser edge cases.
- Draft `asterfmt` deterministic formatting over CST.
