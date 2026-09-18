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

T["e2e_class"] = new_set({})

local function create_language_pre_case(lang, filename, filetype)
  return function()
    local parser_was_installed = h.ensure_parser_available(lang, child)
    if parser_was_installed then
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua([[treescope = require("treescope")]])
      child.lua("treescope.setup()")
    end
    local resource_file = vim.fs.joinpath(h.resources_dir, "class", filename)
    child.cmd(string.format("edit %s | set filetype=%s", resource_file, filetype))
  end
end

local function create_language_post_case(test_cases)
  return function()
    local case = mini_test.current.case
    if #case.exec.fails > 0 then
      local marker = case.args[1]
      if test_cases[marker] then
        mini_test.add_note("Case: " .. test_cases[marker].note)
      end
    end
  end
end

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
    local text = child.lua_get('treescope.get("class").text')
    h.assert_scope(expected, text)
  end
  return test_set
end

local java_test_cases = {
  ["3f7a2b1c"] = { expected = nil, note = "above all classes" },
  ["5k9m1p4x"] = { expected = "SimpleClass", note = "inside class body" },
  ["8l1o3c5a"] = { expected = "SimpleClass", note = "inside method body" },
  ["2q8r6t9v"] = { expected = "OuterClass", note = "inside nested class body — outermost wins" },
  ["7w2d4f8h"] = { expected = "OuterClass", note = "inside nested class method — outermost wins" },
  ["4e6g9s2u"] = {
    expected = "OuterClass",
    note = "inside anonymous class — outermost named class wins",
  },
}

T["e2e_class"]["java"] = create_language_test_set("java", "java.txt", "java", java_test_cases)

local python_test_cases = {
  ["3f7a2b1c"] = { expected = nil, note = "above all classes" },
  ["5k9m1p4x"] = { expected = "SimpleClass", note = "inside class body" },
  ["8l1o3c5a"] = { expected = "SimpleClass", note = "inside method body" },
  ["2q8r6t9v"] = { expected = "OuterClass", note = "inside nested class body — outermost wins" },
  ["7w2d4f8h"] = { expected = "OuterClass", note = "inside nested class method — outermost wins" },
  ["1n3b5j7c"] = { expected = nil, note = "on decorator — outside class_definition" },
  ["6i4p8v2w"] = { expected = "Decorated", note = "inside decorated class body" },
}

T["e2e_class"]["python"] =
  create_language_test_set("python", "python.txt", "python", python_test_cases)

local javascript_test_cases = {
  ["3f7a2b1c"] = { expected = nil, note = "top-level" },
  ["5k9m1p4x"] = { expected = "Simple", note = "inside class body" },
  ["8l1o3c5a"] = { expected = "Simple", note = "inside method body" },
  ["2q8r6t9v"] = {
    expected = "Outer",
    note = "inside class expression method — class_declaration outermost wins",
  },
  ["7w2d4f8h"] = { expected = "Derived", note = "class with extends" },
  ["4e6g9s2u"] = { expected = "Named", note = "export default class" },
  ["1n3b5j7c"] = { expected = nil, note = "inside anonymous class expression" },
}

T["e2e_class"]["javascript"] =
  create_language_test_set("javascript", "javascript.txt", "javascript", javascript_test_cases)

T["e2e_class"]["typescript"] =
  create_language_test_set("typescript", "typescript.txt", "typescript", javascript_test_cases)

return T
