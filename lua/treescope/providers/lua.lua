local M = {}

local ts = vim.treesitter

---@param node TSNode
---@return boolean
function M.is_function(node)
  local t = node:type()

  if t == "function_declaration" or t == "function_definition" then
    return true
  end

  if t == "identifier" then
    -- Case: Cursor on variable name in: local foo = function() end
    -- or in: foo = function() end
    local var_list = node:parent()
    if not var_list or var_list:type() ~= "variable_list" then
      return false
    end

    local assign = var_list:parent()
    if not assign or assign:type() ~= "assignment_statement" then
      return false
    end

    -- Check if the assignment has a function_definition as its value.
    local expr_list = assign:named_child(1)
    if not expr_list then
      return false
    end

    local func_def = expr_list:named_child(0)
    return func_def and func_def:type() == "function_definition"
  end

  return false
end

---@param node TSNode
---@param bufnr integer
---@return string?
function M.get_function_name(node, bufnr)
  local t = node:type()

  if t == "identifier" then
    -- Case: Cursor on variable name in: local foo = function() end
    -- or in: foo = function() end
    return ts.get_node_text(node, bufnr)
  end

  if t == "function_declaration" then
    -- Case: function foo() end
    local name_node = node:field("name")[1]
    if name_node then
      return ts.get_node_text(name_node, bufnr)
    end
  end

  if t == "function_definition" then
    -- Case: foo = function() end
    local expr_list = node:parent()
    local assign = expr_list and expr_list:parent()
    if assign and assign:type() == "assignment_statement" then
      local var_list = assign:named_child(0)
      if var_list and var_list:type() == "variable_list" then
        local name_node = var_list:named_child(0)
        if name_node then
          return ts.get_node_text(name_node, bufnr)
        end
      end
    end
  end

  return nil
end

---@type Provider
local _ = M

return M
