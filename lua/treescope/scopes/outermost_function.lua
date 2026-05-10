local M = {}

--- Get root node.
---@param bufnr integer
---@param lang string
---@return TSNode?
local function get_root(bufnr, lang)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
  if not ok or not parser then
    return nil
  end
  local trees = parser:parse()
  if not trees or #trees == 0 then
    return nil
  end
  return trees[1]:root()
end

--- Get the outermost function node and name at the given position.
---@param provider OutermostFunctionProvider
---@param root TSNode
---@param bufnr integer
---@param row integer 0-indexed.
---@param col integer 0-indexed.
---@return TSNode? outermost_function_node
---@return string? outermost_function_name
local function find_outermost_function_at(provider, root, bufnr, row, col)
  -- Get node at row/col position.
  local pos_node = root:named_descendant_for_range(row, col, row, col)
  if not pos_node then
    return nil, nil
  end
  ---@type TSNode?
  local cur_node = pos_node
  local outermost_function_node = nil
  while cur_node do
    if provider.is_function(cur_node) then
      outermost_function_node = cur_node
    end
    cur_node = cur_node:parent()
  end
  if not outermost_function_node then
    return nil, nil
  end
  -- is_function() returns true for identifier nodes in some providers, e.g. a
  -- field-name identifier in Lua: `{ foo = function() end }`. From the identifier
  -- position the identifier becomes the candidate, but from inside the function
  -- body the function_definition becomes the candidate, two different nodes for
  -- the same function. normalize_node() maps the identifier to the canonical
  -- function node so all positions agree.
  if provider.normalize_node then
    outermost_function_node = provider.normalize_node(outermost_function_node)
      or outermost_function_node
  end
  return outermost_function_node,
    provider.get_function_name(outermost_function_node, bufnr)
end

--- Returns list of `{ row, col, node }` 0-indexed, sorted ascending. `node` is
--- the TSNode for the outermost function at the match position, pre-resolved so
--- navigation can group all matches by their outermost without repeated tree
--- walks. Queries capture all function names, including nested, so pre-resolving
--- here is important: the name identifier of a field-assigned function (e.g.,
--- `foo = function()`) sits outside the function_definition node's byte range,
--- so range-based lookups miss it. Grouping by `outermost:start()` avoids that.
---@param provider OutermostFunctionProvider
---@param root TSNode
---@param bufnr integer
---@param lang string
---@return table[]
local function get_query_matches(provider, root, bufnr, lang)
  local query = vim.treesitter.query.get(lang, "treescope")
  if not query then
    return {}
  end
  local matches = {}
  for id, node in query:iter_captures(root, bufnr, 0, -1) do
    if query.captures[id] == "treescope_outermost_function" then
      local row, col = node:start()
      local outermost =
        find_outermost_function_at(provider, root, bufnr, row, col)
      table.insert(matches, { row = row, col = col, outermost = outermost })
    end
  end
  table.sort(matches, function(a, b)
    if a.row ~= b.row then
      return a.row < b.row
    end
    return a.col < b.col
  end)
  return matches
end

--- Build a map from each outermost node's start position key ("row:col") to the
--- first name match that belongs to it. Iterates `all_matches` in ascending order
--- so the earliest match per outermost is kept. Keyed by position rather than by
--- range because field-assigned function names (e.g. `foo = function()`) sit
--- outside the function_definition node's byte range, making range-based lookup
--- unreliable.
---@param all_matches table[]
---@return table<string, table>
local function build_outermost_name_index(all_matches)
  local index = {}
  for _, m in ipairs(all_matches) do
    if m.outermost then
      local sr, sc = m.outermost:start()
      local key = sr .. ":" .. sc
      if not index[key] then
        index[key] = m
      end
    end
  end
  return index
end

--- Find the name match for the outermost function that ends strictly before the
--- cursor. Uses the cursor position as the reference boundary rather than
--- `outermost:start()` so that any match inside the current function body still
--- qualifies as "before", preventing a no-op when the cursor is in the body of
--- the first visible function.
---@param all_matches table[]
---@param outermost_name_index table<string, table>
---@param ref_row integer 0-indexed cursor row.
---@param ref_col integer 0-indexed cursor col.
---@return table? name_match
local function find_prev_name_match(
  all_matches,
  outermost_name_index,
  ref_row,
  ref_col
)
  local target_match = nil
  for _, m in ipairs(all_matches) do
    if m.row < ref_row or (m.row == ref_row and m.col < ref_col) then
      target_match = m
    end
  end
  if not target_match or not target_match.outermost then
    return nil
  end
  local sr, sc = target_match.outermost:start()
  return outermost_name_index[sr .. ":" .. sc]
end

--- Find the name match for the next outermost function strictly after the cursor.
--- Uses the cursor as the reference boundary rather than `outermost:end_()` so
--- the current function is not skipped when the cursor sits before its name (e.g.
--- on the return type in Java). Skips outermosts whose resolved name match is at
--- or before the cursor — those are the current function — to avoid a no-op when
--- a nested function inside the current body is the first match after the cursor.
---@param all_matches table[]
---@param outermost_name_index table<string, table>
---@param ref_row integer 0-indexed cursor row.
---@param ref_col integer 0-indexed cursor col.
---@return table? name_match
local function find_next_name_match(
  all_matches,
  outermost_name_index,
  ref_row,
  ref_col
)
  local skip_key = nil
  for _, m in ipairs(all_matches) do
    local after_cursor = m.row > ref_row or (m.row == ref_row and m.col > ref_col)
    if after_cursor and m.outermost then
      local sr, sc = m.outermost:start()
      local key = sr .. ":" .. sc
      if key ~= skip_key then
        local nm = outermost_name_index[key]
        if nm then
          if nm.row > ref_row or (nm.row == ref_row and nm.col > ref_col) then
            return nm
          else
            skip_key = key
          end
        end
      end
    end
  end
  return nil
end

--- Return a `set_loclist` function for the given buffer. When called, it defers a
--- full-file scan to the next event-loop tick and populates the current window's
--- location list with every outermost function.
---@param bufnr integer
---@param lang string
---@param provider OutermostFunctionProvider
---@return function set_loclist
local function make_set_loclist_fn(bufnr, lang, provider)
  return function(opts)
    opts = opts or {}
    vim.schedule(function()
      local root = get_root(bufnr, lang)
      if not root then
        return
      end
      local all_matches = get_query_matches(provider, root, bufnr, lang)
      local outermost_name_index = build_outermost_name_index(all_matches)
      local seen = {}
      local items = {}
      for _, m in ipairs(all_matches) do
        if m.outermost then
          local sr, sc = m.outermost:start()
          local key = sr .. ":" .. sc
          if not seen[key] then
            seen[key] = true
            local nm = outermost_name_index[key]
            if nm then
              local name = provider.get_function_name(nm.outermost, bufnr)
              table.insert(items, {
                bufnr = bufnr,
                lnum = nm.row + 1,
                col = nm.col + 1,
                text = name or "(anonymous)",
              })
            end
          end
        end
      end
      vim.fn.setloclist(
        0,
        {},
        "r",
        { title = "[Treescope] Outermost functions", items = items }
      )
      if opts.open then
        vim.cmd("lopen")
      end
    end)
  end
end

--- Return `goto_prev` and `goto_next` functions for the given buffer. Each
--- function moves the cursor to the name identifier of the previous/next
--- outermost function and pushes an entry onto the jumplist.
---@param bufnr integer
---@param lang string
---@param provider OutermostFunctionProvider
---@return function goto_prev
---@return function goto_next
local function make_goto_fns(bufnr, lang, provider)
  local function resolve(direction, opts)
    local count = (opts and opts.count) or 1
    local set_jump = false
    if opts ~= nil and opts.set_jump ~= nil then
      set_jump = opts.set_jump
    end
    local root = get_root(bufnr, lang)
    if not root then
      return
    end

    local win = vim.api.nvim_get_current_win()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local ref_row, ref_col = cursor[1] - 1, cursor[2]

    local all_matches = get_query_matches(provider, root, bufnr, lang)
    local outermost_name_index = build_outermost_name_index(all_matches)

    local name_match
    for _ = 1, count do
      if direction == "prev" then
        name_match = find_prev_name_match(
          all_matches,
          outermost_name_index,
          ref_row,
          ref_col
        )
      else
        name_match = find_next_name_match(
          all_matches,
          outermost_name_index,
          ref_row,
          ref_col
        )
      end
      if not name_match then
        return
      end
      ref_row, ref_col = name_match.row, name_match.col
    end

    if set_jump then
      vim.cmd("normal! m'")
    end

    -- Jump to the name identifier, not outermost:start(). The node start may
    -- point to the first token of the declaration (e.g. "private" in Java).
    vim.api.nvim_win_set_cursor(win, { name_match.row + 1, name_match.col })
  end

  return function(opts)
    resolve("prev", opts)
  end, function(opts)
    resolve("next", opts)
  end
end

--- See docs for matching function in |treescope.outermost_function()|.
---@return treescope.OutermostFunction
function M.get_scope()
  local empty = {
    text = nil,
    goto_prev = function() end,
    goto_next = function() end,
    set_loclist = function() end,
  }

  local bufnr = vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return empty
  end

  local filetype = vim.bo[bufnr].filetype
  if not filetype or filetype == "" then
    return empty
  end

  local provider_locator = require("treescope.provider_locator")
  local provider, lang =
    provider_locator.get_outermost_function_provider(filetype)
  if not provider or not lang then
    return empty
  end

  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_buf(win) ~= bufnr then
    return empty
  end

  local root = get_root(bufnr, lang)
  if not root then
    return empty
  end

  local cursor = vim.api.nvim_win_get_cursor(win)
  local row, col = cursor[1] - 1, cursor[2]

  local _, name = find_outermost_function_at(provider, root, bufnr, row, col)

  local goto_prev, goto_next = make_goto_fns(bufnr, lang, provider)
  local set_loclist = make_set_loclist_fn(bufnr, lang, provider)

  return {
    text = name,
    goto_prev = goto_prev,
    goto_next = goto_next,
    set_loclist = set_loclist,
  }
end

return M
