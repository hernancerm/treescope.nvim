local M = {}

-- Per scope, the supported filetypes. An empty entry means the provider module
-- and the Tree-sitter language are both named after the filetype. Otherwise
-- `provider` names the module and `lang` the Tree-sitter language. Getting
-- `lang` right matters: it is fed to `vim.treesitter.get_parser()` and to
-- `vim.treesitter.query.get()`, so a wrong name silently yields an empty scope.
local registry = {
  ["function"] = {
    lua = {},
    java = {},
    python = {},
    clojure = {},
    javascript = {},
    typescript = { provider = "javascript" },
    javascriptreact = { provider = "javascript", lang = "javascript" },
    typescriptreact = { provider = "javascript", lang = "tsx" },
  },
  class = {
    java = {},
    python = {},
    javascript = {},
    typescript = { provider = "javascript" },
  },
  code_fence = {
    markdown = {},
  },
  yq_path = {
    yaml = {},
    json = {},
    jsonc = { provider = "json", lang = "json" },
  },
  namespace = {
    clojure = {},
    java = {},
  },
}

--- Per scope id, the supported filetypes mapped to their Tree-sitter language.
---@return table<const.ScopeIds, table<string, string>>
function M.get_supported()
  local supported = {}
  for scope_id, filetypes in pairs(registry) do
    supported[scope_id] = {}
    for filetype, entry in pairs(filetypes) do
      supported[scope_id][filetype] = entry.lang or filetype
    end
  end
  return supported
end

--- Returns the provider and the Tree-sitter language name for {scope_id} in
--- {filetype}, or nothing when the filetype is not supported.
---@param scope_id const.ScopeIds
---@param filetype string?
---@return table? provider
---@return string? lang
function M.get(scope_id, filetype)
  if not filetype or filetype == "" then
    return
  end
  local entry = registry[scope_id] and registry[scope_id][filetype]
  if not entry then
    return
  end
  local provider = require(
    "treescope.providers." .. scope_id .. "." .. (entry.provider or filetype)
  )
  return provider, entry.lang or filetype
end

return M
