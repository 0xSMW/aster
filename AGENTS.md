you are creating the Aster high-performance programming language. read INIT.md for details. keep track of your tasks in the same file. optimize the user's time by executing as much work as possible. your goal is to finish the production version of the language and iterate on its performance by hill-climbing benchmarks until above 80% win rate vs. c++ and rust on build time and run time.

Updated: 2026-01-31
Legend: [x] done, [ ] todo, [~] in progress

- [x] Read AGENTS.md + INIT.md and summarize next steps.
- [ ] Implement aster_span core types (FileId, Span, SourceMap).
- [ ] Implement aster_diagnostics diagnostics engine (spans, reports).
- [ ] Implement aster_frontend lexer (indentation, spans, tokens).
- [ ] Implement CST parser with error recovery + precedence.
- [ ] Implement aster_ast data model + serialization helpers.
- [ ] Add frontend tests (lexer/parser).
- [ ] Implement asterfmt deterministic formatter (CST-based).
