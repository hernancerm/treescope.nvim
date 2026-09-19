local M = {}

---@param node TSNode
---@param buf integer
---@return boolean
function M.is_scope_node(node, buf)
  return node:type() == "class_declaration"
end

---@param node TSNode
---@param buf integer
---@return TSNode?
function M.get_name_node(node, buf)
  local name_node = node:field("name")[1]
  return name_node
end

---@type NodeScopeProvider
local _ = M

return M
