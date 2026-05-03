local M = {}

--- See docs for matching function in |treescope.namespace()|.
---@return treescope.Namespace
function M.get_value()
  local bufnr = vim.api.nvim_get_current_buf()

  -- Validate buffer.
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end

  local filetype = vim.bo[bufnr].filetype

  -- Get provider.
  local provider_locator = require("treescope.provider_locator")
  local provider, lang = provider_locator.get_namespace_provider(filetype)
  if not provider or not lang then
    return nil
  end

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
  if not ok or not parser then
    return nil
  end

  local trees = parser:parse()
  if not trees or #trees == 0 then
    return nil
  end

  local root = trees[1]:root()
  if not root then
    return nil
  end

  return {
    text = provider.get_namespace(root, bufnr)
  }
end

return M
