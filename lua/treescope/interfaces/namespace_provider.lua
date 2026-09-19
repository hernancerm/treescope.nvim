---@diagnostic disable: unused-local, missing-return

---@class NamespaceProvider
local NamespaceProvider = {}

---@param root TSNode
---@param buf integer
---@return TSNode? node The declaration, e.g. `package_declaration`.
---@return TSNode? name_node The name inside the declaration.
function NamespaceProvider.get_namespace(root, buf) end
