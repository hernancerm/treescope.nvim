local M = {}

local query = [[
  (list_lit
    value: (sym_lit
             name: (sym_name) @clj_ns_fn (#eq? @clj_ns_fn "ns"))
    value: (sym_lit
             name: (sym_name) @clj_ns_value))
]]

---@return string?
function M.get_namespace()
  local ts_query = vim.treesitter.query.parse("clojure", query)
  local tree = vim.treesitter.get_parser():parse()[1]
  local captures = {}
  local bufnr = vim.fn.bufnr()
  for _, node, _ in ts_query:iter_captures(tree:root(), 0) do
    table.insert(captures, vim.treesitter.get_node_text(node, bufnr))
  end
  if #captures == 2 and captures[1] == "ns" then
    return captures[2]
  end
end

return M
