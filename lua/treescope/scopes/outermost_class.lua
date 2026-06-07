local M = {}

--- See docs for matching function in |treescope.outermost_class()|.
---@return treescope.OutermostClass
function M.get_scope()
  local empty = { text = nil }

  local bufnr = vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return empty
  end

  local filetype = vim.bo[bufnr].filetype
  if not filetype or filetype == "" then
    return empty
  end

  local provider_locator = require("treescope.provider_locator")
  local provider, lang = provider_locator.get_outermost_class_provider(filetype)
  if not provider or not lang then
    return empty
  end

  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_buf(win) ~= bufnr then
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

  local cursor = vim.api.nvim_win_get_cursor(win)
  local row, col = cursor[1] - 1, cursor[2]

  local pos_node = root:named_descendant_for_range(row, col, row, col)
  if not pos_node then
    return empty
  end

  local cur_node = pos_node
  local outermost_class_node = nil
  while cur_node do
    if provider.is_class(cur_node) then
      outermost_class_node = cur_node
    end
    cur_node = cur_node:parent()
  end

  if not outermost_class_node then
    return empty
  end

  return {
    text = provider.get_class_name(outermost_class_node, bufnr),
  }
end

return M
