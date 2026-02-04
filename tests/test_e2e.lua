---@diagnostic disable: undefined-field, undefined-global

local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality
local child = MiniTest.new_child_neovim()

local T = new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua([[treescope = require("treescope")]])
      child.lua([[treescope.setup()]])
    end,
    post_once = function()
      child.stop()
    end,
  },
})

T["e2e"] = new_set({})

T["e2e"]["active buf using bareline.config.statusline"] = function()
  eq(3, 1 + 2)
end

return T
