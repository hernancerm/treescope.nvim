# CLAUDE.md

## Commands

`make ci` runs formatting, docs and tests. Run one test file with:

```sh
nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run_file('tests/test_function.lua')"
```

Print the `:InspectTree` output for a snippet:

```sh
printf 'function f() return 1 end\n' | nvim --headless -n -u ./scripts/minimal_init.lua -c 'set ft=lua' -c 'lua vim.treesitter.inspect_tree(); io.write(table.concat(vim.api.nvim_buf_get_lines(0,0,-1,false),"\n").."\n")' -c 'qa!' -
```

## Gotchas

- `doc/treescope.txt` is generated from comments in `lua/treescope/init.lua`. Edit those, then run `make docs`.
- Private helpers in `init.lua` need `---@private`, or they end up in the help file.
- `lang` in `provider_locator.lua` feeds both `vim.treesitter.get_parser()` and `vim.treesitter.query.get()`. A wrong name silently yields an empty scope.
- Scope ids in `const.ScopeIds` must match the module names under `scopes/` and the directory names under `providers/`.

## Adding a language to a node scope (`function`, `class`, `code_fence`)

1. `lua/treescope/providers/<scope_id>/<lang>.lua`: implement `NodeScopeProvider`.
2. `queries/<lang>/treescope.scm`: capture name identifiers with `@treescope_<scope_id>`.
3. `lua/treescope/provider_locator.lua`: add the filetype under the scope id in `registry`.
4. `tests/resources/<scope_id>/<lang>.txt`: resource file with cursor markers covering all patterns.
5. `tests/test_<scope_id>.lua`: test cases table and `create_language_test_set` call.

## Adding a new scope

1. Add the id to `const.ScopeIds`.
2. Add `lua/treescope/scopes/<id>.lua`. For a node scope, copy `scopes/function.lua` and change the capture name.
3. Add providers under `lua/treescope/providers/<id>/` and the filetypes to `registry` in `provider_locator.lua`.
4. Document the scope under `treescope-scopes` in `init.lua` and run `make docs`.
