local M = {}

---@param node TSNode
---@param bufnr integer
---@return boolean
function M.is_scope_node(node, bufnr)
  local t = node:type()
  return t == "method_declaration" or t == "constructor_declaration"
end

---@param node TSNode
---@param bufnr integer
---@return TSNode?
function M.get_name_node(node, bufnr)
  if node:type() == "method_declaration" then
    local name_node = node:field("name")[1]
    return name_node
  end
  if node:type() == "constructor_declaration" then
    local name_node = node:field("name")[1]
    return name_node
  end
  return nil
end

---@type NodeScopeProvider
local _ = M

return M
