local M = {}

local ts = vim.treesitter

--- Finds the innermost function name at row using Tree-sitter queries.
---@param lang string
---@param root TSNode
---@param bufnr integer
---@param row integer 0-indexed
---@return string?
function M.current_function(lang, root, bufnr, row)
  local query = ts.query.get(lang, "textobjects")
  if not query then
    return nil
  end

  local move_id, display_id, scope_id
  for i, cap in ipairs(query.captures) do
    if cap == "treescope_function" then
      move_id = i
    elseif cap == "treescope_function.name" then
      display_id = i
    elseif cap == "treescope_function.scope" then
      scope_id = i
    end
  end

  if not scope_id or not move_id then
    return nil
  end

  local best_name_node = nil
  local best_scope_size = math.huge

  for _, match, _ in query:iter_matches(root, bufnr, 0, -1, { all = true }) do
    local scope_nodes = match[scope_id]
    if scope_nodes then
      local scope_node = scope_nodes[1]
      if scope_node then
        local sr, _, er, _ = scope_node:range()
        if row >= sr and row <= er then
          local size = er - sr
          if size < best_scope_size then
            best_scope_size = size
            local name_node

            -- Prefer .name capture (full expression like 'M.foo' or 'obj:method').
            if display_id then
              local display_nodes = match[display_id]
              if display_nodes then
                name_node = display_nodes[1]
              end
            end

            -- Fall back to movement capture (plain identifier).
            if not name_node then
              local move_nodes = match[move_id]
              if move_nodes then
                name_node = move_nodes[1]
              end
            end

            if name_node then
              best_name_node = name_node
            end
          end
        end
      end
    end
  end

  if best_name_node then
    return ts.get_node_text(best_name_node, bufnr)
  end

  return nil
end

return M
