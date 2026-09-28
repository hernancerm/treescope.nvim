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
    pre_case = function()
      restart()
      if h.ensure_parser_available("lua", child) then
        restart()
      end
      local resource_file = vim.fs.joinpath(h.resources_dir, "function", "lua.txt")
      child.cmd(string.format("edit %s | set filetype=lua", resource_file))
    end,
    post_once = function()
      child.stop()
    end,
  },
})

T["returns the scope text"] = function()
  h.set_cursor_from_marker("5y6z7a8b", child)
  eq(child.lua_get([[treescope.get_text("function")]]), "outer")
end

T["passes opts to get()"] = function()
  h.set_cursor_from_marker("5y6z7a8b", child)
  eq(child.lua_get([[treescope.get_text("function", { depth = "any" })]]), "deepest")
end

T["returns empty string when there is no scope"] = function()
  h.set_cursor_from_marker("1a2b3c4d", child)
  eq(child.lua_get([[treescope.get_text("function")]]), "")
end

T["works in the statusline"] = function()
  h.set_cursor_from_marker("5y6z7a8b", child)
  local stl = "%{v:lua.Treescope.get_text('function')}"
  eq(child.api.nvim_eval_statusline(stl, {}).str, "outer")
  h.set_cursor_from_marker("1a2b3c4d", child)
  eq(child.api.nvim_eval_statusline(stl, {}).str, "")
end

return T
