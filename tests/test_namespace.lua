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
local function create_language_pre_case(lang, subdir, test_cases)
  return function()
    -- Ensure parser is available.
    local parser_was_installed = h.ensure_parser_available(lang, child)
    -- If parser was just installed, restart child to reload it.
    if parser_was_installed then
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua([[treescope = require("treescope")]])
      child.lua("treescope.setup()")
    end
    -- Open test file and set filetype explicitly.
    local marker = mini_test.current.case.args[1]
    local case_data = test_cases[marker]
    local resource_file = vim.fs.joinpath(h.resources_dir, "namespace", subdir, case_data.filename)
    child.cmd(string.format("edit %s | set filetype=%s", resource_file, lang))
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

-- Helper to create a language-specific test set.
local function create_language_test_set(lang, subdir, test_cases)
  local test_set = new_set({
    parametrize = h.map_test_cases_to_parameterize_data(test_cases),
    hooks = {
      pre_case = create_language_pre_case(lang, subdir, test_cases),
      post_case = create_language_post_case(test_cases),
    },
  })
  test_set["parametrized"] = function(marker, expected)
    h.set_cursor_from_marker(marker, child)
    local text = child.lua_get('treescope.get("namespace").text')
    h.assert_scope(expected, text)
  end
  return test_set
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

T["e2e_namespace"]["clojure"] = create_language_test_set("clojure", "clojure", clojure_test_cases)

local java_test_cases = {
  ["7d4e1f9a"] = {
    expected = "com.example",
    note = "simple package",
    filename = "simple_package.txt",
  },
  ["2c8b5a3f"] = {
    expected = "com.example.service.impl",
    note = "deep package",
    filename = "deep_package.txt",
  },
  ["6e1d0c9b"] = {
    expected = nil,
    note = "no package declaration",
    filename = "no_package.txt",
  },
  ["3a7f2e8d"] = {
    expected = "com.example",
    note = "cursor on package declaration",
    filename = "cursor_on_package.txt",
  },
  ["9b4c6a1e"] = {
    expected = "com.example",
    note = "javadoc before package",
    filename = "javadoc_before_package.txt",
  },
  ["5f2d8e4c"] = {
    expected = "mypackage",
    note = "single segment package",
    filename = "single_segment_package.txt",
  },
}

T["e2e_namespace"]["java"] = create_language_test_set("java", "java", java_test_cases)

return T
