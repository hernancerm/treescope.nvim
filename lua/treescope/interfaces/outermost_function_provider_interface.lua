---@diagnostic disable: unused-local, missing-return

---@class OutermostFunctionProvider
local OutermostFunctionProvider = {}

---@param node TSNode
---@return boolean
function OutermostFunctionProvider.is_function(node) end

---@param node TSNode
---@return TSNode
function OutermostFunctionProvider.normalize_outermost_node(node) end

---@param node TSNode
---@param bufnr integer
---@return string?
function OutermostFunctionProvider.get_function_name(node, bufnr) end
