# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `get_text()`: the scope text as a string, empty when there is none. Meant for the statusline:
  `%{v:lua.Treescope.get_text('function')}`.

### Removed

- **Breaking:** `setup()` and `config.buf_vars`. Replace `%{get(b:,'treescope_function','')}` with
  `%{v:lua.Treescope.get_text('function')}` in 'statusline', and delete the `setup()` call.

### Fixed

- The statusline example in the help file used `${...}` instead of `%{...}`.

## [0.1.0] - 2026-09-26

### Added

- Scopes relative to the cursor position, powered by Tree-sitter:
  - `function`: Clojure, Java, JavaScript, JSX, Lua, Python, TypeScript, TSX.
  - `class`: Java, JavaScript, Python, TypeScript.
  - `code_fence`: Markdown.
  - `namespace`: Clojure, Java.
  - `yq_path`: JSON, JSONC, YAML.
- Navigation between functions, classes and code fences (`goto_prev`, `goto_next`, loclist).
- Buf vars with the current scope, for use in the statusline.
- `:checkhealth treescope` to report missing parsers.

[Unreleased]: https://github.com/hernancerm/treescope.nvim/compare/0.1.0...HEAD
[0.1.0]: https://github.com/hernancerm/treescope.nvim/releases/tag/0.1.0
