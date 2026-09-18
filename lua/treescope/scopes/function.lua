local node_scope = require("treescope.node_scope")

local M = {}

---@param ctx treescope.Ctx
---@param row integer
---@param col integer
---@param depth const.Depth
---@return treescope.Scope
function M.get(ctx, row, col, depth)
  return node_scope.get(ctx, row, col, depth)
end

---@param ctx treescope.Ctx
---@param depth const.Depth
---@return treescope.Scope[]
function M.list(ctx, depth)
  return node_scope.list(ctx, "treescope_function", depth)
end

return M
