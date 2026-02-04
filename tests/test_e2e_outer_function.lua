---@diagnostic disable: undefined-field, undefined-global

local h = dofile("tests/helpers.lua")

local new_set = MiniTest.new_set
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

local javascript_test_cases = {
  ["3f7a2b1c"] = { expected = nil, note = "top-level" },
  ["5k9m1p4x"] = { expected = "greet", note = "function declaration" },
  ["8l1o3c5a"] = { expected = "fetchData", note = "async function declaration" },
  ["2q8r6t9v"] = { expected = "salute", note = "arrow function assigned to variable" },
  ["4e6g9s2u"] = { expected = "asyncFetch", note = "async arrow function" },
  ["7w2d4f8h"] = { expected = "processData", note = "nested function" },
  ["1n3b5j7c"] = { expected = "processData", note = "deeply nested function" },
  ["6i4p8v2w"] = { expected = "foo", note = "function expression assigned to variable" },
}

T["e2e"]["javascript"] = new_set({
  parametrize = h.map_test_cases_to_parameterize_data(javascript_test_cases),
  hooks = {
    pre_case = function()
      -- Ensure JavaScript parser is available.
      local parser_was_installed = h.ensure_parser_available("javascript", child)
      -- If parser was just installed, restart child to reload it.
      if parser_was_installed then
        child.restart({ "-u", "scripts/minimal_init.lua" })
        child.lua([[treescope = require("treescope")]])
        child.lua("treescope.setup()")
      end
      -- Open test file and set filetype explicitly.
      local resource_file = vim.fs.joinpath(h.resources_dir, "javascript.js")
      child.cmd(string.format("edit %s | set filetype=javascript", resource_file))
    end,

    post_case = function()
      -- Add case note but only when test fails so that successful tests are not printed.
      local case = MiniTest.current.case
      if #case.exec.fails > 0 then
        local marker = case.args[1]
        if javascript_test_cases[marker] then
          MiniTest.add_note("Case: " .. javascript_test_cases[marker].note)
        end
      end
    end,
  },
})

T["e2e"]["javascript"]["returns correct outer function name"] = function(marker, expected)
  h.set_cursor_from_marker(marker, child)
  local scope = child.lua_get("treescope.outer_function()")
  h.assert_scope(expected, scope)
end

return T
