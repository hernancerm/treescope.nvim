---@diagnostic disable: unused-local, missing-return

---@class OuterFunctionProvider
local OuterFunctionProvider = {}

---@param node TSNode
---@return boolean
function OuterFunctionProvider.is_function(node) end

---@param node TSNode
---@param bufnr integer
---@return string?
function OuterFunctionProvider.get_function_name(node, bufnr) end
