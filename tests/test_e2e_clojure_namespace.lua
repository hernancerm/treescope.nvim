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

T["e2e_clojure_namespace"] = new_set({})

local test_cases = {
}

T["e2e_clojure_namespace"]["returns correct clojure namespace"] = new_set({})
