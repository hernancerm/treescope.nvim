local M = {}

---@param node TSNode
---@param buf integer
---@return boolean
function M.is_scope_node(node, buf)
  local t = node:type()

  if t == "function_declaration" or t == "function_definition" then
    return true
  end

  -- Case: Cursor on `=` in: { field = function() end }
  if t == "field" then
    local value = node:field("value")[1]
    return value ~= nil and value:type() == "function_definition"
  end

  -- Case: Cursor on `=` in: local foo = function() end  or  foo = function() end
  if t == "assignment_statement" then
    local expr_list = node:named_child(1)
    if not expr_list then
      return false
    end
    local func_def = expr_list:named_child(0)
    return func_def ~= nil and func_def:type() == "function_definition"
  end

  if t == "identifier" then
    local parent = node:parent()
    if not parent then
      return false
    end

    -- Case: Cursor on variable name in: local foo = function() end
    -- or in: foo = function() end
    if parent:type() == "variable_list" then
      local assign = parent:parent()
      if not assign or assign:type() ~= "assignment_statement" then
        return false
      end
      local expr_list = assign:named_child(1)
      if not expr_list then
        return false
      end
      local func_def = expr_list:named_child(0)
      return func_def ~= nil and func_def:type() == "function_definition"
    end

    -- Case: Cursor on field name in: { field_with_function = function() end }
    if parent:type() == "field" then
      local value = parent:field("value")[1]
      return value ~= nil and value:type() == "function_definition"
    end

    return false
  end

  return false
end

---@param node TSNode
---@param buf integer
---@return TSNode?
function M.get_name_node(node, buf)
  local t = node:type()

  if t == "identifier" then
    -- Case: Cursor on variable name in: local foo = function() end
    -- or in: foo = function() end
    return node
  end

  if t == "function_declaration" then
    -- Case: function foo() end
    local name_node = node:field("name")[1]
    if name_node then
      return name_node
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
          return name_node
        end
      end
    end

    -- Case: { field_with_function = function() end }
    local field = node:parent()
    if field and field:type() == "field" then
      local name_node = field:field("name")[1]
      if name_node then
        return name_node
      end
    end
  end

  return nil
end

---@param node TSNode
---@return TSNode
function M.normalize_node(node)
  local t = node:type()
  -- field → function_definition (cursor was on `=` gap in table field)
  if t == "field" then
    local value = node:field("value")[1]
    if value and value:type() == "function_definition" then
      return value
    end
    return node
  end
  -- assignment_statement → function_definition (cursor was on `=` gap)
  if t == "assignment_statement" then
    local expr_list = node:named_child(1)
    if expr_list then
      local func_def = expr_list:named_child(0)
      if func_def and func_def:type() == "function_definition" then
        return func_def
      end
    end
    return node
  end
  if t ~= "identifier" then
    return node
  end
  local parent = node:parent()
  if not parent then
    return node
  end
  -- { foo = function() end }
  if parent:type() == "field" then
    local value = parent:field("value")[1]
    if value and value:type() == "function_definition" then
      return value
    end
  end
  -- foo = function() end  /  local foo = function() end
  if parent:type() == "variable_list" then
    local assign = parent:parent()
    if assign and assign:type() == "assignment_statement" then
      local expr_list = assign:named_child(1)
      if expr_list then
        local func_def = expr_list:named_child(0)
        if func_def and func_def:type() == "function_definition" then
          return func_def
        end
      end
    end
  end
  return node
end

---@type NodeScopeProvider
local _ = M

return M
