# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this plugin does

`treescope.nvim` is a Neovim plugin that uses Tree-sitter to expose cursor scope information via a Lua API and optional buffer variables. The three scopes are:

- `outermost_function` — name of the outermost function/method enclosing the cursor
- `yq_path` — yq filter expression for the cursor position in YAML/JSON files
- `namespace` — the namespace/package declared at the top of the file (Clojure `ns`, Java `package`)

## Commands

```sh
make test      # Run all tests (headless Neovim + mini.test)
make testfmt   # Check formatting with stylua
make testdocs  # Check docs are up to date
make testci    # Run all CI checks (fmt + docs + tests)
make fmt       # Format code with stylua
make docs      # Regenerate doc/treescope.txt from inline comments
```

Dependencies (`deps/lua/`) are downloaded on first `make test` / `make docs`. Tree-sitter parsers are downloaded automatically during tests via nvim-treesitter and cached in `deps/parsers/`.

To run a single test file:
```sh
nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run_file('tests/test_e2e_outermost_function.lua')"
```

## Architecture

### Public API (`lua/treescope/init.lua`)

All three public functions (`outermost_function()`, `yq_path()`, `namespace()`) are thin wrappers that delegate immediately to the corresponding `scopes/` module (e.g. `require("treescope.scopes.outermost_function").get_value()`).

`treescope.setup()` registers `CursorMoved` autocmds (via `vars_service`) that keep buf vars like `b:treescope_outermost_function` up to date. After setup, the module is also exported as `_G.Treescope` so statusline integrations can call it without a `require()`.

### Scopes layer (`lua/treescope/scopes/`)

Each scope has its own module (`outermost_function.lua`, `yq_path.lua`, `namespace.lua`) that owns the full logic flow:
1. Validate buffer and filetype
2. Ask `provider_locator` for the right provider and Tree-sitter language name
3. Parse the Tree-sitter tree and find the cursor node
4. Delegate to the provider

`scopes/outermost_function.lua` is significantly heavier than the other two: it also builds and returns the `goto_prev`, `goto_next`, and `set_loclist` closures. These use `vim.treesitter.query.get(lang, "treescope")` to iterate all `@treescope_outermost_function` captures, resolve each to its outermost function node via the provider, and walk the sorted list to find the target. `yq_path.lua` and `namespace.lua` are simpler: they return `{ text = ... }` and delegate directly to their provider.

### Provider system

`lua/treescope/provider_locator.lua` maps filetypes to provider modules under `lua/treescope/providers/`.

Provider directories:
- `providers/outermost_function/` — one file per language (`lua`, `java`, `python`, `clojure`, `javascript`). Each implements the `OutermostFunctionProvider` interface: `is_function(node)`, `get_function_name(node, bufnr)`, and an optional `normalize_outermost_node(node)` (maps identifier nodes to their canonical function node so all cursor positions within the same function agree on the same TSNode).
- `providers/yq_path/` — `yaml`, `json`. Each implements `get_path(node, bufnr)`.
- `providers/namespace/` — `clojure.lua`, `java.lua`. Each implements `get_namespace(root, bufnr)`.

Interface definitions (for type checking only) live in `lua/treescope/interfaces/`.

Some filetypes share existing providers rather than having their own files: TypeScript, JSX (`javascriptreact`) and TSX (`typescriptreact`) all use the JavaScript provider, and JSONC uses the JSON provider. This is handled by the alias tables in `provider_locator.lua`, which also map the filetype to the tree-sitter language name where the two differ — `javascriptreact` → `javascript`, `typescriptreact` → `tsx`, `jsonc` → `json`. Getting that language name right matters: the scopes layer feeds it to both `vim.treesitter.get_parser()` and `vim.treesitter.query.get()`, so a filetype name that is not a parser name silently yields an empty scope.

TypeScript has its own `queries/typescript/treescope.scm` because it has a distinct tree-sitter grammar. TSX has a distinct grammar too, but its node types are identical for these captures, so `queries/tsx/treescope.scm` is a one-line `; inherits: typescript`. JSX needs no query file: it parses with the `javascript` grammar.

### Tree-sitter queries (`queries/`)

Each supported `outermost_function` language has a `queries/<lang>/treescope.scm` file that captures function name identifiers with `@treescope_outermost_function`. These captures drive `goto_prev()`/`goto_next()` navigation: the scopes layer queries all captures, resolves each to its outermost function node via the provider, then walks the sorted match list to find the target boundary. All query files use `;;extends` so they extend nvim-treesitter's built-in queries for that language.

### Constants (`lua/treescope/const.lua`)

Defines the augroup name and the `ScopeIds` enum (`outermost_function`, `yq_path`, `namespace`). Scope IDs must stay in sync with the public function names on the `treescope` table.

### Tests

Tests use [mini.test](https://github.com/echasnovski/mini.test) and run in a child headless Neovim instance. Test files are in `tests/`, resource files (code snippets with cursor markers) are in `tests/resources/`.

Two resource file patterns are used:

- **`outermost_function` and `yq_path`**: one file per language with embedded cursor markers (`-- cursor-3f7a2b1c`). The marker ID is the parametrize key; `h.set_cursor_from_marker(marker_id, child)` positions the cursor before each assertion. Markers can include an optional `[keys]` suffix (e.g., `-- cursor-3f7a2b1c[Ww]`) to execute normal-mode keystrokes after positioning.
- **`namespace`**: one file per test case in `tests/resources/namespace/<lang>/`. Each file has a single cursor marker and is opened individually per test.

### Adding a new `outermost_function` language

Touch these five places:
1. `lua/treescope/providers/outermost_function/<lang>.lua` — implement `is_function(node)`, `get_function_name(node, bufnr)`, and optionally `normalize_node(node)`.
2. `queries/<lang>/treescope.scm` — capture function name identifiers with `@treescope_outermost_function`. Use `;;extends`.
3. `lua/treescope/provider_locator.lua` — add the filetype to `supported_filetypes` and wire up the provider.
4. `tests/resources/outermost_function/<lang>.txt` — resource file with cursor markers covering all function patterns.
5. `tests/test_outermost_function.lua` — test cases table and `create_language_test_set` call.

### Docs

`doc/treescope.txt` is auto-generated by `mini.doc` from structured inline comments in `lua/treescope/init.lua`. Do not edit `doc/treescope.txt` directly; edit the source comments and run `make docs`.
