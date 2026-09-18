local M = {}

local query = [[
  (list_lit
    value: (sym_lit
             name: (sym_name) @clj_ns_fn (#eq? @clj_ns_fn "ns"))
    value: (sym_lit
             name: (sym_name) @clj_ns_value)) @clj_ns_form
]]

local ts_query = nil

---@param root TSNode
---@param bufnr integer
---@return TSNode? node
---@return TSNode? name_node
function M.get_namespace(root, bufnr)
  if not ts_query then
    ts_query = vim.treesitter.query.parse("clojure", query)
  end
  for _, match in ts_query:iter_matches(root, bufnr, 0, -1, { all = true }) do
    local form, name
    for id, nodes in pairs(match) do
      local capture = ts_query.captures[id]
      if capture == "clj_ns_form" then
        form = nodes[1]
      elseif capture == "clj_ns_value" then
        name = nodes[1]
      end
    end
    if form and name then
      return form, name
    end
  end
end

---@type NamespaceProvider
local _ = M

return M
