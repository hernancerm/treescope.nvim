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
    -- Case: const foo = () => {} or const foo = async () => {}
    local parent = node:parent()
    return parent and parent:type() == "variable_declarator" or false
  end

  if t == "function_expression" then
    -- Case: const foo = function() {} or const foo = async function() {}
    local parent = node:parent()
    return parent and parent:type() == "variable_declarator" or false
  end

  if t == "identifier" then
    -- Case: Cursor on variable name in: const foo = () => {}
    local parent = node:parent()
    if not parent or parent:type() ~= "variable_declarator" then
      return false
    end
    -- Check if the value field contains a function.
    local value = parent:field("value")[1]
    if not value then
      return false
    end
    local value_type = value:type()
    return value_type == "arrow_function" or value_type == "function_expression"
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
    -- Case: const foo = () => {} or const foo = function() {}
    local parent = node:parent()
    if not parent or parent:type() ~= "variable_declarator" then
      -- This shouldn't happen if is_function() is correct, but handle gracefully.
      return nil
    end

    local name_node = parent:field("name")[1]
    if not name_node then
      -- If name extraction fails, return nil rather than attempting fallback.
      return nil
    end

    return ts.get_node_text(name_node, bufnr)
  end

  return nil
end

---@type OutermostFunctionProvider
local _ = M

return M
