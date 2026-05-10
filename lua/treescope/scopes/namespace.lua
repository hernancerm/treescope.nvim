local M = {}

--- See docs for matching function in |treescope.namespace()|.
---@return treescope.Namespace
function M.get_scope()
  local empty = {
    text = nil,
  }

  local bufnr = vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return empty
  end

  local filetype = vim.bo[bufnr].filetype

  local provider_locator = require("treescope.provider_locator")
  local provider, lang = provider_locator.get_namespace_provider(filetype)
  if not provider or not lang then
    return empty
  end

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
  if not ok or not parser then
    return empty
  end

  local trees = parser:parse()
  if not trees or #trees == 0 then
    return empty
  end

  local root = trees[1]:root()
  if not root then
    return empty
  end

  return {
    text = provider.get_namespace(root, bufnr),
  }
end

return M
