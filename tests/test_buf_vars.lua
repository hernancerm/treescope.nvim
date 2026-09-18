local h = dofile("tests/helpers.lua")
local mini_test = require("mini.test")

local child = mini_test.new_child_neovim()
local new_set = mini_test.new_set
local eq = mini_test.expect.equality

local function restart()
  child.restart({ "-u", "scripts/minimal_init.lua" })
  child.lua([[treescope = require("treescope")]])
end

local T = new_set({
  hooks = {
    pre_case = function()
      restart()
      if h.ensure_parser_available("lua", child) then
        restart()
      end
    end,
    post_once = function()
      child.stop()
    end,
  },
})

local function open_lua()
  local resource_file = vim.fs.joinpath(h.resources_dir, "function", "lua.txt")
  child.cmd(string.format("edit %s | set filetype=lua", resource_file))
end

T["string entry uses default depth"] = function()
  child.lua([[treescope.setup({ buf_vars = { "function" } })]])
  open_lua()
  h.set_cursor_from_marker("5y6z7a8b", child)
  child.cmd("doautocmd CursorMoved")
  eq(child.b.treescope_function, "outer")
end

T["table entry with depth gets a suffixed var"] = function()
  child.lua([[treescope.setup({ buf_vars = { "function", { "function", depth = "any" } } })]])
  open_lua()
  h.set_cursor_from_marker("5y6z7a8b", child)
  child.cmd("doautocmd CursorMoved")
  eq(child.b.treescope_function, "outer")
  eq(child.b.treescope_function_any, "deepest")
end

T["var is empty string when there is no scope"] = function()
  child.lua([[treescope.setup({ buf_vars = { "function" } })]])
  open_lua()
  h.set_cursor_from_marker("1a2b3c4d", child)
  child.cmd("doautocmd CursorMoved")
  eq(child.b.treescope_function, "")
end

T["rejects unknown scope id"] = function()
  mini_test.expect.error(function()
    child.lua([[treescope.setup({ buf_vars = { "nope" } })]])
  end, "Invalid value in config.buf_vars")
end

T["rejects invalid depth"] = function()
  child.lua([[treescope.setup({ buf_vars = { { "function", depth = "nope" } } })]])
  open_lua()
  mini_test.expect.error(function()
    child.cmd("doautocmd CursorMoved")
  end, "opts.depth")
end

return T
