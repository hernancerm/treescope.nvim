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

T["e2e_outermost_function"] = new_set({})

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
    local resource_file = vim.fs.joinpath(h.resources_dir, "outermost_function", filename)
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
  test_set["parametrized"] = function(marker, expected)
    h.set_cursor_from_marker(marker, child)
    local text = child.lua_get("treescope.outermost_function().text")
    h.assert_scope(expected, text)
  end
  return test_set
end

local javascript_test_cases = {
  ["3f7a2b1c"] = { expected = nil, note = "top-level" },
  ["5k9m1p4x"] = { expected = "greet", note = "function declaration" },
  ["8l1o3c5a"] = { expected = "fetchData", note = "async function declaration" },
  ["2q8r6t9v"] = { expected = "salute", note = "arrow function assigned to variable" },
  ["9z8y7x6w"] = {
    expected = "salute",
    note = "arrow function assigned to variable - cursor on identifier",
  },
  ["4e6g9s2u"] = { expected = "asyncFetch", note = "async arrow function" },
  ["7w2d4f8h"] = { expected = "processData", note = "nested function" },
  ["1n3b5j7c"] = { expected = "processData", note = "deeply nested function" },
  ["6i4p8v2w"] = { expected = "foo", note = "function expression assigned to variable" },
  ["5a4b3c2d"] = {
    expected = "foo",
    note = "function expression assigned to variable - cursor on identifier",
  },
  ["eq1c2d3e"] = {
    expected = "js_fn_eq_ts",
    note = "function expression assigned to variable - cursor on `=`",
  },
  ["eq4f5g6h"] = {
    expected = "js_ar_eq_ts",
    note = "arrow function assigned to variable - cursor on `=`",
  },
  ["ziacbd3e"] = {
    expected = "someFunction",
    note = "function assigned to field - cursor on `:`",
  },
  ["zxacbd81"] = {
    expected = "someFunction",
    note = "function assigned to field - cursor on identifier",
  },
  ["fiacbd3e"] = {
    expected = "someFunction",
    note = "function assigned to field - cursor in function body",
  },
  ["yiacbd4e"] = {
    expected = "someFunction2",
    note = "arrow function assigned to field - cursor on `:`",
  },
  ["doacbd88"] = {
    expected = "someFunction2",
    note = "arrow function assigned to field - cursor on identifier",
  },
  ["biac8d3e"] = {
    expected = "someFunction2",
    note = "arrow function assigned to field - cursor in function body",
  },
}

T["e2e_outermost_function"]["javascript"] =
  create_language_test_set("javascript", "javascript.txt", "javascript", javascript_test_cases)

local clojure_test_cases = {
  ["9a3b5c7d"] = { expected = nil, note = "top-level" },
  ["1x2y3z4w"] = { expected = "greet", note = "function declaration" },
  ["2k3l4m5n"] = { expected = "process-data", note = "nested anonymous function" },
  ["8d9e0f1g"] = { expected = "process-data", note = "nested defn" },
  ["6g7h8i9j"] = { expected = "fetch-data", note = "deeply nested defn" },
  ["5m6n7o8p"] = { expected = "salute", note = "function assigned to variable" },
  ["7a1nko2i"] = {
    expected = "salute",
    note = "function assigned to variable - cursor on identifier",
  },
  ["3h4i5j6k"] = {
    expected = "a-test",
    note = "deftest - cursor on identifier",
  },
  ["1q2w3e4r"] = {
    expected = "a-test",
    note = "deftest",
  },
  ["2a4i4k6b"] = {
    expected = "backwards",
    note = "defmacro - cursor on identifier",
  },
  ["1s2i8k6l"] = {
    expected = "backwards",
    note = "defmacro",
  },
}

T["e2e_outermost_function"]["clojure"] =
  create_language_test_set("clojure", "clojure.txt", "clojure", clojure_test_cases)

local typescript_test_cases = {
  ["3f7a2b1c"] = { expected = nil, note = "top-level" },
  ["5k9m1p4x"] = { expected = "greet", note = "function declaration" },
  ["8l1o3c5a"] = { expected = "fetchData", note = "async function declaration" },
  ["2q8r6t9v"] = { expected = "salute", note = "arrow function assigned to variable" },
  ["9z8y7x6w"] = {
    expected = "salute",
    note = "arrow function assigned to variable - cursor on identifier",
  },
  ["4e6g9s2u"] = { expected = "asyncFetch", note = "async arrow function" },
  ["7w2d4f8h"] = { expected = "processData", note = "nested function" },
  ["1n3b5j7c"] = { expected = "processData", note = "deeply nested function" },
  ["6i4p8v2w"] = { expected = "foo", note = "function expression assigned to variable" },
  ["5a4b3c2d"] = {
    expected = "foo",
    note = "function expression assigned to variable - cursor on identifier",
  },
  ["eq7h8i9j"] = {
    expected = "ts_fn_eq_ts",
    note = "function expression assigned to variable - cursor on `=`",
  },
  ["eqabc123"] = {
    expected = "ts_ar_eq_ts",
    note = "arrow function assigned to variable - cursor on `=`",
  },
  ["a1b2c3d4"] = {
    expected = "someFunction",
    note = "function assigned to field - cursor on `:`",
  },
  ["e5f6g7h8"] = {
    expected = "someFunction",
    note = "function assigned to field - cursor on identifier",
  },
  ["i9j0k1l2"] = {
    expected = "someFunction",
    note = "function assigned to field - cursor in function body",
  },
  ["m3n4o5p6"] = {
    expected = "someFunction2",
    note = "arrow function assigned to field - cursor on `:`",
  },
  ["q7r8s9t0"] = {
    expected = "someFunction2",
    note = "arrow function assigned to field - cursor on identifier",
  },
  ["u1v2w3x4"] = {
    expected = "someFunction2",
    note = "arrow function assigned to field - cursor in function body",
  },
}

T["e2e_outermost_function"]["typescript"] =
  create_language_test_set("typescript", "typescript.txt", "typescript", typescript_test_cases)

local lua_test_cases = {
  ["1a2b3c4d"] = { expected = nil, note = "top-level" },
  ["5e6f7g8h"] = { expected = "greet", note = "function declaration" },
  ["1o2p3q4r"] = {
    expected = "greet",
    note = "function declaration - cursor on identifier",
  },
  ["9i0j1k2l"] = { expected = "fetch_data", note = "local function declaration" },
  ["a7cp3312"] = {
    expected = "fetch_data",
    note = "local function declaration - cursor on identifier",
  },
  ["3m4n5o6p"] = { expected = "calculate", note = "function assigned to variable" },
  ["7q8r9s0t"] = {
    expected = "calculate",
    note = "function assigned to variable - cursor on identifier",
  },
  ["5s6t7u8v"] = { expected = "my_func", note = "function assigned to global variable" },
  ["axbpbq73"] = {
    expected = "my_func",
    note = "function assigned to global variable - cursor on identifier",
  },
  ["1u2v3w4x"] = { expected = "processData", note = "nested function" },
  ["5y6z7a8b"] = { expected = "outer", note = "deeply nested function" },
  ["9c0d1e2f"] = { expected = "withLocalNested", note = "nested local function" },
  ["3g4h5i6j"] = { expected = "withTableFilter", note = "anonymous function in table.filter" },
  ["2k3l4m5n"] = { expected = "obj:method", note = "method syntax" },
  ["1h3bfm6m"] = {
    expected = "obj:method",
    note = "method syntax - cursor on identifier",
  },
  ["1s2t3u4v"] = { expected = "outer.inner:method", note = "nested method syntax" },
  ["912v4v4a"] = {
    expected = "outer.inner:method",
    note = "nested method syntax - cursor on identifier",
  },
  ["2sy24v56"] = {
    expected = "field_with_function",
    note = "field with function",
  },
  ["11y24v56"] = {
    expected = "field_with_function",
    note = "field with function - cursor on identifier",
  },
  ["3s4i4l66"] = {
    expected = "nested_field_with_function",
    note = "nested field with function assigned to local variable",
  },
  ["5a6iblz6"] = {
    expected = "deeply_nested_field_with_function",
    note = "deeply nested field with function assigned to local variable",
  },
  ["aaaib8zb"] = {
    expected = "field_with_function",
    note = "field with function in return table",
  },
  ["7aaiblzb"] = {
    expected = "deeply_nested_field_with_function",
    note = "deeply nested field with function in return table",
  },
  ["eq1a2b3c"] = {
    expected = "eq_gap_test",
    note = "function assigned to variable - cursor on `=`",
  },
  ["eqfield1"] = {
    expected = "field",
    note = "table field with function - cursor on `=`",
  },
}

T["e2e_outermost_function"]["lua"] =
  create_language_test_set("lua", "lua.txt", "lua", lua_test_cases)

local java_test_cases = {
  ["3f7a2b1c"] = { expected = nil, note = "top-level" },
  ["8l1o3c5a"] = { expected = "MyClass", note = "constructor declaration" },
  ["4e6g9s2u"] = {
    expected = "MyClass",
    note = "constructor declaration - cursor on identifier",
  },
  ["5k9m1p4x"] = { expected = "greet", note = "method declaration" },
  ["2q8r6t9v"] = {
    expected = "greet",
    note = "method declaration - cursor on identifier",
  },
  ["7w2d4f8h"] = { expected = "staticMethod", note = "static method" },
  ["1n3b5j7c"] = { expected = "genericMethod", note = "generic method" },
  ["6i4p8v2w"] = { expected = "withAnonymousInner", note = "anonymous inner class method" },
  ["9z8y7x6w"] = { expected = "innerMethod", note = "named inner class method" },
  ["5a4b3c2d"] = {
    expected = "innerMethod",
    note = "named inner class method - cursor on identifier",
  },
}

T["e2e_outermost_function"]["java"] =
  create_language_test_set("java", "java.txt", "java", java_test_cases)

local python_test_cases = {
  ["3f7a2b1c"] = { expected = nil, note = "top-level" },
  ["5k9m1p4x"] = { expected = "greet", note = "function definition" },
  ["2q8r6t9v"] = {
    expected = "greet",
    note = "function definition - cursor on identifier",
  },
  ["8l1o3c5a"] = { expected = "asyncFetch", note = "async function" },
  ["1u2v3w4x"] = { expected = "processData", note = "nested function" },
  ["5y6z7a8b"] = { expected = "outer", note = "deeply nested function" },
  ["9i0j1k2l"] = { expected = "method", note = "instance method" },
  ["a7cp3312"] = {
    expected = "method",
    note = "instance method - cursor on identifier",
  },
  ["1n3b5j7c"] = { expected = "asyncMethod", note = "async instance method" },
  ["4e6g9s2u"] = { expected = "classMethod", note = "classmethod with decorator" },
  ["7w2d4f8h"] = { expected = "staticMethod", note = "staticmethod with decorator" },
  ["6i4p8v2w"] = { expected = "methodWithNested", note = "method with nested function definition" },
}

T["e2e_outermost_function"]["python"] =
  create_language_test_set("python", "python.txt", "python", python_test_cases)

return T
