# Implementation Plan: Hybrid Navigation for `outermost_function`

## Background

`treescope.outermost_function()` currently returns `string?`. It will be changed to always return a table:

```lua
{
  text = string?,               -- nil when cursor is outside any function
  goto_next = function() end,   -- jumps to next outermost function; no-op if none
  goto_prev = function() end,   -- jumps to prev outermost function; no-op if none
}
```

Navigation uses a hybrid approach:
1. Tree-sitter queries (`queries/<lang>/treescope.scm`) enumerate candidate function name positions in the buffer.
2. The existing tree-walking logic (via providers) resolves the outermost function from any given position.

The tree-walking already happens from the cursor for `text`. For `goto_prev`/`goto_next`, the same tree-walking is run from a query match position.

---

## Files to change

1. `lua/treescope/scopes_service.lua` — main logic changes
2. `lua/treescope/vars_service.lua` — minor: extract `.text` from table result
3. `lua/treescope/init.lua` — doc/annotation update
4. `tests/test_e2e_outermost_function.lua` — update existing tests + add navigation tests

No new files needed.

---

## 1. `lua/treescope/scopes_service.lua`

### 1a. Extract a private helper: `find_outermost_at`

This is the core tree-walking logic, currently inlined in `M.outermost_function()`. Pull it out as a module-local function that accepts an arbitrary `(row, col)` instead of always reading the cursor. Returns both the TSNode and the name string.

```lua
-- row and col are 0-indexed.
-- Returns: outermost_node (TSNode | nil), name (string | nil)
local function find_outermost_at(provider, root, bufnr, row, col)
  local node = root:named_descendant_for_range(row, col, row, col)
  if not node then return nil, nil end

  local candidate = nil
  local cur = node
  while cur do
    if provider.is_function(cur) then
      candidate = cur
    end
    cur = cur:parent()
  end

  if not candidate then return nil, nil end
  return candidate, provider.get_function_name(candidate, bufnr)
end
```

### 1b. Add a private helper: `get_query_matches`

Runs the `treescope` query for the given language against the already-parsed tree and returns all `@treescope_outermost_function` capture positions, sorted ascending.

```lua
-- Returns: list of { row = integer, col = integer }, 0-indexed, sorted ascending.
local function get_query_matches(root, bufnr, lang)
  local query = vim.treesitter.query.get(lang, "treescope")
  if not query then return {} end

  local matches = {}
  for id, node in query:iter_captures(root, bufnr, 0, -1) do
    if query.captures[id] == "treescope_outermost_function" then
      local row, col = node:start()
      table.insert(matches, { row = row, col = col })
    end
  end

  table.sort(matches, function(a, b)
    if a.row ~= b.row then return a.row < b.row end
    return a.col < b.col
  end)
  return matches
end
```

### 1c. Add a private helper: `make_goto_fns`

Builds the `goto_prev` and `goto_next` closures. Accepts the context needed for re-parsing. The closures capture `bufnr`, `lang`, and `provider`. They do **not** capture the outermost node from the outer call — they re-derive everything at call time from the then-current cursor position, because the buffer may have changed between when `outermost_function()` was called and when the keymap fires.

```lua
local function make_goto_fns(bufnr, lang, provider)
  local function resolve(direction)
    -- direction: "prev" or "next"
    local ok, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
    if not ok or not parser then return end
    local trees = parser:parse()
    if not trees or #trees == 0 then return end
    local root = trees[1]:root()
    if not root then return end

    local win = vim.api.nvim_get_current_win()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local cur_row, cur_col = cursor[1] - 1, cursor[2]  -- convert to 0-indexed

    -- Find the current outermost node to get the reference boundary.
    local cur_outermost = find_outermost_at(provider, root, bufnr, cur_row, cur_col)

    local ref_row, ref_col
    if direction == "prev" then
      if cur_outermost then
        ref_row, ref_col = cur_outermost:start()  -- boundary: start of current outermost
      else
        ref_row, ref_col = cur_row, cur_col
      end
    else  -- "next"
      if cur_outermost then
        ref_row, ref_col = cur_outermost:end_()   -- boundary: end of current outermost
      else
        ref_row, ref_col = cur_row, cur_col
      end
    end

    local all_matches = get_query_matches(root, bufnr, lang)

    local target_match = nil
    if direction == "prev" then
      -- Last match strictly before (ref_row, ref_col).
      for _, m in ipairs(all_matches) do
        if m.row < ref_row or (m.row == ref_row and m.col < ref_col) then
          target_match = m
          -- keep iterating; last one wins
        end
      end
    else
      -- First match strictly after (ref_row, ref_col).
      for _, m in ipairs(all_matches) do
        if m.row > ref_row or (m.row == ref_row and m.col > ref_col) then
          target_match = m
          break
        end
      end
    end

    if not target_match then return end

    local target_node = find_outermost_at(provider, root, bufnr, target_match.row, target_match.col)
    if not target_node then return end

    local jump_row, jump_col = target_node:start()
    vim.api.nvim_win_set_cursor(win, { jump_row + 1, jump_col })
  end

  return
    function() resolve("prev") end,
    function() resolve("next") end
end
```

Note: `cur_outermost:end_()` — Lua uses `end_()` because `end` is a reserved keyword.

### 1d. Rewrite `M.outermost_function()`

The new version always returns a table. When the filetype is unsupported or any setup step fails, it returns `{ text = nil, goto_prev = noop, goto_next = noop }`.

```lua
function M.outermost_function()
  local noop = function() end
  local default = { text = nil, goto_prev = noop, goto_next = noop }

  local bufnr = vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then return default end

  local filetype = vim.bo[bufnr].filetype
  if not filetype or filetype == "" then return default end

  local provider_locator = require("treescope.provider_locator")
  local provider, lang = provider_locator.get_outermost_function_provider(filetype)
  if not provider or not lang then return default end

  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_buf(win) ~= bufnr then return default end

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
  if not ok or not parser then return default end

  local trees = parser:parse()
  if not trees or #trees == 0 then return default end

  local root = trees[1]:root()
  if not root then return default end

  local cursor = vim.api.nvim_win_get_cursor(win)
  local row, col = cursor[1] - 1, cursor[2]

  local _, name = find_outermost_at(provider, root, bufnr, row, col)

  local goto_prev, goto_next = make_goto_fns(bufnr, lang, provider)

  return { text = name, goto_prev = goto_prev, goto_next = goto_next }
end
```

Remove the old inline logic. The tree-walking is now entirely in `find_outermost_at`.

---

## 2. `lua/treescope/vars_service.lua`

The autocmd callback currently does:

```lua
treescope[scope_id]() or ""
```

`outermost_function()` now returns a table, so the `or ""` fallback and direct use of the return value will break. Update the callback to extract `.text` when the result is a table:

```lua
callback = function()
  local result = treescope[scope_id]()
  local value
  if type(result) == "table" then
    value = result.text
  else
    value = result
  end
  vim.api.nvim_buf_set_var(0, "treescope_" .. scope_id, value or "")
end
```

`yq_path()` and `namespace()` still return `string?`, so the `type(result) == "table"` branch is future-safe and doesn't break those.

---

## 3. `lua/treescope/init.lua`

Update the `outermost_function` function doc block:

- Change `@return string?` to `@return { text: string?, goto_prev: function, goto_next: function }`.
- Update the prose description to mention that the return value is a table, that `.text` holds the name, and that `.goto_prev()` / `.goto_next()` navigate to the previous/next outermost function boundary (no-op if none exists).
- Update the inline example in the quickstart section that references `require("treescope").outermost_function()` to show `.text`.

---

## 4. `tests/test_e2e_outermost_function.lua`

### 4a. Fix existing assertions

Every existing test does:

```lua
local scope = child.lua_get("treescope.outermost_function()")
h.assert_scope(expected, scope)
```

Change to:

```lua
local result = child.lua_get("treescope.outermost_function()")
h.assert_scope(expected, result.text)
```

The `h.assert_scope` helper in `tests/helpers.lua` does not need to change — it already handles `nil` correctly.

### 4b. Add navigation tests

Before doing anything about this phase, stop. Let the user try out the implementation and request feedback from him/her before proceeding.

Add a new test set `T["e2e_outermost_function_navigation"]` in the same file. Use the **same existing resource files** — they already contain multiple function definitions at different nesting levels. Define test cases as: set cursor at marker, call `goto_prev()` or `goto_next()`, assert resulting cursor row matches the start row of the expected outermost function.

After a goto call, verify correctness by calling `treescope.outermost_function().text` at the new cursor position and asserting it equals the expected function name.

A minimal set of navigation cases to cover per language:
- Cursor inside a nested function → `goto_prev` lands at the outermost of the previous sibling at the outer level.
- Cursor outside any function → `goto_next` lands at the first function in the file.
- Cursor outside any function → `goto_prev` lands at the last function in the file.
- Cursor at the first function in the file → `goto_prev` is a no-op (cursor does not move).
- Cursor at the last function in the file → `goto_next` is a no-op.

Add new cursor markers to at least one resource file (e.g., `tests/resources/outermost_function/lua.lua`) for positions that cover these cases: top-of-file before any function, between two top-level functions, and inside a nested function that has a sibling function at the outer level.

---

## Key invariants to preserve

- **`goto_prev` always moves backward** — it searches before the start of the current outermost node, not before the cursor. This prevents jumping to the same outermost when the cursor is past its start line but before any nested functions within it.
- **`goto_next` always moves forward** — it searches after the end of the current outermost node, not after the cursor. This prevents a nested function inside the same outermost from collapsing the jump target backward.
- **Both are no-ops when there is no valid target** — early return from `resolve()` without calling `nvim_win_set_cursor`.
- **The closures re-derive the cursor at call time** — `outermost_function()` may be called once and the closures stored in a keymap; navigation should reflect wherever the cursor is when the closure is actually invoked.
- **`text` can be `nil`; `goto_prev`/`goto_next` are always non-nil** — the `default` table guarantees this even when the filetype is unsupported.
