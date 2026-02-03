local const = require("treescope.const")

local M = {}

---@class Provider
---@field is_function fun(node: TSNode): boolean
---@field get_function_name fun(node: TSNode, bufnr: integer): string?

---@param filetype string? Case-insensitive.
---@return const.ProviderIds?
function M.get_provider_id(filetype)
  if not filetype then
    return nil
  end
  return const.ProviderIds[vim.fn.toupper(filetype)]
end

---@param provider_id const.ProviderIds
---@return Provider
function M.get_provider(provider_id)
  assert(provider_id, "provider_id is required")
  local status, result = pcall(require, "treescope.providers." .. provider_id)
  assert(status, string.format("Provider with id '%s' not found.", provider_id))
  return result
end

return M
