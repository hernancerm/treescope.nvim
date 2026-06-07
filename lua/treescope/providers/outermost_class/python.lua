local M = {}

local ts = vim.treesitter

---@param node TSNode
---@return boolean
function M.is_class(node)
  return node:type() == "class_definition"
end

---@param node TSNode
---@param bufnr integer
---@return string?
function M.get_class_name(node, bufnr)
  local name_node = node:field("name")[1]
  return name_node and ts.get_node_text(name_node, bufnr)
end

---@type OutermostClassProvider
local _ = M

return M
