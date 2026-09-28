local h = dofile("tests/helpers.lua")
local mini_test = require("mini.test")

local child = mini_test.new_child_neovim()
local new_set = mini_test.new_set

local T = new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua([[treescope = require("treescope")]])
    end,
    post_once = function()
      child.stop()
    end,
  },
})

T["no_parser"] = new_set({})

T["no_parser"]["function returns nil text when parser not installed"] = function()
  child.cmd("enew | set filetype=lua")
  child.api.nvim_buf_set_lines(0, 0, -1, false, { "local x = 1" })
  child.lua("vim.treesitter.get_parser = function() error('no parser') end")
  local text = child.lua_get('treescope.get("function").text')
  h.assert_scope(nil, text)
end

T["no_parser"]["namespace returns nil text when parser not installed"] = function()
  child.cmd("enew | set filetype=clojure")
  child.api.nvim_buf_set_lines(0, 0, -1, false, { "(ns foo.bar)" })
  child.lua("vim.treesitter.get_parser = function() error('no parser') end")
  local text = child.lua_get('treescope.get("namespace").text')
  h.assert_scope(nil, text)
end

T["no_parser"]["yq_path returns nil text when parser not installed"] = function()
  child.cmd("enew | set filetype=yaml")
  child.api.nvim_buf_set_lines(0, 0, -1, false, { "key: value" })
  child.lua("vim.treesitter.get_parser = function() error('no parser') end")
  local text = child.lua_get('treescope.get("yq_path").text')
  h.assert_scope(nil, text)
end

return T
