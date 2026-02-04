---@diagnostic disable: undefined-field, undefined-global

local h = dofile("tests/helpers.lua")

local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality
local child = MiniTest.new_child_neovim()

local T = new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua([[treescope = require("treescope")]])
      child.lua([[treescope.setup()]])
    end,
    post_once = function()
      child.stop()
    end,
  },
})

T["e2e"] = new_set({})

T["e2e"]["javascript"] = new_set({
  hooks = {
    pre_case = function()
      -- Ensure JavaScript parser is available
      local parser_was_installed = h.ensure_parser_available("javascript", child)

      -- If parser was just installed, restart child to reload it
      if parser_was_installed then
        child.restart({ "-u", "scripts/minimal_init.lua" })
        child.lua([[treescope = require("treescope")]])
        child.lua([[treescope.setup()]])
      end

      -- Open test file and set filetype explicitly
      local js_file = vim.fs.joinpath(h.resources_dir, "javascript.js")
      child.cmd("edit " .. js_file)
      child.lua([[vim.bo.filetype = "javascript"]])
    end,
  },
})

T["e2e"]["javascript"]["at top-level returns fn name"] = function()
  h.set_cursor_from_marker("3f7a2b1c", child)
  local result = child.lua_get([[require("treescope").outer_function()]])
  eq(result == nil or result == vim.NIL, true)
end

T["e2e"]["javascript"]["at fn declaration body returns fn name"] = function()
  h.set_cursor_from_marker("5k9m1p4x", child)
  local result = child.lua_get([[require("treescope").outer_function()]])
  eq(result, "greet")
end

T["e2e"]["javascript"]["at arrow fn assigned to var returns fn name"] = function()
  h.set_cursor_from_marker("2q8r6t9v", child)
  local result = child.lua_get([[require("treescope").outer_function()]])
  eq(result, "salute")
end

T["e2e"]["javascript"]["at nested fn returns fn name"] = function()
  h.set_cursor_from_marker("7w2d4f8h", child)
  local result = child.lua_get([[require("treescope").outer_function()]])
  eq(result, "processData")
end

T["e2e"]["javascript"]["at deeply nested fn returns fn name"] = function()
  h.set_cursor_from_marker("1n3b5j7c", child)
  local result = child.lua_get([[require("treescope").outer_function()]])
  eq(result, "processData")
end

T["e2e"]["javascript"]["at async arrow fn returns fn name"] = function()
  h.set_cursor_from_marker("4e6g9s2u", child)
  local result = child.lua_get([[require("treescope").outer_function()]])
  eq(result, "asyncFetch")
end

T["e2e"]["javascript"]["at async fn declaration returns fn name"] = function()
  h.set_cursor_from_marker("8l1o3c5a", child)
  local result = child.lua_get([[require("treescope").outer_function()]])
  eq(result, "fetchData")
end

T["e2e"]["javascript"]["at fn expression assigned to var returns fn name"] = function()
  h.set_cursor_from_marker("6i4p8v2w", child)
  local result = child.lua_get([[require("treescope").outer_function()]])
  eq(result, "foo")
end

return T
