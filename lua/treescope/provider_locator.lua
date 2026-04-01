local M = {}

--- Returns provider and Tree-sitter lang for required parser.
---@param filetype string
---@return OuterFunctionProvider?
---@return string?
function M.get_outer_function_provider(filetype)
  local base = "treescope.providers.outer_function."
  if filetype == nil then
    return
  end
  local supported_filetypes = {
    "lua",
    "java",
    "python",
    "clojure",
    "javascript",
    "typescript",
  }
  if not vim.tbl_contains(supported_filetypes, filetype) then
    return
  end
  local provider
  if filetype == "typescript" then
    provider = require(base .. "javascript")
  else
    provider = require(base .. filetype)
  end
  return provider, filetype
end

--- Returns provider and Tree-sitter lang for required parser.
---@param filetype string
---@return YqPathProvider?
---@return string?
function M.get_yq_path_provider(filetype)
  local base = "treescope.providers.yq_path."
  if filetype == nil then
    return
  end
  local supported_filetypes = { "yaml", "json", "jsonc" }
  if not vim.tbl_contains(supported_filetypes, filetype) then
    return
  end
  local provider
  local lang
  if filetype == "jsonc" then
    provider = require(base .. "json")
    lang = "json"
  else
    provider = require(base .. filetype)
    lang = filetype
  end
  return provider, lang
end

--- Returns provider and Tree-sitter lang for required parser.
---@param filetype string
---@return NamespaceProvider?
---@return string?
function M.get_namespace_provider(filetype)
  local providers = {
    clojure = { mod = "treescope.providers.namespace.clojure", lang = "clojure" },
  }
  local entry = providers[filetype]
  if not entry then
    return
  end
  return require(entry.mod), entry.lang
end

return M
