local M = {}

---@param ctx treescope.Ctx
---@return treescope.Scope
function M.get(ctx)
  local node, name_node = ctx.provider.get_namespace(ctx.root, ctx.buf)
  if not node then
    return {}
  end
  return {
    text = name_node and vim.treesitter.get_node_text(name_node, ctx.buf),
    node = node,
    name_node = name_node,
  }
end

return M
