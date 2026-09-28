local h = dofile("tests/helpers.lua")
local mini_test = require("mini.test")

local child = mini_test.new_child_neovim()
local new_set = mini_test.new_set
local eq = mini_test.expect.equality

local function restart()
  child.restart({ "-u", "scripts/minimal_init.lua" })
  child.lua([[treescope = require("treescope")]])
end

local T = new_set({
  hooks = {
    pre_case = restart,
    post_once = function()
      child.stop()
    end,
  },
})

local function open(lang, subdir, filename)
  if h.ensure_parser_available(lang, child) then
    restart()
  end
  local resource_file = vim.fs.joinpath(h.resources_dir, subdir, filename)
  child.cmd(string.format("edit %s | set filetype=%s", resource_file, lang))
end

local function texts(scope_id, opts)
  return child.lua_get(
    "vim.tbl_map(function(s) return s.text end, treescope.list(...))",
    { scope_id, opts or {} }
  )
end

local function cursor()
  return child.api.nvim_win_get_cursor(0)
end

T["list"] = new_set({
  hooks = {
    pre_case = function()
      open("lua", "function", "lua.txt")
    end,
  },
})

T["list"]["outermost skips nested functions"] = function()
  eq(texts("function"), {
    "greet",
    "fetch_data",
    "calculate",
    "my_func",
    "processData",
    "outer",
    "withLocalNested",
    "withTableFilter",
    "obj:method",
    "outer.inner:method",
    "field_with_function",
    "nested_field_with_function",
    "deeply_nested_field_with_function",
    'T["1 equals 1"]',
    'S["base"]["2 equals 2"]',
    "hooks.write_pre",
    "eq_gap_test",
    "field",
    "field_with_function",
    "nested_field_with_function",
    "deeply_nested_field_with_function",
  })
end

T["list"]["any includes nested functions"] = function()
  local all = texts("function", { depth = "any" })
  eq(#all, 31)
  eq(vim.list_slice(all, 5, 10), {
    "processData",
    "inner",
    "outer",
    "middle",
    "deepest",
    "withLocalNested",
  })
end

T["list"]["returns empty for unsupported filetype"] = function()
  child.cmd("set filetype=text")
  eq(texts("function"), {})
end

T["get"] = new_set({})

T["get"]["depth any returns nearest function"] = function()
  open("lua", "function", "lua.txt")
  h.set_cursor_from_marker("5y6z7a8b", child)
  eq(child.lua_get([[treescope.get("function").text]]), "outer")
  eq(child.lua_get([[treescope.get("function", { depth = "any" }).text]]), "deepest")
end

T["get"]["depth any returns nearest class"] = function()
  open("java", "class", "java.txt")
  h.set_cursor_from_marker("7w2d4f8h", child)
  eq(child.lua_get([[treescope.get("class").text]]), "OuterClass")
  eq(child.lua_get([[treescope.get("class", { depth = "any" }).text]]), "InnerClass")
end

T["get"]["accepts explicit buf and pos"] = function()
  open("lua", "function", "lua.txt")
  local buf = child.api.nvim_get_current_buf()
  child.cmd("enew")
  eq(child.lua_get([[treescope.get("function").text]]), vim.NIL)
  eq(
    child.lua_get([[treescope.get("function", { buf = ..., pos = { 37, 0 } }).text]], { buf }),
    "outer"
  )
end

T["get"]["rejects unknown scope id"] = function()
  mini_test.expect.error(function()
    child.lua([[treescope.get("nope")]])
  end, "scope_id")
end

T["goto"] = new_set({
  hooks = {
    pre_case = function()
      open("lua", "function", "lua.txt")
    end,
  },
})

T["goto"]["next lands on the name"] = function()
  child.api.nvim_win_set_cursor(0, { 1, 0 })
  child.lua([[treescope.goto_next("function")]])
  eq(cursor(), { 3, 9 })
end

T["goto"]["next honors count"] = function()
  child.api.nvim_win_set_cursor(0, { 1, 0 })
  child.lua([[treescope.goto_next("function", { count = 2 })]])
  eq(cursor(), { 9, 15 })
end

T["goto"]["outermost skips nested, any stops at them"] = function()
  h.set_cursor_from_marker("1u2v3w4x", child)
  child.lua([[treescope.goto_prev("function")]])
  eq(cursor(), { 26, 9 })
  h.set_cursor_from_marker("1u2v3w4x", child)
  child.lua([[treescope.goto_next("function")]])
  eq(cursor(), { 34, 9 })
  h.set_cursor_from_marker("1u2v3w4x", child)
  child.lua([[treescope.goto_prev("function", { depth = "any" })]])
  eq(cursor(), { 27, 11 })
  h.set_cursor_from_marker("1u2v3w4x", child)
  child.lua([[treescope.goto_next("function", { depth = "any" })]])
  eq(cursor(), { 34, 9 })
  child.lua([[treescope.goto_next("function", { depth = "any" })]])
  eq(cursor(), { 35, 11 })
end

T["goto"]["no-op at the edges"] = function()
  child.api.nvim_win_set_cursor(0, { 1, 0 })
  child.lua([[treescope.goto_prev("function")]])
  eq(cursor(), { 1, 0 })
  h.set_cursor_from_marker("7aaiblzb", child)
  local before = cursor()
  child.lua([[treescope.goto_next("function")]])
  eq(cursor(), before)
end

T["goto"]["set_jump pushes a jumplist entry"] = function()
  child.api.nvim_win_set_cursor(0, { 1, 0 })
  child.lua([[treescope.goto_next("function", { set_jump = true })]])
  eq(cursor(), { 3, 9 })
  child.type_keys("<C-o>")
  eq(cursor(), { 1, 0 })
end

T["goto"]["warns on scope without navigation"] = function()
  child.lua([[
    notified = nil
    vim.notify = function(msg, level) notified = { msg = msg, level = level } end
  ]])
  child.api.nvim_win_set_cursor(0, { 1, 0 })
  child.lua([[treescope.goto_next("namespace")]])
  eq(cursor(), { 1, 0 })
  eq(child.lua_get("notified.level"), vim.log.levels.WARN)
  eq(child.lua_get("notified.msg"), "treescope: scope 'namespace' does not support navigation")
end

T["set_loclist"] = new_set({})

T["set_loclist"]["lists classes"] = function()
  open("java", "class", "java.txt")
  child.lua([[treescope.set_loclist("class", { depth = "any" })]])
  local items = child.fn.getloclist(0)
  eq(
    vim.tbl_map(function(i)
      return { i.text, i.lnum, i.col }
    end, items),
    { { "SimpleClass", 2, 7 }, { "OuterClass", 11, 7 }, { "InnerClass", 13, 9 } }
  )
  eq(child.fn.getloclist(0, { title = 0 }).title, "[Treescope] class")
end

T["is_supported"] = new_set({})

T["is_supported"]["true for a supported filetype"] = function()
  open("lua", "function", "lua.txt")
  eq(child.lua_get([[treescope.is_supported("function")]]), true)
  eq(child.lua_get([[treescope.is_supported("class")]]), false)
end

T["is_supported"]["false for an unsupported filetype"] = function()
  child.cmd("enew | set filetype=text")
  eq(child.lua_get([[treescope.is_supported("function")]]), false)
end

T["is_supported"]["accepts buf"] = function()
  open("lua", "function", "lua.txt")
  local buf = child.api.nvim_get_current_buf()
  child.cmd("enew | set filetype=text")
  eq(child.lua_get([[treescope.is_supported("function", { buf = ... })]], { buf }), true)
end

T["vitest"] = new_set({
  hooks = {
    pre_case = function()
      open("javascript", "function", "javascript.txt")
    end,
  },
})

T["vitest"]["get with depth any returns the test title"] = function()
  h.set_cursor_from_marker("vt4d5e6f", child)
  eq(child.lua_get([[treescope.get("function", { depth = "any" }).text]]), "adds an item")
  h.set_cursor_from_marker("vt7g8h9i", child)
  eq(child.lua_get([[treescope.get("function", { depth = "any" }).text]]), "pays")
  h.set_cursor_from_marker("vt3c4d5e", child)
  eq(child.lua_get([[treescope.get("function", { depth = "any" }).text]]), "adds an item")
end

T["vitest"]["list includes suites and tests"] = function()
  local all = texts("function", { depth = "any" })
  eq(vim.list_slice(all, #all - 4, #all), {
    "cart",
    "adds an item",
    "helper",
    "checkout",
    "pays",
  })
  local outermost = texts("function")
  eq(outermost[#outermost], "cart")
end

T["vitest"]["goto lands on the title"] = function()
  h.set_cursor_from_marker("vt2b3c4d", child)
  child.lua([[treescope.goto_next("function", { depth = "any" })]])
  local row, col = unpack(cursor())
  eq(child.api.nvim_buf_get_lines(0, row - 1, row, false)[1]:sub(col + 1, col + 12), "adds an item")
end

return T
