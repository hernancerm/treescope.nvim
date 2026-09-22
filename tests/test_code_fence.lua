local h = dofile("tests/helpers.lua")
local mini_test = require("mini.test")

local child = mini_test.new_child_neovim()
local new_set = mini_test.new_set
local eq = mini_test.expect.equality

local function restart()
  child.restart({ "-u", "scripts/minimal_init.lua" })
  child.lua([[treescope = require("treescope")]])
  child.lua("treescope.setup()")
end

local T = new_set({
  hooks = {
    pre_case = restart,
    post_once = function()
      child.stop()
    end,
  },
})

local function open()
  if h.ensure_parser_available("markdown", child) then
    restart()
  end
  local resource_file = vim.fs.joinpath(h.resources_dir, "code_fence", "markdown.txt")
  child.cmd(string.format("edit %s | set filetype=markdown", resource_file))
end

T["e2e_code_fence"] = new_set({})

-- Helper for post_case hook.
local function create_post_case(test_cases)
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

local test_cases = {
  ["1a2b3c4d"] = {
    expected = nil,
    note = "outside any fence",
  },
  ["2b3c4d5e"] = {
    expected = "python",
    note = "inside a fence",
  },
  ["3c4d5e6f"] = {
    expected = "python",
    note = "on the opening fence delimiter",
  },
  ["4d5e6f7g"] = {
    expected = "python",
    note = "on the closing fence delimiter",
  },
  ["5e6f7g8h"] = {
    expected = "lua",
    note = "inside a fence of another language",
  },
  ["6f7g8h9i"] = {
    expected = "python",
    note = "info string carrying more than the language",
  },
  ["7g8h9i0j"] = {
    expected = nil,
    note = "fence without an info string is anonymous",
  },
  ["8h9i0j1k"] = {
    expected = nil,
    note = "empty fence is no scope",
  },
}

T["e2e_code_fence"]["markdown"] = new_set({
  parametrize = h.map_test_cases_to_parameterize_data(test_cases),
  hooks = {
    pre_case = open,
    post_case = create_post_case(test_cases),
  },
})

T["e2e_code_fence"]["markdown"]["parametrized"] = function(marker, expected)
  h.set_cursor_from_marker(marker, child)
  local text = child.lua_get('treescope.get("code_fence").text')
  h.assert_scope(expected, text)
end

-- `node` is the fence content, not the whole block. This is the one place where
-- a scope's `node` is the inside of the thing, so it is worth pinning down.
T["node"] = new_set({ hooks = { pre_case = open } })

local function scope_at(marker)
  h.set_cursor_from_marker(marker, child)
  return child.lua_func(function()
    local scope = treescope.get("code_fence")
    return {
      node_type = scope.node and scope.node:type() or vim.NIL,
      node_text = scope.node and vim.treesitter.get_node_text(scope.node, 0) or vim.NIL,
      name_node_type = scope.name_node and scope.name_node:type() or vim.NIL,
    }
  end)
end

T["node"]["is the fence content"] = function()
  local scope = scope_at("2b3c4d5e")
  eq(scope.node_type, "code_fence_content")
  eq(
    scope.node_text,
    "# cursor-2b3c4d5e\n# cursor-3c4d5e6f[kk]\nx = 1\n# cursor-4d5e6f7g[jj]\ny = 2\n"
  )
end

T["node"]["is the same content from a delimiter line"] = function()
  eq(scope_at("3c4d5e6f").node_text, scope_at("2b3c4d5e").node_text)
end

T["node"]["name_node is the language"] = function()
  eq(scope_at("2b3c4d5e").name_node_type, "language")
end

T["node"]["an anonymous fence still has content"] = function()
  local scope = scope_at("7g8h9i0j")
  eq(scope.node_type, "code_fence_content")
  eq(scope.node_text, "cursor-7g8h9i0j\n")
  eq(scope.name_node_type, vim.NIL)
end

T["node"]["an empty fence has no scope at all"] = function()
  eq(scope_at("8h9i0j1k").node_type, vim.NIL)
end

-- Navigation comes from `list`, so exercise it end to end.
T["navigation"] = new_set({ hooks = { pre_case = open } })

local function texts()
  return child.lua_get(
    'vim.tbl_map(function(s) return s.text or "(anonymous)" end, treescope.list("code_fence"))'
  )
end

T["navigation"]["list gives every fence with content, empty ones excluded"] = function()
  eq(texts(), { "python", "lua", "python", "(anonymous)" })
end

T["navigation"]["goto_next stops at each fence"] = function()
  child.api.nvim_win_set_cursor(0, { 1, 0 })
  local rows = {}
  for _ = 1, 5 do
    child.lua('treescope.goto_next("code_fence")')
    table.insert(rows, child.api.nvim_win_get_cursor(0)[1])
  end
  -- Landing is on the language, hence the opening delimiter line. The anonymous
  -- fence has none, so it lands on its content instead, a line lower.
  eq(rows, { 3, 11, 16, 22, 22 })
end

T["navigation"]["goto_prev walks back"] = function()
  child.api.nvim_win_set_cursor(0, { 30, 0 })
  local rows = {}
  for _ = 1, 4 do
    child.lua('treescope.goto_prev("code_fence")')
    table.insert(rows, child.api.nvim_win_get_cursor(0)[1])
  end
  eq(rows, { 22, 16, 11, 3 })
end

T["is_supported"] = new_set({ hooks = { pre_case = open } })

T["is_supported"]["true for markdown"] = function()
  eq(child.lua_get('treescope.is_supported("code_fence")'), true)
end

T["is_supported"]["false for another filetype"] = function()
  child.cmd("set filetype=lua")
  eq(child.lua_get('treescope.is_supported("code_fence")'), false)
end

return T
