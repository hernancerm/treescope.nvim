-- Benchmark: outer_function() — cached vs uncached parse
-- Usage (run twice, once at HEAD~1 and once at HEAD):
--   nvim --headless --noplugin -u ./scripts/minimal_init.lua \
--        -c "luafile scripts/bench_outer_function.lua"

local resource = vim.fn.fnamemodify("tests/resources/outer_function/lua.txt", ":p")
vim.cmd("edit " .. resource)
local bufnr = vim.api.nvim_get_current_buf()
local win = vim.api.nvim_get_current_win()

-- Set filetype explicitly so treescope picks the right provider
vim.api.nvim_buf_set_option(bufnr, "filetype", "lua")

local treescope = require("treescope")
treescope.setup()

-- Five lines spread across the 72-line fixture, each inside a function body
local positions = { 5, 17, 23, 47, 64 }
local N = 1000

local t0 = vim.loop.hrtime()
for i = 1, N do
  local row = positions[(i % #positions) + 1]
  vim.api.nvim_win_set_cursor(win, { row, 0 })
  treescope.outer_function()
end
local elapsed_ms = (vim.loop.hrtime() - t0) / 1e6

print(string.format("%d calls | %.2f ms total | %.3f µs/call", N, elapsed_ms, elapsed_ms * 1000 / N))
vim.cmd("qa!")
