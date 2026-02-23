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

---@return table
function M.get_yaml_path_provider()
  local provider = require("treescope.providers.yaml.path")
  return provider
end

return M
