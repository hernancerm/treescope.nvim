local M = {}

---@class Provider
---@field is_function fun(node: TSNode): boolean
---@field get_function_signature fun(node: TSNode, bufnr: integer): string

---@alias ProviderNames "lua"

---@param provider_name ProviderNames
---@return Provider?
function M.get_provider(provider_name)
  if provider_name == nil then
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
