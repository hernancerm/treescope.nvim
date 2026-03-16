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

T["e2e_yq_path"] = new_set({})

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
    local resource_file = vim.fs.joinpath(h.resources_dir, "yq_path", filename)
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
    local scope = child.lua_get("treescope.yq_path()")
    h.assert_scope(expected, scope)
  end
  return test_set
end

local yaml_object_root_test_cases = {
  ["1a2b3c4d"] = {
    expected = ".",
    note = "root level - object root",
  },
  ["2b3c4d5e"] = {
    expected = ".server",
    note = "top-level key - object root",
  },
  ["3c4d5e6f"] = {
    expected = ".server.port",
    note = "one level nested - object root",
  },
  ["4d5e6f7g"] = {
    expected = ".spring.application.name",
    note = "two levels nested - object root",
  },
  ["5e6f7g8h"] = {
    expected = ".items",
    note = "array parent key - object root",
  },
  ["6f7g8h9i"] = {
    expected = ".items[0]",
    note = "first array item - object root",
  },
  ["7g8h9i0j"] = {
    expected = ".items[1]",
    note = "second array item - object root",
  },
  ["8h9i0j1k"] = {
    expected = ".databases",
    note = "array of objects parent - object root",
  },
  ["9i0j1k2l"] = {
    expected = ".databases[0].name",
    note = "key in first object of array - object root",
  },
  ["0j1k2l3m"] = {
    expected = ".databases[1].host",
    note = "key in second object of array - object root",
  },
  ["1k2l3m4n"] = {
    expected = ".databases[0].config.timeout",
    note = "nested key inside array object - object root",
  },
  ["2l3m4n5o"] = {
    expected = ".spring.application.version",
    note = "cursor on value (not key) - object root",
  },
  ["3m4n5o6p"] = {
    expected = ".api.v1.endpoints.users.get.enabled",
    note = "deeply nested (5 levels) - object root",
  },
  ["4n5o6p7q"] = {
    expected = ".description",
    note = "multiline string (pipe notation) - object root",
  },
  ["5o6p7q8r"] = {
    expected = ".summary",
    note = "multiline string (folded notation) - object root",
  },
  ["6p7q8r9s"] = {
    expected = '.["my key with spaces"]',
    note = "key with spaces (bracket notation) - object root",
  },
  ["7q8r9s0t"] = {
    expected = '.nested["another key with spaces"]',
    note = "nested key with spaces (bracket notation) - object root",
  },
}

T["e2e_yq_path"]["yaml"] =
  create_language_test_set("yaml", "yaml_object_root.txt", "yaml", yaml_object_root_test_cases)

local yaml_array_root_test_cases = {
  ["129v4xsy"] = {
    expected = ".",
    note = "root level - array root",
  },
  ["8s9t0u1v"] = {
    expected = ".[0]",
    note = "first item - array root",
  },
  ["9t0u1v2w"] = {
    expected = ".[1]",
    note = "second item - array root",
  },
  ["0u1v2w3x"] = {
    expected = ".[2]",
    note = "third item - array root",
  },
  ["1v2w3x4y"] = {
    expected = ".[3].name",
    note = "property in first object - array root",
  },
  ["2w3x4y5z"] = {
    expected = ".[3].value",
    note = "another property in first object - array root",
  },
  ["3x4y5z6a"] = {
    expected = ".[4].name",
    note = "property in second object - array root",
  },
  ["4y5z6a7b"] = {
    expected = ".[4].value",
    note = "property in second object - array root",
  },
  ["5z6a7b8c"] = {
    expected = ".[4].nested.deep",
    note = "nested property - array root",
  },
}

T["e2e_yq_path"]["yaml_array_root"] =
  create_language_test_set("yaml", "yaml_array_root.txt", "yaml", yaml_array_root_test_cases)

-- The json provider is being tested through jsonc. The jsonc provider is a pass-through to the json
-- provider. Assumption: the jsonc tests accurately reflect the behavior for json. This decision was
-- taken since json does not support comments which complicates adding the cursor markers.

local jsonc_object_root_test_cases = {
  ["j1a2b3c4d"] = {
    expected = ".",
    note = "root level - object root",
  },
  ["j2b3c4d5e"] = {
    expected = ".server",
    note = "top-level key - object root",
  },
  ["j3c4d5e6f"] = {
    expected = ".server.port",
    note = "one level nested - object root",
  },
  ["j4d5e6f7g"] = {
    expected = ".spring.application.name",
    note = "two levels nested - object root",
  },
  ["j5e6f7g8h"] = {
    expected = ".items",
    note = "array parent key - object root",
  },
  ["j6f7g8h9i"] = {
    expected = ".items[0]",
    note = "first array item - object root",
  },
  ["j7g8h9i0j"] = {
    expected = ".items[1]",
    note = "second array item - object root",
  },
  ["j8h9i0j1k"] = {
    expected = ".databases",
    note = "array of objects parent - object root",
  },
  ["j9i0j1k2l"] = {
    expected = ".databases[0].name",
    note = "key in first object of array - object root",
  },
  ["j0j1k2l3m"] = {
    expected = ".databases[1].host",
    note = "key in second object of array - object root",
  },
  ["j1k2l3m4n"] = {
    expected = ".databases[0].config.timeout",
    note = "nested key inside array object - object root",
  },
  ["j2l3m4n5o"] = {
    expected = ".spring.application.version",
    note = "cursor on value (not key) - object root",
  },
  ["j3m4n5o6p"] = {
    expected = ".api.v1.endpoints.users.get.enabled",
    note = "deeply nested (5 levels) - object root",
  },
  ["j6p7q8r9s"] = {
    expected = '.["my key with spaces"]',
    note = "key with spaces (bracket notation) - object root",
  },
  ["j7q8r9s0t"] = {
    expected = '.nested["another key with spaces"]',
    note = "nested key with spaces (bracket notation) - object root",
  },
}

T["e2e_yq_path"]["json"] =
  create_language_test_set("jsonc", "jsonc_object_root.txt", "jsonc", jsonc_object_root_test_cases)

local jsonc_array_root_test_cases = {
  ["j129v4xsy"] = {
    expected = ".",
    note = "root level - array root",
  },
  ["j8s9t0u1v"] = {
    expected = ".[0]",
    note = "first item - array root",
  },
  ["j9t0u1v2w"] = {
    expected = ".[1]",
    note = "second item - array root",
  },
  ["j0u1v2w3x"] = {
    expected = ".[2]",
    note = "third item - array root",
  },
  ["j1v2w3x4y"] = {
    expected = ".[3].name",
    note = "property in first object - array root",
  },
  ["j2w3x4y5z"] = {
    expected = ".[3].value",
    note = "another property in first object - array root",
  },
  ["j3x4y5z6a"] = {
    expected = ".[4].name",
    note = "property in second object - array root",
  },
  ["j4y5z6a7b"] = {
    expected = ".[4].value",
    note = "property in second object - array root",
  },
  ["j5z6a7b8c"] = {
    expected = ".[4].nested.deep",
    note = "nested property - array root",
  },
}

T["e2e_yq_path"]["json_array_root"] =
  create_language_test_set("jsonc", "jsonc_array_root.txt", "jsonc", jsonc_array_root_test_cases)

return T
