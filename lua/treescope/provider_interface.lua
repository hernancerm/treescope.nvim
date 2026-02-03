---@diagnostic disable: unused-local, missing-return

---@class Provider
local Provider = {}

---@param node TSNode
---@return boolean
function Provider.is_function(node) end

---@param node TSNode
---@param bufnr integer
---@return string?
function Provider.get_function_name(node, bufnr) end
