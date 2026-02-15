local const = require("treescope.const")

local M = {}

---@param filetype string? Case-insensitive.
---@return const.LanguageIds?
function M.get_language_id(filetype)
  if not filetype then
    return nil
  end
  return const.LanguageId[vim.fn.toupper(filetype)]
end

---@param language_id const.LanguageIds
---@return OuterFunctionProvider
function M.get_outer_function_provider(language_id)
  assert(language_id, "provider_id is required")
  local status, result =
    pcall(require, "treescope.providers.outer_function." .. language_id)
  assert(
    status,
    string.format("Outer function provider for lang '%s' not found.", language_id)
  )
  return result
end

---@return table
function M.get_clojure_namespace_provider()
  local provider = require("treescope.providers.clojure.namespace")
  return provider
end

return M
