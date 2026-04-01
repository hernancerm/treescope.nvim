local h = dofile("tests/helpers.lua")
local mini_test = require("mini.test")

local child = mini_test.new_child_neovim()
local new_set = mini_test.new_set

local T = new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua([[treescope = require("treescope")]])
      child.lua("treescope.setup()")
    end,
    post_once = function()
      child.stop()
    end,
  },
})

T["e2e_namespace"] = new_set({})

-- Helper for pre_case hook.
local function create_language_pre_case(test_cases)
  return function()
    -- Ensure parser is available.
    local parser_was_installed = h.ensure_parser_available("clojure", child)
    -- If parser was just installed, restart child to reload it.
    if parser_was_installed then
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua([[treescope = require("treescope")]])
      child.lua("treescope.setup()")
    end
    -- Open test file and set filetype explicitly.
    local marker = mini_test.current.case.args[1]
    local case_data = test_cases[marker]
    local resource_file =
      vim.fs.joinpath(h.resources_dir, "namespace", "clojure", case_data.filename)
    child.cmd(string.format("edit %s | set filetype=clojure", resource_file))
  end
end

-- Helper for post_case hook.
local function create_language_post_case(test_cases)
  return function()
    -- Add case note but only when test fails so that successful tests are not printed.
    local case = mini_test.current.case
    if #case.exec.fails > 0 then
      local marker = case.args[1]
      if test_cases[marker] then
        mini_test.add_note("Case: " .. test_cases[marker].note)
      end
    end
  end
end

local clojure_test_cases = {
  ["3f7a2b1c"] = {
    expected = "my.namespace",
    note = "simple namespace",
    filename = "simple_namespace.txt",
  },
  ["5k9m1p4x"] = {
    expected = "my.namespace",
    note = "namespace with require",
    filename = "namespace_with_require.txt",
  },
  ["8l1o3c5a"] = {
    expected = "com.example.api",
    note = "namespaced symbol",
    filename = "namespaced_symbol.txt",
  },
  ["2q8r6t9v"] = {
    expected = "my.app",
    note = "namespace with multiple options",
    filename = "namespace_with_options.txt",
  },
  ["9z8y7x6w"] = {
    expected = nil,
    note = "no namespace in file",
    filename = "no_namespace.txt",
  },
  ["4e6g9s2u"] = {
    expected = "my-app.core",
    note = "cursor on namespace name",
    filename = "namespace_cursor_on_name.txt",
  },
}

T["e2e_namespace"]["clojure"] = new_set({
  parametrize = h.map_test_cases_to_parameterize_data(clojure_test_cases),
  hooks = {
    pre_case = create_language_pre_case(clojure_test_cases),
    post_case = create_language_post_case(clojure_test_cases),
  },
})

T["e2e_namespace"]["clojure"]["parametrized"] = function(marker, expected)
  h.set_cursor_from_marker(marker, child)
  local namespace = child.lua_get("treescope.namespace()")
  h.assert_scope(expected, namespace)
end

return T
