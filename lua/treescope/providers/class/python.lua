local M = {}

---@param node TSNode
---@param bufnr integer
---@return boolean
function M.is_scope_node(node, bufnr)
  return node:type() == "class_definition"
end

---@param node TSNode
---@param bufnr integer
---@return TSNode?
function M.get_name_node(node, bufnr)
  local name_node = node:field("name")[1]
  return name_node
end

---@type NodeScopeProvider
local _ = M

return M
