local M = {}

--- The content of {block}, or nil for an empty fence, which has no content node.
---@param block TSNode
---@return TSNode?
local function get_content(block)
  for child in block:iter_children() do
    if child:type() == "code_fence_content" then
      return child
    end
  end
  return nil
end

--- An empty fence is no scope: the content is the whole point, and without a
--- content node there is no range to hand back.
---@param node TSNode
---@param buf integer
---@return boolean
function M.is_scope_node(node, buf)
  return node:type() == "fenced_code_block" and get_content(node) ~= nil
end

--- The `language` node, nil when the fence carries no info string.
---@param node TSNode Code fence content, per `normalize_node`.
---@param buf integer
---@return TSNode?
function M.get_name_node(node, buf)
  local block = node:parent()
  if not block then
    return nil
  end
  for child in block:iter_children() do
    if child:type() == "info_string" then
      -- Only the first word names the language: in ```python {.numberLines} the
      -- rest belongs to the info string, not to the name.
      for part in child:iter_children() do
        if part:type() == "language" then
          return part
        end
      end
    end
  end
  return nil
end

--- The delimiter lines are syntax, so the scope is the content. Going through
--- the block means a position on a delimiter resolves to the fence too.
---@param node TSNode
---@return TSNode
function M.normalize_node(node)
  return get_content(node) or node
end

---@type NodeScopeProvider
local _ = M

return M
