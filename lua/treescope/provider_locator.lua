local M = {}

---@class Provider
---@field is_function fun(node: TSNode): boolean
---@field get_function_name fun(node: TSNode, bufnr: integer): string?

---@enum provider_ids
M.provider_ids = {
  lua = "lua",
  java = "java",
}

---@param filetype string
---@return provider_ids?
function M.get_provider_id(filetype)
  assert(filetype)
  return M.provider_ids[filetype]
end

---@param provider_id provider_ids
---@return Provider
function M.get_provider(provider_id)
  assert(provider_id)
  return require("treescope.providers." .. provider_id)
end

return M
