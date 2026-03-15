local M = {}

---@param filetype string
---@return OuterFunctionProvider?
function M.get_outer_function_provider(filetype)
  if filetype == nil then
    return nil
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
    return nil
  end
  local provider = require("treescope.providers.outer_function." .. filetype)
  return provider
end

---@return table
function M.get_clojure_namespace_provider()
  local provider = require("treescope.providers.clojure.namespace")
  return provider
end

---@param filetype string
---@return table?
function M.get_yq_path_provider(filetype)
  local base = "treescope.providers.yq_path."
  local supported_filetypes = { "yaml", "json", "jsonc" }
  if not vim.tbl_contains(supported_filetypes, filetype) then
    return nil
  end
  local provider
  if filetype == "jsonc" then
    provider = require(base .. "json")
  else
    provider = require(base .. filetype)
  end
  return provider
end

return M
