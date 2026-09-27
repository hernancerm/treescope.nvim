local h = dofile("tests/helpers.lua")
local mini_test = require("mini.test")

local child = mini_test.new_child_neovim()
local new_set = mini_test.new_set
local eq = mini_test.expect.equality

local function restart()
  child.restart({ "-u", "scripts/minimal_init.lua" })
end

local T = new_set({
  hooks = {
    pre_case = function()
      restart()
      if h.ensure_parser_available("lua", child) then
        restart()
      end
    end,
    post_once = function()
      child.stop()
    end,
  },
})

--- Run `:checkhealth treescope` and return the report as one string.
---@return string
local function checkhealth()
  child.cmd("checkhealth treescope")
  return table.concat(child.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
end

---@param report string
---@param text string
local function has(report, text)
  eq(report:find(text, 1, true) ~= nil, true)
end

T["reports an installed parser as ok"] = function()
  has(checkhealth(), "OK lua: parser found. Used by: function (lua)")
end

T["warns about a missing parser"] = function()
  child.lua([[
    local add = vim.treesitter.language.add
    vim.treesitter.language.add = function(lang)
      if lang == "tsx" then
        return nil, "not found"
      end
      return add(lang)
    end
  ]])
  local report = checkhealth()
  has(report, "WARNING tsx: parser not found. Used by: function (typescriptreact)")
  has(report, ":TSInstall tsx")
end

T["errors when the queries fail to load"] = function()
  child.lua([[
    local get = vim.treesitter.query.get
    vim.treesitter.query.get = function(lang, name)
      if lang == "lua" then
        error("invalid node type")
      end
      return get(lang, name)
    end
  ]])
  local report = checkhealth()
  has(report, "ERROR lua: query failed to load:")
  has(report, ":TSUpdate lua")
end

return T
