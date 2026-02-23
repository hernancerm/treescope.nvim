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

T["e2e_yaml_path"] = new_set({})

-- Helper for pre_case hook.
local function create_language_pre_case(test_cases)
  return function()
    -- Ensure parser is available.
    local parser_was_installed = h.ensure_parser_available("yaml", child)
    -- If parser was just installed, restart child to reload it.
    if parser_was_installed then
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua([[treescope = require("treescope")]])
      child.lua("treescope.setup()")
    end
    -- Open test file and set filetype explicitly.
    local marker = mini_test.current.case.args[1]
    local case_data = test_cases[marker]
    local resource_file = vim.fs.joinpath(h.resources_dir, "yaml", case_data.filename)
    child.cmd(string.format("edit %s | set filetype=yaml", resource_file))
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

local yaml_test_cases = {
  ["1a2b3c4d"] = {
    expected = nil,
    note = "root level",
    filename = "basic.txt",
  },
  ["2b3c4d5e"] = {
    expected = "server",
    note = "top-level key",
    filename = "basic.txt",
  },
  ["3c4d5e6f"] = {
    expected = "server.port",
    note = "one level nested",
    filename = "basic.txt",
  },
  ["4d5e6f7g"] = {
    expected = "spring.application.name",
    note = "two levels nested",
    filename = "basic.txt",
  },
  ["5e6f7g8h"] = {
    expected = "items",
    note = "list parent key",
    filename = "basic.txt",
  },
  ["6f7g8h9i"] = {
    expected = "items[0]",
    note = "first list item",
    filename = "basic.txt",
  },
  ["7g8h9i0j"] = {
    expected = "items[1]",
    note = "second list item",
    filename = "basic.txt",
  },
  ["8h9i0j1k"] = {
    expected = "databases",
    note = "list of objects parent",
    filename = "basic.txt",
  },
  ["9i0j1k2l"] = {
    expected = "databases[0].name",
    note = "key in first object of list",
    filename = "basic.txt",
  },
  ["0j1k2l3m"] = {
    expected = "databases[1].host",
    note = "key in second object of list",
    filename = "basic.txt",
  },
  ["1k2l3m4n"] = {
    expected = "databases[0].config.timeout",
    note = "nested key inside list object",
    filename = "basic.txt",
  },
  ["2l3m4n5o"] = {
    expected = "spring.application.version",
    note = "cursor on value (not key)",
    filename = "basic.txt",
  },
  ["3m4n5o6p"] = {
    expected = "api.v1.endpoints.users.get.enabled",
    note = "deeply nested (5 levels)",
    filename = "basic.txt",
  },
  ["4n5o6p7q"] = {
    expected = "description",
    note = "multiline string (pipe notation)",
    filename = "basic.txt",
  },
  ["5o6p7q8r"] = {
    expected = "summary",
    note = "multiline string (folded notation)",
    filename = "basic.txt",
  },
}

T["e2e_yaml_path"]["yaml"] = new_set({
  parametrize = h.map_test_cases_to_parameterize_data(yaml_test_cases),
  hooks = {
    pre_case = create_language_pre_case(yaml_test_cases),
    post_case = create_language_post_case(yaml_test_cases),
  },
})

T["e2e_yaml_path"]["yaml"]["parametrized"] = function(marker, expected)
  h.set_cursor_from_marker(marker, child)
  local yaml_path = child.lua_get("treescope.yaml_path()")
  h.assert_scope(expected, yaml_path)
end

return T
