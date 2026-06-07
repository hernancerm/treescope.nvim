---@diagnostic disable: unused-local, missing-return

---@class OutermostClassProvider
local OutermostClassProvider = {}

---@param node TSNode
---@return boolean
function OutermostClassProvider.is_class(node) end

---@param node TSNode
---@param bufnr integer
---@return string?
function OutermostClassProvider.get_class_name(node, bufnr) end
