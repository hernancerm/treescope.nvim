---@class Provider
local M = {}

local ts = vim.treesitter

---@param node TSNode
function M.is_function(node)
  local t = node:type()
  return t == "function_declaration" or t == "function_definition"
end

---@param node TSNode
---@param bufnr integer
function M.get_function_signature(node, bufnr)
  local name_node
  local params_node

  if node:type() == "function_declaration" then
    name_node = node:field("name")[1]
    params_node = node:field("parameters")[1]

  elseif node:type() == "function_definition" then
    params_node = node:field("parameters")[1]

    -- function_definition -> expression_list -> assignment_statement
    local expr_list = node:parent()
    local assign = expr_list and expr_list:parent()

    if assign and assign:type() == "assignment_statement" then
      -- variable_list is the first named child
      local var_list = assign:named_child(0)
      if var_list and var_list:type() == "variable_list" then
        name_node = var_list:named_child(0)
      end
    end
  end

  if not params_node then
    return nil
  end

  local name = name_node
    and ts.get_node_text(name_node, bufnr)
    or "<anonymous>"

  local params = ts.get_node_text(params_node, bufnr)

  return name .. params
end

return M
