local M = {}

local ts = vim.treesitter

---@param node TSNode
---@return boolean
function M.is_function(node)
  if node:type() ~= "list_lit" then
    return false
  end
  -- Get the first child (should be the "defn" or "def" symbol).
  local first_child = node:named_child(0)
  if not first_child or first_child:type() ~= "sym_lit" then
    return false
  end
  local sym_text = ts.get_node_text(first_child, 0)

  -- Case: (defn name ...) or (deftest name ...) or (defmacro name ...)
  if sym_text == "defn" or sym_text == "deftest" or sym_text == "defmacro" then
    return true
  end

  -- Case: (def name (fn ...))
  if sym_text == "def" then
    -- Check if the third child is an anonymous function (fn).
    local third_child = node:named_child(2)
    if not third_child or third_child:type() ~= "list_lit" then
      return false
    end
    -- Check if the first child of the list is "fn".
    local fn_first_child = third_child:named_child(0)
    if not fn_first_child or fn_first_child:type() ~= "sym_lit" then
      return false
    end
    return ts.get_node_text(fn_first_child, 0) == "fn"
  end

  return false
end

---@param node TSNode
---@param bufnr integer
---@return string?
function M.get_function_name(node, bufnr)
  -- Get the first child to determine if it's "defn" or "def".
  local first_child = node:named_child(0)
  if not first_child or first_child:type() ~= "sym_lit" then
    return nil
  end
  local sym_text = ts.get_node_text(first_child, 0)

  -- Case: (defn name ...) or (deftest name ...) or (defmacro name ...)
  if sym_text == "defn" or sym_text == "deftest" or sym_text == "defmacro" then
    local name_node = node:named_child(1)
    if not name_node or name_node:type() ~= "sym_lit" then
      return nil
    end
    return ts.get_node_text(name_node, bufnr)
  end

  -- Case: (def name (fn ...))
  if sym_text == "def" then
    local name_node = node:named_child(1)
    if not name_node or name_node:type() ~= "sym_lit" then
      return nil
    end
    return ts.get_node_text(name_node, bufnr)
  end

  return nil
end

---@type OutermostFunctionProvider
local _ = M

return M
