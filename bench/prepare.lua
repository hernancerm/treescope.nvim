-- Install the Lua parser and write the fixture: a large Lua file with nested
-- functions, shaped like a busted spec (describe > it > callbacks). Generated
-- so that no third-party code is committed.
-- Usage: nvim --headless --noplugin -u ./scripts/minimal_init.lua -l bench/prepare.lua <fixture>

local fixture = _G.arg[1]
assert(fixture, "fixture path is required")

if not vim.list_contains(require("nvim-treesitter").get_installed("parsers"), "lua") then
  require("nvim-treesitter").install({ "lua" }):wait(40000)
end

if vim.uv.fs_stat(fixture) then
  return
end

local lines = { "local M = {}", "" }
local function add(indent, line)
  table.insert(lines, string.rep("  ", indent) .. line)
end
for i = 1, 190 do
  add(0, ('describe("group %d", function()'):format(i))
  add(1, ("local function setup_%d()"):format(i))
  add(2, ("return %d"):format(i))
  add(1, "end")
  add(0, "")
  for j = 1, 5 do
    add(1, ('it("case %d.%d", function()'):format(i, j))
    add(2, "local t = {")
    add(3, "cb = function()")
    add(4, ("return setup_%d() + %d"):format(i, j))
    add(3, "end,")
    add(2, "}")
    add(2, ("M.run_%d_%d = function()"):format(i, j))
    add(3, "return t.cb()")
    add(2, "end")
    add(2, ("assert(M.run_%d_%d() > 0)"):format(i, j))
    add(1, "end)")
    add(0, "")
  end
  add(0, "end)")
  add(0, "")
end
add(0, "return M")

vim.fn.mkdir(vim.fs.dirname(fixture), "p")
vim.fn.writefile(lines, fixture)
