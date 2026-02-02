local crumbs = {}

function crumbs.setup()
  local outline_config_augroup = vim.api.nvim_create_augroup("Crumbs", {})
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = outline_config_augroup,
    callback = function()
      vim.api.nvim_buf_set_var(0, "crumbs_function", crumbs.get_toplevel_function_at_cursor() or "")
    end
  })
end

function crumbs.get_toplevel_function_at_cursor()
  local provider = require("crumbs.provider_locator").get_provider(vim.bo.filetype)

  if provider == nil then
    return nil
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1 -- Tree-sitter uses 0-based rows

  local parser = vim.treesitter.get_parser(bufnr, "lua")
  if not parser then
    return nil
  end

  local tree = parser:parse()[1]
  local root = tree:root()

  local node = root:named_descendant_for_range(row, col, row, col)
  if not node then
    return nil
  end

  local candidate = nil
  local cur = node

  -- Walk up: remember the outermost function
  while cur do
    if provider.is_function(cur) then
      candidate = cur
    end
    cur = cur:parent()
  end

  if not candidate then
    return nil
  end

  -- Reject if nested inside another function
  cur = candidate:parent()
  while cur do
    if provider.is_function(cur) then
      return nil
    end
    cur = cur:parent()
  end

  return provider.get_function_signature(candidate, bufnr)
end

return crumbs
