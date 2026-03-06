local M = {}

-- Extract the key text from a JSON pair node's key field.
-- The key is always a string node; strip the surrounding double quotes.
local function extract_key_text(pair_node, bufnr)
  local key_fields = pair_node:field("key")
  if not key_fields or not key_fields[1] then
    return nil
  end
  local text = vim.treesitter.get_node_text(key_fields[1], bufnr)
  if not text then
    return nil
  end
  -- Strip surrounding double quotes.
  text = text:gsub('^"(.*)"$', "%1")
  return text
end

-- Check if key needs bracket notation for yq (contains spaces or special chars).
local function needs_quoting(key)
  if not key then
    return false
  end
  return key:match("%s") ~= nil
end

-- Format a key for yq path (use bracket notation if needed).
local function format_key(key)
  if needs_quoting(key) then
    return '["' .. key .. '"]'
  end
  return key
end

-- Get the 0-based index of a node among its siblings inside a JSON array.
-- Skips comment nodes (JSONC).
local function get_array_item_index(node)
  local parent = node:parent()
  if not parent or parent:type() ~= "array" then
    return 0
  end

  local index = 0
  for i = 0, parent:named_child_count() - 1 do
    local sibling = parent:named_child(i)
    if sibling:type() ~= "comment" then
      if sibling:id() == node:id() then
        return index
      end
      index = index + 1
    end
  end

  return 0
end

---@param node TSNode
---@param bufnr number
---@return string?
function M.get_path(node, bufnr)
  -- Walk up the tree collecting path segments.
  local segments = {}
  ---@type TSNode?
  local current = node
  local pending_index = nil

  while current do
    local node_type = current:type()

    if node_type == "pair" then
      local key_text = extract_key_text(current, bufnr)
      if key_text then
        local formatted_key = format_key(key_text)
        if pending_index ~= nil then
          -- Attach pending array index to this key.
          table.insert(segments, 1, formatted_key .. "[" .. pending_index .. "]")
          pending_index = nil
        else
          table.insert(segments, 1, formatted_key)
        end
      end
    elseif
      node_type ~= "comment"
      and current:parent()
      and current:parent():type() == "array"
    then
      -- This node is a direct child of an array; record its index.
      pending_index = get_array_item_index(current)
    elseif node_type == "document" then
      break
    end

    current = current:parent()
  end

  -- Return "." for root (no path segments collected).
  if #segments == 0 then
    if pending_index ~= nil then
      return ".[" .. pending_index .. "]"
    end
    return "."
  end

  -- Build yq filter path.
  local path = pending_index ~= nil and ".[" .. pending_index .. "]" or "."

  for i, segment in ipairs(segments) do
    if segment:match('^%[".*"%]') then
      -- Bracket notation key (with or without array index): append directly.
      path = path .. segment
    else
      -- Plain key: prefix with "." except when already preceded by .[index].
      if i > 1 or pending_index ~= nil then
        path = path .. "."
      end
      path = path .. segment
    end
  end

  return path
end

return M
