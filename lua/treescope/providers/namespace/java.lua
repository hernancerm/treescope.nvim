local M = {}

local query = [[
  (package_declaration [
    (scoped_identifier) @java_ns_value
    (identifier) @java_ns_value
  ])
]]

local ts_query = nil

---@param root TSNode
---@param bufnr integer
---@return string?
function M.get_namespace(root, bufnr)
  if not ts_query then
    ts_query = vim.treesitter.query.parse("java", query)
  end
  for _, node, _ in ts_query:iter_captures(root, bufnr) do
    return vim.treesitter.get_node_text(node, bufnr)
  end
end

return M
