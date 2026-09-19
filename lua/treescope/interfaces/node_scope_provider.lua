---@diagnostic disable: unused-local, missing-return

--- Provider for scopes resolved by walking up the tree from the cursor, e.g.
--- `function` and `class`.
---@class NodeScopeProvider
local NodeScopeProvider = {}

--- Decides if {node} is (or stands in for) a scope node. Identifier nodes may
--- test true when they sit outside the definition's byte range, e.g. `foo` in
--- Lua's `foo = function() end`. `normalize_node` maps those to the definition.
---@param node TSNode
---@param buf integer
---@return boolean
function NodeScopeProvider.is_scope_node(node, buf) end

--- Node whose text is the scope's name, e.g. the identifier. Called with a node
--- already passed through `normalize_node`.
---@param node TSNode
---@param buf integer
---@return TSNode?
function NodeScopeProvider.get_name_node(node, buf) end

--- Optional. Maps stand-in nodes to the canonical scope node so all cursor
--- positions within the same scope agree on the same TSNode.
---@param node TSNode
---@return TSNode
function NodeScopeProvider.normalize_node(node) end
