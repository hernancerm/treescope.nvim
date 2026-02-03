local M = {}

local ts = vim.treesitter

---@param node TSNode
---@return boolean
function M.is_function(node)
  if node:type() ~= "list_lit" then
    return false
  end
  -- Get the first child (should be the "defn" symbol).
  local first_child = node:named_child(0)
  if not first_child or first_child:type() ~= "sym_lit" then
    return false
  end
  -- Check if the symbol is "defn".
  local sym_text = ts.get_node_text(first_child, 0)
  return sym_text == "defn"
end

---@param node TSNode
---@param bufnr integer
---@return string?
function M.get_function_name(node, bufnr)
  -- Get the second child (the function name).
  local name_node = node:named_child(1)
  if not name_node or name_node:type() ~= "sym_lit" then
    return nil
  end
  return ts.get_node_text(name_node, bufnr)
end

---@type Provider
local _ = M

return M
