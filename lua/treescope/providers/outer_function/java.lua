local M = {}

local ts = vim.treesitter

---@param node TSNode
---@return boolean
function M.is_function(node)
  local t = node:type()
  return t == "method_declaration" or t == "constructor_declaration"
end

---@param node TSNode
---@param bufnr integer
---@return string?
function M.get_function_name(node, bufnr)
  if node:type() == "method_declaration" then
    local name_node = node:field("name")[1]
    return name_node and ts.get_node_text(name_node, bufnr)
  end
  if node:type() == "constructor_declaration" then
    local name_node = node:field("name")[1]
    return name_node and ts.get_node_text(name_node, bufnr)
  end
  return nil
end

---@type OuterFunctionProvider
local _ = M

return M
