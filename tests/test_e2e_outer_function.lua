local h = dofile("tests/helpers.lua")

local mini_test = require("test")
local new_set = mini_test.new_set
local child = mini_test.new_child_neovim()

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

T["e2e"] = new_set({})

-- Helper for pre_case hook.
local function create_language_pre_case(lang, filename, filetype)
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
    local resource_file = vim.fs.joinpath(h.resources_dir, filename)
    child.cmd(string.format("edit %s | set filetype=%s", resource_file, filetype))
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
local function create_language_test_set(lang, filename, filetype, test_cases)
  local test_set = new_set({
    parametrize = h.map_test_cases_to_parameterize_data(test_cases),
    hooks = {
      pre_case = create_language_pre_case(lang, filename, filetype),
      post_case = create_language_post_case(test_cases),
    },
  })
  test_set["returns correct outer function name"] = function(marker, expected)
    h.set_cursor_from_marker(marker, child)
    local scope = child.lua_get("treescope.outer_function()")
    h.assert_scope(expected, scope)
  end
  return test_set
end

local javascript_test_cases = {
  ["3f7a2b1c"] = { expected = nil, note = "top-level" },
  ["5k9m1p4x"] = { expected = "greet", note = "function declaration" },
  ["8l1o3c5a"] = { expected = "fetchData", note = "async function declaration" },
  ["2q8r6t9v"] = { expected = "salute", note = "arrow function assigned to variable" },
  ["4e6g9s2u"] = { expected = "asyncFetch", note = "async arrow function" },
  ["7w2d4f8h"] = { expected = "processData", note = "nested function" },
  ["1n3b5j7c"] = { expected = "processData", note = "deeply nested function" },
  ["6i4p8v2w"] = { expected = "foo", note = "function assigned to variable" },
}

T["e2e"]["javascript"] =
  create_language_test_set("javascript", "javascript.js", "javascript", javascript_test_cases)

local clojure_test_cases = {
  ["9a3b5c7d"] = { expected = nil, note = "top-level" },
  ["1x2y3z4w"] = { expected = "greet", note = "function declaration" },
  ["2k3l4m5n"] = { expected = "process-data", note = "nested anonymous function" },
  ["8d9e0f1g"] = { expected = "process-data", note = "nested defn" },
  ["6g7h8i9j"] = { expected = "fetch-data", note = "deeply nested defn" },
  ["5m6n7o8p"] = { expected = "salute", note = "function assigned to variable" },
}

T["e2e"]["clojure"] =
  create_language_test_set("clojure", "clojure.clj", "clojure", clojure_test_cases)

return T
