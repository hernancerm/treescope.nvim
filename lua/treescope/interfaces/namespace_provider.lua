---@diagnostic disable: unused-local, missing-return

---@class NamespaceProvider
local NamespaceProvider = {}

---@param root TSNode
---@param bufnr integer
---@return TSNode? node The declaration, e.g. `package_declaration`.
---@return TSNode? name_node The name inside the declaration.
function NamespaceProvider.get_namespace(root, bufnr) end
