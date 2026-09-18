local const = require("treescope.const")

local M = {}

---@class treescope.BufVar
---@field scope_id const.ScopeIds
---@field depth const.Depth

--- Parse a `config.buf_vars` entry: a scope id string, or a table
--- `{ scope_id, depth = ... }`. Returns nil on an invalid scope id.
---@param entry string|table
---@return treescope.BufVar?
function M.parse_buf_var(entry)
  local scope_name, depth
  if type(entry) == "table" then
    scope_name, depth = entry[1], entry.depth
  else
    scope_name = entry
  end
  if type(scope_name) ~= "string" then
    return nil
  end
  local scope_id = const.ScopeIds[vim.fn.toupper(scope_name)]
  if not scope_id then
    return nil
  end
  return { scope_id = scope_id, depth = depth or const.Depth.OUTERMOST }
end

--- Buf var name. The depth is a suffix only when it is not the default, so
--- `{ "function", depth = "any" }` can coexist with `"function"`.
---@param buf_var treescope.BufVar
---@return string
function M.get_buf_var_name(buf_var)
  local name = "treescope_" .. buf_var.scope_id
  if buf_var.depth ~= const.Depth.OUTERMOST then
    name = name .. "_" .. buf_var.depth
  end
  return name
end

---@param buf_var treescope.BufVar
---@param treescope table
function M.register_buf_var(buf_var, treescope)
  assert(buf_var, "buf_var is required")
  assert(treescope, "treescope is required")
  local name = M.get_buf_var_name(buf_var)
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = "Treescope",
    callback = function()
      local text = treescope.get(buf_var.scope_id, { depth = buf_var.depth }).text
      vim.api.nvim_buf_set_var(0, name, text or "")
    end,
  })
end

---@return string[]
function M.get_valid_scope_ids()
  return vim.tbl_values(const.ScopeIds)
end

return M
