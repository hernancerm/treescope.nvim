-- Time `get()` in a headless loop. Runs hot, so numbers are lower than in a
-- real UI (see `bench/ui.sh`), but good to compare two versions of the code.
-- Usage: nvim --headless --noplugin -u ./scripts/minimal_init.lua -l bench/get.lua <file>

local file = _G.arg[1]
assert(file, "file path is required")
vim.cmd.edit(file)
local treescope = require("treescope")
local hrtime = vim.uv.hrtime
local stats = dofile(vim.fs.joinpath(vim.fs.dirname(_G.arg[0]), "stats.lua"))

local line_count = vim.api.nvim_buf_line_count(0)
math.randomseed(42)
local rows = {}
for i = 1, 2000 do
  rows[i] = math.random(1, line_count)
end

local start = hrtime()
treescope.get("function")
print(("%s (%d lines)"):format(vim.fs.basename(file), line_count))
print(("  first get(), full parse: %.1f ms"):format((hrtime() - start) / 1e6))

local no_edit = {}
for i, row in ipairs(rows) do
  vim.api.nvim_win_set_cursor(0, { row, 0 })
  start = hrtime()
  treescope.get("function")
  no_edit[i] = hrtime() - start
end
print("  get(), no edit:           " .. stats(no_edit))

-- Each turn edits twice: add a space, then remove it. After the first edit,
-- time `get()`, which reparses first. After the second, time the reparse alone.
-- In a real UI the highlighter usually reparsed already, so `get()` mostly
-- skips that part.
local after_edit, parse_only = {}, {}
for i = 1, 300 do
  local row = rows[i]
  vim.api.nvim_buf_set_text(0, row - 1, 0, row - 1, 0, { " " })
  vim.api.nvim_win_set_cursor(0, { row, 0 })
  start = hrtime()
  treescope.get("function")
  after_edit[i] = hrtime() - start
  vim.api.nvim_buf_set_text(0, row - 1, 0, row - 1, 1, { "" })
  start = hrtime()
  vim.treesitter.get_parser(0):parse()
  parse_only[i] = hrtime() - start
end
print("  get(), after edit:        " .. stats(after_edit))
print("  parse() only, after edit: " .. stats(parse_only))
