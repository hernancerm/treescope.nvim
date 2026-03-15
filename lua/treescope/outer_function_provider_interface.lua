---@diagnostic disable: unused-local, missing-return

---@class OuterFunctionProvider
local OuterFunctionProvider = {}

--- Get the Tree-sitter language of the required parser. This allows the same
--- provider to be used for different languages, when applicable, for example the
--- javascript provider can be used for typescript.
---@return string
function OuterFunctionProvider.get_lang() end

---@param node TSNode
---@return boolean
function OuterFunctionProvider.is_function(node) end

---@param node TSNode
---@param bufnr integer
---@return string?
function OuterFunctionProvider.get_function_name(node, bufnr) end
