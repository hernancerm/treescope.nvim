local M = {}

-- row and col are 0-indexed.
-- Returns: outermost_node (TSNode | nil), name (string | nil)
local function find_outermost_at(provider, root, bufnr, row, col)
  local node = root:named_descendant_for_range(row, col, row, col)
  if not node then
    return nil, nil
  end

  local candidate = nil
  local cur = node
  while cur do
    if provider.is_function(cur) then
      candidate = cur
    end
    cur = cur:parent()
  end

  if not candidate then
    return nil, nil
  end
  -- is_function() returns true for identifier nodes in some providers (e.g. a
  -- field-name identifier in Lua: `{ foo = function() end }`). From the
  -- identifier position the identifier becomes the candidate, but from inside
  -- the function body the function_definition becomes the candidate — two
  -- different nodes for the same function. normalize_outermost_node() maps the
  -- identifier to the canonical function node so all positions agree.
  if provider.normalize_outermost_node then
    candidate = provider.normalize_outermost_node(candidate) or candidate
  end
  return candidate, provider.get_function_name(candidate, bufnr)
end

-- Returns: list of { row, col, outermost } 0-indexed, sorted ascending.
-- `outermost` is the TSNode for the outermost function at the match position,
-- pre-resolved so navigation can group all matches by their outermost without
-- repeated tree walks.
-- Queries capture ALL function names (including nested), so pre-resolving here
-- is important: the name identifier of a field-assigned function (e.g.
-- `foo = function()`) sits outside the function_definition node's byte range,
-- so range-based lookups miss it. Grouping by outermost:start() avoids that.
local function get_query_matches(root, bufnr, lang, provider)
  local query = vim.treesitter.query.get(lang, "treescope")
  if not query then
    return {}
  end

  local matches = {}
  for id, node in query:iter_captures(root, bufnr, 0, -1) do
    if query.captures[id] == "treescope_outermost_function" then
      local row, col = node:start()
      local outermost = find_outermost_at(provider, root, bufnr, row, col)
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
    local ok, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
    if not ok or not parser then
      return
    end
    local trees = parser:parse()
    if not trees or #trees == 0 then
      return
    end
    local root = trees[1]:root()
    if not root then
      return
    end

    local win = vim.api.nvim_get_current_win()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local ref_row, ref_col = cursor[1] - 1, cursor[2]

    local all_matches = get_query_matches(root, bufnr, lang, provider)

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
        local after_cursor = m.row > ref_row or (m.row == ref_row and m.col > ref_col)
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
function M.get_value()
  local noop = function() end
  local default = { text = nil, goto_prev = noop, goto_next = noop }

  local bufnr = vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return default
  end

  local filetype = vim.bo[bufnr].filetype
  if not filetype or filetype == "" then
    return default
  end

  local provider_locator = require("treescope.provider_locator")
  local provider, lang =
    provider_locator.get_outermost_function_provider(filetype)
  if not provider or not lang then
    return default
  end

  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_buf(win) ~= bufnr then
    return default
  end

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
  if not ok or not parser then
    return default
  end

  local trees = parser:parse()
  if not trees or #trees == 0 then
    return default
  end

  local root = trees[1]:root()
  if not root then
    return default
  end

  local cursor = vim.api.nvim_win_get_cursor(win)
  local row, col = cursor[1] - 1, cursor[2]

  local _, name = find_outermost_at(provider, root, bufnr, row, col)

  local goto_prev, goto_next = make_goto_fns(bufnr, lang, provider)

  return { text = name, goto_prev = goto_prev, goto_next = goto_next }
end

return M
