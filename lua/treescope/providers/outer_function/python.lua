local M = {}

local ts = vim.treesitter

---@param node TSNode
---@return boolean
function M.is_function(node)
  local t = node:type()
  return t == "function_definition" or t == "async_function_definition"
end

---@param node TSNode
---@param bufnr integer
---@return string?
function M.get_function_name(node, bufnr)
  local name_node = node:field("name")[1]
  return name_node and ts.get_node_text(name_node, bufnr)
end

---@type OuterFunctionProvider
local _ = M

return M
