# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this plugin does

`treescope.nvim` is a Neovim plugin that uses Tree-sitter to expose "scopes" via a Lua API and optional buffer variables. A scope is a thing in the file, identified by a scope id:

- `function`: the function/method enclosing the cursor
- `class`: the class enclosing the cursor
- `namespace`: the namespace/package declared at the top of the file (Clojure `ns`, Java `package`)
- `yq_path`: yq filter expression for the cursor position in YAML/JSON files

`function` and `class` are "node scopes": found by walking the tree up from a position. They honor `depth` (`"outermost"`, the default, or `"any"` for the nearest) and support navigation. `namespace` and `yq_path` are read-only via `get()`.

## Commands

```sh
make test      # Run all tests (headless Neovim + mini.test)
make testfmt   # Check formatting with stylua
make testdocs  # Check docs are up to date
make ci        # Run all CI checks (fmt + docs + tests)
make fmt       # Format code with stylua
make docs      # Regenerate doc/treescope.txt from inline comments
```

Dependencies (`deps/`) are downloaded on first `make test` / `make docs`. Tree-sitter parsers are downloaded automatically during tests via nvim-treesitter and cached in `deps/parsers/`.

To run a single test file:
```sh
nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run_file('tests/test_function.lua')"
```

## Architecture

### Public API (`lua/treescope/init.lua`)

Six functions, each taking a scope id first: `get(id, opts)`, `list(id, opts)`, `goto_prev(id, opts)`, `goto_next(id, opts)`, `set_loclist(id, opts)`, `is_supported(id, opts)`. There is no per-scope sugar.

`get()` and `list()` return `treescope.Scope` tables: `{ text, node, name_node }`. `name_node` is where navigation lands (the identifier, not the definition start, so Java does not land on `private`).

`init.lua` owns the generic flow: validate the scope id, locate the provider, parse, resolve the position, then delegate to the scope module. `list()` is the navigation primitive: `goto_*` and `set_loclist` are built on it. Calling navigation on a scope whose module has no `list` warns via `vim.notify`.

`treescope.setup()` registers `CursorMoved` autocmds (via `vars_service`) that keep buf vars like `b:treescope_function` set to `get(id).text`. A `buf_vars` entry can be a table `{ id, depth = "any" }`, which yields `b:treescope_function_any`. After setup, the module is also exported as `_G.Treescope`.

### Scopes layer (`lua/treescope/scopes/`)

One module per scope id. Contract: `get(ctx, row, col, depth) -> Scope`, and optionally `list(ctx, depth) -> Scope[]`. `ctx` is `{ buf, lang, provider, root }`, built by `init.lua`. A scope without `list` does not support navigation, nothing else is needed to opt out.

`function.lua` and `class.lua` are two-liners over `lua/treescope/node_scope.lua`, which holds the shared upward walk and the query-driven `list()`. They differ only in the capture name they pass (`treescope_function`, `treescope_class`).

### Provider system

`lua/treescope/provider_locator.lua` is a single `registry` table: scope id, then filetype, then an optional `provider` module name and Tree-sitter `lang`. An empty entry means both are named after the filetype. Getting `lang` right matters: it is fed to both `vim.treesitter.get_parser()` and `vim.treesitter.query.get()`, so a wrong name silently yields an empty scope. Current aliases: `typescript` and the React filetypes use the JavaScript provider (`javascriptreact` → lang `javascript`, `typescriptreact` → lang `tsx`), `jsonc` uses the JSON provider with lang `json`.

Provider directories under `lua/treescope/providers/`:
- `function/`, `class/`: implement `NodeScopeProvider`: `is_scope_node(node, buf)`, `get_name_node(node, buf)`, optional `normalize_node(node)`. `normalize_node` maps stand-in nodes (e.g. the identifier in Lua's `foo = function() end`, which sits outside the definition's range) to the canonical definition node so all cursor positions agree on the same TSNode.
  The JavaScript provider also treats `describe`/`it`/`test`/`suite` callbacks as functions named by their title string, so vitest and jest files work with `depth = "any"` for the test under the cursor.
- `yq_path/`: `get_path(node, buf) -> string?`.
- `namespace/`: `get_namespace(root, buf) -> node?, name_node?`.

Interface definitions (for type checking only) live in `lua/treescope/interfaces/`.

### Tree-sitter queries (`queries/`)

`queries/<lang>/treescope.scm` captures name identifiers with `@treescope_function` and `@treescope_class`. These drive `list()`, and therefore all navigation: each capture is resolved to its scope node through the provider (honoring `depth`), then deduplicated by node start and sorted by name position. TypeScript has its own file because its grammar differs; `queries/tsx/treescope.scm` is a one-line `; inherits: typescript`. JSX needs no query file: it parses with the `javascript` grammar.

### Constants (`lua/treescope/const.lua`)

`ScopeIds` (`function`, `class`, `namespace`, `yq_path`) and `Depth` (`outermost`, `any`). Scope ids must match the module names under `scopes/` and the directory names under `providers/`.

### Tests

Tests use [mini.test](https://github.com/echasnovski/mini.test) and run in a child headless Neovim instance. Test files are in `tests/`, resource files (code snippets with cursor markers) are in `tests/resources/<scope_id>/`.

Two resource file patterns are used:

- **`function`, `class` and `yq_path`**: one file per language with embedded cursor markers (`-- cursor-3f7a2b1c`). The marker ID is the parametrize key; `h.set_cursor_from_marker(marker_id, child)` positions the cursor before each assertion. Markers can include an optional `[keys]` suffix (e.g., `-- cursor-3f7a2b1c[Ww]`) to execute normal-mode keystrokes after positioning.
- **`namespace`**: one file per test case in `tests/resources/namespace/<lang>/`. Each file has a single cursor marker and is opened individually per test.

`tests/test_navigation.lua` covers `list()`, `depth`, `goto_*`, `set_loclist` and the explicit `buf`/`pos` options, reusing the `function` and `class` resource files.

### Adding a new language to a node scope

Touch these five places:
1. `lua/treescope/providers/<scope_id>/<lang>.lua`: implement `NodeScopeProvider`.
2. `queries/<lang>/treescope.scm`: capture name identifiers with `@treescope_<scope_id>`.
3. `lua/treescope/provider_locator.lua`: add the filetype under the scope id in `registry`.
4. `tests/resources/<scope_id>/<lang>.txt`: resource file with cursor markers covering all patterns.
5. `tests/test_<scope_id>.lua`: test cases table and `create_language_test_set` call.

### Adding a new scope

1. Add the id to `const.ScopeIds`.
2. Add `lua/treescope/scopes/<id>.lua` with `get()`. For a node scope, copy `scopes/function.lua` and change the capture name; `list()` and navigation come for free once queries capture `@treescope_<id>`.
3. Add providers under `lua/treescope/providers/<id>/` and the filetypes to `registry` in `provider_locator.lua`.
4. Document the scope under `treescope-scopes` in `init.lua` and run `make docs`.

### Docs

`doc/treescope.txt` is auto-generated by `mini.doc` from structured inline comments in `lua/treescope/init.lua`. Do not edit `doc/treescope.txt` directly; edit the source comments and run `make docs`. Private helpers in `init.lua` must carry `---@private` or they end up in the help file.
