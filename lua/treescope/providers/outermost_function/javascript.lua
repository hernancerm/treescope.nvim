local M = {}

local ts = vim.treesitter

---@param node TSNode
---@return boolean
function M.is_function(node)
  local t = node:type()

  if t == "function_declaration" then
    -- Case: function foo() {} or async function foo() {}
    return true
  end

  if t == "arrow_function" then
    -- Case: const foo = () => {} or { key: () => {} }
    local parent = node:parent()
    if not parent then return false end
    local pt = parent:type()
    return pt == "variable_declarator" or pt == "pair"
  end

  if t == "function_expression" then
    -- Case: const foo = function() {} or { key: function() {} }
    local parent = node:parent()
    if not parent then return false end
    local pt = parent:type()
    return pt == "variable_declarator" or pt == "pair"
  end

  -- Case: Cursor on `:` in: { key: function() {} }  or  { key: () => {} }
  if t == "pair" then
    local value = node:field("value")[1]
    if not value then
      return false
    end
    local vt = value:type()
    return vt == "arrow_function" or vt == "function_expression"
  end

  -- Case: Cursor on `=` in: const foo = function() {}  or  const foo = () => {}
  if t == "variable_declarator" then
    local value = node:field("value")[1]
    if not value then
      return false
    end
    local vt = value:type()
    return vt == "arrow_function" or vt == "function_expression"
  end

  if t == "identifier" then
    -- Case: Cursor on variable name in: const foo = () => {}
    local parent = node:parent()
    if not parent or parent:type() ~= "variable_declarator" then
      return false
    end
    local value = parent:field("value")[1]
    if not value then
      return false
    end
    local value_type = value:type()
    return value_type == "arrow_function" or value_type == "function_expression"
  end

  if t == "property_identifier" then
    -- Case: Cursor on key in: { key: function() {} } or { key: () => {} }
    local parent = node:parent()
    if not parent or parent:type() ~= "pair" then
      return false
    end
    local value = parent:field("value")[1]
    if not value then
      return false
    end
    local vt = value:type()
    return vt == "arrow_function" or vt == "function_expression"
  end

  return false
end

---@param node TSNode
---@param bufnr integer
---@return string?
function M.get_function_name(node, bufnr)
  local t = node:type()

  if t == "identifier" then
    -- Case: Cursor on variable name in: const foo = () => {}
    return ts.get_node_text(node, bufnr)
  end

  if t == "function_declaration" then
    -- Case: function foo() {}
    local name_node = node:field("name")[1]
    return name_node and ts.get_node_text(name_node, bufnr)
  end

  if t == "arrow_function" or t == "function_expression" then
    local parent = node:parent()
    if not parent then
      return nil
    end
    local pt = parent:type()
    if pt == "variable_declarator" then
      -- Case: const foo = () => {} or const foo = function() {}
      local name_node = parent:field("name")[1]
      return name_node and ts.get_node_text(name_node, bufnr)
    end
    if pt == "pair" then
      -- Case: { key: () => {} } or { key: function() {} }
      local key_node = parent:field("key")[1]
      return key_node and ts.get_node_text(key_node, bufnr)
    end
    return nil
  end

  if t == "property_identifier" then
    -- Case: Cursor on key in: { key: function() {} } or { key: () => {} }
    return ts.get_node_text(node, bufnr)
  end

  if t == "pair" then
    -- Case: Cursor on `:` in: { key: function() {} } or { key: () => {} }
    local key_node = node:field("key")[1]
    return key_node and ts.get_node_text(key_node, bufnr)
  end

  return nil
end

---@param node TSNode
---@return TSNode
function M.normalize_node(node)
  local t = node:type()
  -- variable_declarator → function literal (cursor was on `=` gap)
  if t == "variable_declarator" then
    local value = node:field("value")[1]
    if value and (value:type() == "arrow_function" or value:type() == "function_expression") then
      return value
    end
    return node
  end
  if t == "identifier" then
    local parent = node:parent()
    if not parent or parent:type() ~= "variable_declarator" then
      return node
    end
    local value = parent:field("value")[1]
    if value and (value:type() == "arrow_function" or value:type() == "function_expression") then
      return value
    end
    return node
  end

  if t == "property_identifier" then
    -- { key: function() {} } or { key: () => {} }
    local parent = node:parent()
    if not parent or parent:type() ~= "pair" then
      return node
    end
    local value = parent:field("value")[1]
    if value and (value:type() == "arrow_function" or value:type() == "function_expression") then
      return value
    end
    return node
  end

  if t == "pair" then
    -- Cursor on `:` in { key: function() {} } or { key: () => {} }
    local value = node:field("value")[1]
    if value and (value:type() == "arrow_function" or value:type() == "function_expression") then
      return value
    end
    return node
  end

  return node
end

---@type OutermostFunctionProvider
local _ = M

return M
