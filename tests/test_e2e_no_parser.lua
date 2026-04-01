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

T["no_parser"] = new_set({})

T["no_parser"]["outer_function returns nil when parser not installed"] = function()
  child.cmd("enew | set filetype=lua")
  child.api.nvim_buf_set_lines(0, 0, -1, false, { "local x = 1" })
  child.lua("vim.treesitter.get_parser = function() error('no parser') end")
  local result = child.lua_get("treescope.outer_function()")
  h.assert_scope(nil, result)
end

T["no_parser"]["namespace returns nil when parser not installed"] = function()
  child.cmd("enew | set filetype=clojure")
  child.api.nvim_buf_set_lines(0, 0, -1, false, { "(ns foo.bar)" })
  child.lua("vim.treesitter.get_parser = function() error('no parser') end")
  local result = child.lua_get("treescope.namespace()")
  h.assert_scope(nil, result)
end

T["no_parser"]["yq_path returns nil when parser not installed"] = function()
  child.cmd("enew | set filetype=yaml")
  child.api.nvim_buf_set_lines(0, 0, -1, false, { "key: value" })
  child.lua("vim.treesitter.get_parser = function() error('no parser') end")
  local result = child.lua_get("treescope.yq_path()")
  h.assert_scope(nil, result)
end

return T
