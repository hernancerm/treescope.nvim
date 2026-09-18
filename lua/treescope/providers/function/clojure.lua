local M = {}

local ts = vim.treesitter

---@param node TSNode
---@param bufnr integer
---@return boolean
function M.is_scope_node(node, bufnr)
  if node:type() ~= "list_lit" then
    return false
  end
  -- Get the first child (should be the "defn" or "def" symbol).
  local first_child = node:named_child(0)
  if not first_child or first_child:type() ~= "sym_lit" then
    return false
  end
  local sym_text = ts.get_node_text(first_child, bufnr)

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
    return ts.get_node_text(fn_first_child, bufnr) == "fn"
  end

  return false
end

---@param node TSNode
---@param bufnr integer
---@return TSNode?
function M.get_name_node(node, bufnr)
  -- Get the first child to determine if it's "defn" or "def".
  local first_child = node:named_child(0)
  if not first_child or first_child:type() ~= "sym_lit" then
    return nil
  end
  local sym_text = ts.get_node_text(first_child, bufnr)

  -- Case: (defn name ...) or (deftest name ...) or (defmacro name ...)
  if sym_text == "defn" or sym_text == "deftest" or sym_text == "defmacro" then
    local name_node = node:named_child(1)
    if not name_node or name_node:type() ~= "sym_lit" then
      return nil
    end
    return name_node
  end

  -- Case: (def name (fn ...))
  if sym_text == "def" then
    local name_node = node:named_child(1)
    if not name_node or name_node:type() ~= "sym_lit" then
      return nil
    end
    return name_node
  end

  return nil
end

---@type NodeScopeProvider
local _ = M

return M
