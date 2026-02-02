local M = {}

---@class Provider
---@field is_function fun(node: TSNode): boolean
---@field get_function_name fun(node: TSNode, bufnr: integer): string?

---@enum ProviderIds
M.ProviderIds = {
  lua = 0,
  java = 1
}

---@param filetype string
---@return ProviderIds?
function M.get_provider_id(filetype)
  return M.ProviderIds[filetype]
end

---@param provider_id ProviderIds
---@return Provider?
function M.get_provider(provider_id)
  if provider_id == nil then
    return nil
  end
  local filetype = vim.api.nvim_get_option_value("filetype", { buf = 0 })
  local status, result = pcall(require, "crumbs.providers." .. filetype)
  if status then
    return result
  else
    return nil
  end
end

return M
