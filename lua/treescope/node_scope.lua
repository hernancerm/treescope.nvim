-- Shared logic for scopes resolved by walking up the tree from a position
-- (`function`, `class`). A scope module for one of these only needs to name its
-- query capture, see `scopes/function.lua`.

local const = require("treescope.const")

local M = {}

---@param node TSNode
---@param provider NodeScopeProvider
---@param buf integer
---@return treescope.Scope
local function to_scope(node, provider, buf)
  local name_node = provider.get_name_node(node, buf)
  return {
    text = name_node and vim.treesitter.get_node_text(name_node, buf),
    node = node,
    name_node = name_node,
  }
end

--- Scope node enclosing (row, col), 0-indexed. Outermost keeps the last hit
--- walking up, any keeps the first.
---@param ctx treescope.Ctx
---@param row integer
---@param col integer
---@param depth const.Depth
---@return TSNode?
local function find_node_at(ctx, row, col, depth)
  ---@type TSNode?
  local cur = ctx.root:named_descendant_for_range(row, col, row, col)
  local found = nil
  while cur do
    if ctx.provider.is_scope_node(cur, ctx.buf) then
      found = cur
      if depth == const.Depth.ANY then
        break
      end
    end
    cur = cur:parent()
  end
  if found and ctx.provider.normalize_node then
    found = ctx.provider.normalize_node(found) or found
  end
  return found
end

---@param ctx treescope.Ctx
---@param row integer 0-indexed.
---@param col integer 0-indexed.
---@param depth const.Depth
---@return treescope.Scope
function M.get(ctx, row, col, depth)
  local node = find_node_at(ctx, row, col, depth)
  if not node then
    return {}
  end
  return to_scope(node, ctx.provider, ctx.buf)
end

--- All scopes in the buffer, sorted by name position. Each `@{capture}` in the
--- `treescope` query marks a name; resolving it through `find_node_at` reuses
--- the provider's normalization, so field-assigned names that sit outside the
--- definition's range (Lua `foo = function()`) still map to the right node.
--- Duplicates (two patterns matching one name) are dropped by node start.
---@param ctx treescope.Ctx
---@param capture string
---@param depth const.Depth
---@return treescope.Scope[]
function M.list(ctx, capture, depth)
  local query = vim.treesitter.query.get(ctx.lang, "treescope")
  if not query then
    return {}
  end
  local seen = {}
  local scopes = {}
  for id, node in query:iter_captures(ctx.root, ctx.buf, 0, -1) do
    if query.captures[id] == capture then
      local row, col = node:start()
      local scope_node = find_node_at(ctx, row, col, depth)
      if scope_node then
        local sr, sc = scope_node:start()
        local key = sr .. ":" .. sc
        if not seen[key] then
          seen[key] = true
          table.insert(scopes, to_scope(scope_node, ctx.provider, ctx.buf))
        end
      end
    end
  end
  table.sort(scopes, function(a, b)
    local ar, ac = (a.name_node or a.node):start()
    local br, bc = (b.name_node or b.node):start()
    if ar ~= br then
      return ar < br
    end
    return ac < bc
  end)
  return scopes
end

return M
