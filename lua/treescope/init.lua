local treescope = {}

function treescope.setup()
  local outline_config_augroup = vim.api.nvim_create_augroup("treescope", {})
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = outline_config_augroup,
    callback = function()
      vim.api.nvim_buf_set_var(0, "treescope_outer_function", treescope.outer_function() or "")
    end
  })
end

function treescope.outer_function()
  local provider_id = require("treescope.provider_locator").get_provider_id(vim.bo.filetype)
  local provider = require("treescope.provider_locator").get_provider(provider_id)

  if provider == nil then
    return nil
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1 -- Tree-sitter uses 0-based rows

  local lang = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype)
  local parser = vim.treesitter.get_parser(bufnr, lang)

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

  return provider.get_function_name(candidate, bufnr)
end

return treescope
