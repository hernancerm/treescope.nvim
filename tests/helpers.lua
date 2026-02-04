local h = {}

local mini_test = require("test")
local eq = mini_test.expect.equality

h.resources_dir = vim.fs.joinpath(vim.fn.getcwd(), "tests", "resources")

--- Assert expected vs. actual handling nil comparison properly.
---@param expected_scope string?
---@param actual_scope string?
function h.assert_scope(expected_scope, actual_scope)
  if expected_scope == nil then
    eq(true, actual_scope == nil or actual_scope == vim.NIL)
  else
    eq(expected_scope, actual_scope)
  end
end

--- Map test case data with the following structure:
---     { ["3f7a2b1c"] = { expected = nil, note = "top-level" }, ... }
--- To this structure for use by the `parametrize` key of a mini.test test set.
---    { { "3f7a2b1c", nil }, ... }
function h.map_test_cases_to_parameterize_data(test_cases)
  local parametrize_data = {}
  for marker, case_data in pairs(test_cases) do
    table.insert(parametrize_data, { marker, case_data.expected })
  end
  return parametrize_data
end

--- Set cursor position from a marker comment in the child instance.
---@param marker_id string The alphanumeric string after "cursor-" (e.g., "3f7a2b1c").
---@param child MiniTest.child The child Neovim instance.
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

--- Ensure a Tree-sitter parser is installed. Returns true if the parser was installed (in this case
--- the client needs to restart the child); false, if the parser was already installed.
---@param lang string The Tree-sitter language name (e.g., "javascript").
---@param child MiniTest.child The child Neovim instance.
---@return boolean
function h.ensure_parser_available(lang, child)
  -- Check if parser is already installed.
  child.lua(string.format(
    [[
      _treescope_parser_installed = vim.list_contains(
        require('nvim-treesitter.config').get_installed('parsers'),
        %q)
  ]],
    lang
  ))
  if child.lua_get("_treescope_parser_installed") then
    -- Parser already installed. No need to install.
    return false
  end
  -- Install the parser synchronously with 45 seconds timeout.
  child.lua(string.format("require('nvim-treesitter').install({'%s'}):wait(45000)", lang))
  -- Parser was installed.
  return true
end

return h
