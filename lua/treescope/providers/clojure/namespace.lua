local M = {}

local query = [[
  (list_lit
    value: (sym_lit
             name: (sym_name) @clj_ns_fn (#eq? @clj_ns_fn "ns"))
    value: (sym_lit
             name: (sym_name) @clj_ns_value))
]]

local ts_query = nil

---@param root TSNode
---@param bufnr integer
---@return string?
function M.get_namespace(root, bufnr)
  if not ts_query then
    ts_query = vim.treesitter.query.parse("clojure", query)
  end
  local captures = {}
  for _, node, _ in ts_query:iter_captures(root, bufnr) do
    table.insert(captures, vim.treesitter.get_node_text(node, bufnr))
  end
  if #captures == 2 and captures[1] == "ns" then
    return captures[2]
  end
end

return M
