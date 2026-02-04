local h = {}

h.resources_dir = vim.fs.joinpath(vim.fn.getcwd(), "tests", "resources")

--- Set cursor position from a marker comment in the child instance
---@param marker_id string The alphanumeric string after "cursor-" (e.g., "3f7a2b1c")
---@param child MiniTest.ChildNeovim The child Neovim instance
function h.set_cursor_from_marker(marker_id, child)
  child.lua(string.format(
    [[
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local marker_text = "cursor-%s"
    for line_num, line_content in ipairs(lines) do
      if line_content:find(marker_text, 1, true) then
        local start_pos = line_content:find(marker_text, 1, true)
        local cursor_col = start_pos + #marker_text - 1
        vim.api.nvim_win_set_cursor(0, {line_num, cursor_col})
        return
      end
    end
    error("Marker 'cursor-%s' not found in buffer")
  ]],
    marker_id,
    marker_id
  ))
end

--- Ensure a Tree-sitter parser is installed, fail-fast if not available
---@param lang string The Tree-sitter language name (e.g., "javascript")
---@param child MiniTest.ChildNeovim The child Neovim instance
function h.ensure_parser_available(lang, child)
  -- Attempt to install the parser synchronously with 60 second timeout
  -- This is a no-op if the parser is already installed
  child.lua(string.format("require('nvim-treesitter').install({'%s'}):wait(60000)", lang))
end

return h
