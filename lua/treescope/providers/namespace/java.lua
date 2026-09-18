local M = {}

local query = [[
  (package_declaration [
    (scoped_identifier) @java_ns_value
    (identifier) @java_ns_value
  ]) @java_ns_decl
]]

local ts_query = nil

---@param root TSNode
---@param bufnr integer
---@return TSNode? node
---@return TSNode? name_node
function M.get_namespace(root, bufnr)
  if not ts_query then
    ts_query = vim.treesitter.query.parse("java", query)
  end
  for _, match in ts_query:iter_matches(root, bufnr, 0, -1, { all = true }) do
    local decl, name
    for id, nodes in pairs(match) do
      local capture = ts_query.captures[id]
      if capture == "java_ns_decl" then
        decl = nodes[1]
      elseif capture == "java_ns_value" then
        name = nodes[1]
      end
    end
    if decl and name then
      return decl, name
    end
  end
end

---@type NamespaceProvider
local _ = M

return M
