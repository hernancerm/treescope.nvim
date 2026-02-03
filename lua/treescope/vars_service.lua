local const = require("treescope.const")

local M = {}

local valid_buf_var_names = nil

---@param scope_id const.scope_ids
---@param treescope table
local function create_buf_var_autocmd(scope_id, treescope)
  assert(scope_id)
  assert(treescope)
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = const.AUGROUP_NAME,
    callback = function()
      vim.api.nvim_buf_set_var(
        0,
        "treescope_" .. scope_id,
        treescope[scope_id]() or ""
      )
    end,
  })
end

---@param scope_name string
---@return const.scope_ids?
function M.get_scope_id(scope_name)
  assert(scope_name)
  return const.scope_ids[scope_name]
end

---@param scope_id const.scope_ids
---@param treescope table
function M.register_buf_var(scope_id, treescope)
  assert(scope_id)
  assert(treescope)
  create_buf_var_autocmd(scope_id, treescope)
end

---@return string[]
function M.get_valid_buf_var_names()
  if valid_buf_var_names ~= nil then
    return valid_buf_var_names
  end
  local result = {}
  for _, scope_id in pairs(const.scope_ids) do
    table.insert(result, scope_id)
  end
  valid_buf_var_names = result
  return result
end

return M
