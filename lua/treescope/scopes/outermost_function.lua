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

local function make_goto_fns(bufnr, lang, provider)
  local function resolve(direction)
    local root = get_root(bufnr, lang)
    if not root then
      return
    end

    local win = vim.api.nvim_get_current_win()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local ref_row, ref_col = cursor[1] - 1, cursor[2]

    local all_matches = get_query_matches(provider, root, bufnr, lang)

    -- For each outermost node, find its own name match: the first match in
    -- all_matches (sorted ascending) that belongs to it. Keyed by
    -- "outermost:start_row:start_col" so lookup is O(1).
    -- Range-based lookup (outermost:start()..outermost:end_()) fails for
    -- field-assigned functions (e.g. `foo = function()`): the name identifier
    -- sits outside the function_definition node's byte range.
    local outermost_name = {}
    for _, m in ipairs(all_matches) do
      if m.outermost then
        local sr, sc = m.outermost:start()
        local key = sr .. ":" .. sc
        if not outermost_name[key] then
          outermost_name[key] = m
        end
      end
    end

    local name_match = nil

    if direction == "prev" then
      -- Use the cursor as the reference boundary (not outermost:start()). Using
      -- the node start would place the reference before the name identifier (e.g.
      -- before "public int" in Java), making the name match never qualify as
      -- "strictly before", causing a no-op when the cursor is anywhere in the body.
      local target_match = nil
      for _, m in ipairs(all_matches) do
        if m.row < ref_row or (m.row == ref_row and m.col < ref_col) then
          target_match = m
        end
      end
      if not target_match then
        return
      end
      -- target_match may be a nested function. Use its pre-resolved outermost.
      local outermost = target_match.outermost
      if not outermost then
        return
      end
      local sr, sc = outermost:start()
      name_match = outermost_name[sr .. ":" .. sc]
    else
      -- Same cursor-as-reference rationale as "prev": using outermost:end_() would
      -- skip the entire current function when the cursor sits before its name (e.g.
      -- on the return type in Java).
      --
      -- Additionally, a match after the cursor may be a nested function that
      -- resolves to the same outermost the cursor is already on. In that case the
      -- resolved name_match is at or before the cursor, so we skip past the whole
      -- outermost and retry — otherwise goto_next is a no-op (stuck).
      local skip_key = nil
      for _, m in ipairs(all_matches) do
        local after_cursor = m.row > ref_row
          or (m.row == ref_row and m.col > ref_col)
        if after_cursor and m.outermost then
          local sr, sc = m.outermost:start()
          local key = sr .. ":" .. sc
          if key ~= skip_key then
            local nm = outermost_name[key]
            if nm then
              if nm.row > ref_row or (nm.row == ref_row and nm.col > ref_col) then
                name_match = nm
                break
              else
                skip_key = key
              end
            end
          end
        end
      end
    end

    if not name_match then
      return
    end

    -- Jump to the name match position, not outermost:start(). The node start
    -- points to the first token of the declaration (e.g. "private" in Java),
    -- not the identifier.
    vim.cmd("normal! m'") -- add entry to jumplist
    vim.api.nvim_win_set_cursor(win, { name_match.row + 1, name_match.col })
  end

  return function()
    resolve("prev")
  end, function()
    resolve("next")
  end
end

--- See docs for matching function in |treescope.outermost_function()|.
---@return treescope.OutermostFunction
function M.get_scope()
  local empty = {
    text = nil,
    goto_prev = function() end,
    goto_next = function() end,
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

  return {
    text = name,
    goto_prev = goto_prev,
    goto_next = goto_next,
  }
end

return M
