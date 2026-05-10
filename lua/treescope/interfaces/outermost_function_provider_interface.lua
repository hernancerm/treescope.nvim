---@diagnostic disable: unused-local, missing-return

---@class OutermostFunctionProvider
local OutermostFunctionProvider = {}

--- Decides if the node represents a function. Used to determine
--- outermost_function candidates during upwards tree walking.
---@param node TSNode
---@return boolean
function OutermostFunctionProvider.is_function(node) end

--- Gets function name from {node}. This function is meant to be called with a
--- {node} that tests as true by `OutermostFunctionProvider.is_function`.
---@param node TSNode
---@param bufnr integer
---@return string?
function OutermostFunctionProvider.get_function_name(node, bufnr) end

--- Map each node to its canonical outermost_function node. An example where this
--- is useful is Lua on forms like `local x = function() end`. This function is
--- meant to be called with a {node} that tests as true by
--- `OutermostFunctionProvider.is_function`.
---@param node TSNode
---@return TSNode
function OutermostFunctionProvider.normalize_node(node) end
