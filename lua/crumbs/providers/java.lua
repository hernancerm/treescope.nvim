---@class Provider
local M = {}

local ts = vim.treesitter

---@param node TSNode
function M.is_function(node)
  local t = node:type()
  return t == "method_declaration"
      or t == "constructor_declaration"
end

local function enclosing_primary_type(node)
  local cur = node:parent()
  while cur do
    local t = cur:type()
    if t == "class_declaration"
      or t == "interface_declaration"
      or t == "enum_declaration"
      or t == "record_declaration" then
      return cur
    end
    cur = cur:parent()
  end
  return nil
end

local function primary_type_name(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" then
    return nil
  end
  return vim.fn.fnamemodify(path, ":t:r")
end

---@param node TSNode
---@param bufnr integer
function M.get_function_name(node, bufnr)
  local type_decl = enclosing_primary_type(node)
  if not type_decl then
    return nil
  end

  local type_name_node = type_decl:field("name")[1]
  if not type_name_node then
    return nil
  end

  local type_name = ts.get_node_text(type_name_node, bufnr)
  local primary = primary_type_name(bufnr)

  if not primary or type_name ~= primary then
    return nil
  end

  if node:type() == "method_declaration" then
    local name_node = node:field("name")[1]
    return name_node and ts.get_node_text(name_node, bufnr)
  end

  if node:type() == "constructor_declaration" then
    -- constructor name == type name
    return type_name
  end

  return nil
end

return M
