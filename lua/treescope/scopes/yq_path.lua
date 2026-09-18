local M = {}

---@param ctx treescope.Ctx
---@param row integer
---@param col integer
---@return treescope.Scope
function M.get(ctx, row, col)
  local node = ctx.root:named_descendant_for_range(row, col, row, col)
  if not node then
    return {}
  end
  -- The path is built from all ancestors, so no single node owns it.
  return { text = ctx.provider.get_path(node, ctx.bufnr) }
end

return M
