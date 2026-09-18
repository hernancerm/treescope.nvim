local M = {}

local ts = vim.treesitter

-- Test framework calls whose callback is named by the title string, e.g.
-- `it("adds", () => {})`. Covers vitest, jest and mocha.
local test_call_names = {
  describe = true,
  it = true,
  test = true,
  suite = true,
  xdescribe = true,
  xit = true,
  xtest = true,
  fdescribe = true,
  fit = true,
  ftest = true,
}

---@param node TSNode
---@param bufnr integer
---@return boolean
local function is_test_call(node, bufnr)
  if node:type() ~= "call_expression" then
    return false
  end
  local fn = node:field("function")[1]
  if not fn then
    return false
  end
  -- `it.only(...)`, `describe.skip(...)`: the object names the framework call.
  if fn:type() == "member_expression" then
    fn = fn:field("object")[1]
  end
  if not fn or fn:type() ~= "identifier" then
    return false
  end
  return test_call_names[ts.get_node_text(fn, bufnr)] == true
end

--- Callback argument of a test call, e.g. the arrow function in `it("x", () => {})`.
---@param call TSNode
---@return TSNode?
local function get_test_callback(call)
  local args = call:field("arguments")[1]
  if not args then
    return nil
  end
  for i = 0, args:named_child_count() - 1 do
    local arg = args:named_child(i)
    local at = arg and arg:type()
    if at == "arrow_function" or at == "function_expression" then
      return arg
    end
  end
  return nil
end

--- True when {node} is the callback of a test call.
---@param node TSNode
---@param bufnr integer
---@return boolean
local function is_test_callback(node, bufnr)
  local args = node:parent()
  if not args or args:type() ~= "arguments" then
    return false
  end
  local call = args:parent()
  return call ~= nil
    and is_test_call(call, bufnr)
    and get_test_callback(call) == node
end

--- Title of a test call without quotes: the `string_fragment` of the first
--- argument. Template strings have no fragment, so the whole literal is used.
---@param call TSNode
---@return TSNode?
local function get_test_title_node(call)
  local args = call:field("arguments")[1]
  local title = args and args:named_child(0)
  if not title then
    return nil
  end
  if title:type() == "string" then
    return title:named_child(0) or title
  end
  if title:type() == "template_string" then
    return title
  end
  return nil
end

---@param node TSNode
---@param bufnr integer
---@return boolean
function M.is_scope_node(node, bufnr)
  local t = node:type()

  if t == "function_declaration" then
    -- Case: function foo() {} or async function foo() {}
    return true
  end

  if t == "arrow_function" or t == "function_expression" then
    -- Case: const foo = () => {} or { key: () => {} } or it("x", () => {})
    local parent = node:parent()
    if not parent then
      return false
    end
    local pt = parent:type()
    return pt == "variable_declarator"
      or pt == "pair"
      or is_test_callback(node, bufnr)
  end

  -- Case: Cursor on `it(` or on the title in: it("x", () => {})
  if t == "call_expression" then
    return is_test_call(node, bufnr) and get_test_callback(node) ~= nil
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
---@return TSNode?
function M.get_name_node(node, bufnr)
  local t = node:type()

  if t == "identifier" then
    -- Case: Cursor on variable name in: const foo = () => {}
    return node
  end

  if t == "function_declaration" then
    -- Case: function foo() {}
    local name_node = node:field("name")[1]
    return name_node
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
      return name_node
    end
    if pt == "pair" then
      -- Case: { key: () => {} } or { key: function() {} }
      local key_node = parent:field("key")[1]
      return key_node
    end
    if pt == "arguments" and is_test_callback(node, bufnr) then
      -- Case: it("x", () => {})
      return get_test_title_node(parent:parent())
    end
    return nil
  end

  if t == "call_expression" then
    -- Case: Cursor on `it(` in: it("x", () => {})
    return get_test_title_node(node)
  end

  if t == "property_identifier" then
    -- Case: Cursor on key in: { key: function() {} } or { key: () => {} }
    return node
  end

  if t == "pair" then
    -- Case: Cursor on `:` in: { key: function() {} } or { key: () => {} }
    local key_node = node:field("key")[1]
    return key_node
  end

  return nil
end

---@param node TSNode
---@return TSNode
function M.normalize_node(node)
  local t = node:type()
  -- call_expression → callback (cursor was on `it(` or the title)
  if t == "call_expression" then
    return get_test_callback(node) or node
  end
  -- variable_declarator → function literal (cursor was on `=` gap)
  if t == "variable_declarator" then
    local value = node:field("value")[1]
    if
      value
      and (
        value:type() == "arrow_function"
        or value:type() == "function_expression"
      )
    then
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
    if
      value
      and (
        value:type() == "arrow_function"
        or value:type() == "function_expression"
      )
    then
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
    if
      value
      and (
        value:type() == "arrow_function"
        or value:type() == "function_expression"
      )
    then
      return value
    end
    return node
  end

  if t == "pair" then
    -- Cursor on `:` in { key: function() {} } or { key: () => {} }
    local value = node:field("value")[1]
    if
      value
      and (
        value:type() == "arrow_function"
        or value:type() == "function_expression"
      )
    then
      return value
    end
    return node
  end

  return node
end

---@type NodeScopeProvider
local _ = M

return M
