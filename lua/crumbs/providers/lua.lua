---@class Provider
local M = {}

local ts = vim.treesitter

---@param node TSNode
---@return boolean
function M.is_function(node)
  local t = node:type()
  return t == "function_declaration" or t == "function_definition"
end

---@param node TSNode
---@param bufnr integer
---@return string?
function M.get_function_name(node, bufnr)
  local name_node

  if node:type() == "function_declaration" then
    -- function foo() end
    name_node = node:field("name")[1]

  elseif node:type() == "function_definition" then
    -- foo = function() end
    local expr_list = node:parent()
    local assign = expr_list and expr_list:parent()

    if assign and assign:type() == "assignment_statement" then
      local var_list = assign:named_child(0)
      if var_list and var_list:type() == "variable_list" then
        name_node = var_list:named_child(0)
      end
    end
  end

  if not name_node then
    return nil
  end

  return ts.get_node_text(name_node, bufnr)
end

return M
