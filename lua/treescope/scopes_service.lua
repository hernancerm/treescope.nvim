local M = {}

--- See docs for matching function in |treescope.outermost_function()|.
function M.outermost_function()
  local bufnr = vim.api.nvim_get_current_buf()

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end

  local filetype = vim.bo[bufnr].filetype
  if not filetype or filetype == "" then
    return nil
  end

  local win = vim.api.nvim_get_current_win()
  -- col is not needed, function scopes span full lines.
  local row = unpack(vim.api.nvim_win_get_cursor(win))
  row = row - 1

  if vim.api.nvim_win_get_buf(win) ~= bufnr then
    return nil
  end

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, filetype)
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

  local query_service = require("treescope.query_service")
  local result = query_service.outermost_function(filetype, root, bufnr, row)
  return result
end

--- See docs for matching function in |treescope.yq_path()|.
function M.yq_path()
  local bufnr = vim.api.nvim_get_current_buf()

  -- Validate buffer.
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end

  local filetype = vim.bo[bufnr].filetype

  -- Get provider.
  local provider_locator = require("treescope.provider_locator")
  local provider, lang = provider_locator.get_yq_path_provider(filetype)
  if not provider or not lang then
    return nil
  end

  -- Get Tree-sitter parser.
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

  -- Get cursor position.
  local win = vim.api.nvim_get_current_win()
  local row, col = unpack(vim.api.nvim_win_get_cursor(win))
  row = row - 1

  local node = root:named_descendant_for_range(row, col, row, col)
  if not node then
    return nil
  end

  return provider.get_path(node, bufnr)
end

--- See docs for matching function in |treescope.namespace()|.
function M.namespace()
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

  return provider.get_namespace(root, bufnr)
end

return M
