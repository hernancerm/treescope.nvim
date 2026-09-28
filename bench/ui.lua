-- Config for the real-UI run, see `bench/ui.sh`. The statusline calls `get()`
-- directly and times each call.

local root = vim.env.BENCH_ROOT
vim.opt.rtp:append(root)
vim.opt.rtp:append(root .. "/deps/parsers")
vim.o.laststatus = 2
vim.o.swapfile = false
require("treescope")

local stats = dofile(root .. "/bench/stats.lua")

local phase = "startup"
local phases = {}

local function current()
  if not phases[phase] then
    phases[phase] = { durations = {} }
  end
  return phases[phase]
end

function _G.BenchStatusline()
  local start = vim.uv.hrtime()
  local text = Treescope.get("function").text or ""
  table.insert(current().durations, vim.uv.hrtime() - start)
  return text
end

function _G.BenchPhase(name)
  phase = name
end

function _G.BenchDump()
  local lines = {}
  for _, name in ipairs({ "move", "insert" }) do
    local p = phases[name]
    table.insert(lines, ("%-6s statusline evals %4d"):format(name, #p.durations))
    table.insert(lines, "  get(): " .. stats(p.durations))
  end
  vim.fn.writefile(lines, vim.env.BENCH_OUT)
end

vim.api.nvim_create_autocmd("FileType", {
  callback = function(ev)
    pcall(vim.treesitter.start, ev.buf)
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.fn.writefile({}, vim.env.BENCH_READY)
  end,
})

vim.o.statusline = "%{v:lua.BenchStatusline()} %l:%c"
