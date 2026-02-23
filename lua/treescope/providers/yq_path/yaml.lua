local M = {}

-- Extract text from a scalar node.
-- Handles nested flow_node -> plain_scalar -> string_scalar.
local function extract_scalar_text(node, bufnr)
  if not node then
    return nil
  end

  -- Handle flow_node wrapper.
  if node:type() == "flow_node" then
    if node:named_child_count() > 0 then
      node = node:named_child(0)
    end
  end

  -- Handle plain_scalar wrapper.
  if node:type() == "plain_scalar" then
    if node:named_child_count() > 0 then
      node = node:named_child(0)
    end
  end

  -- Extract text from the actual scalar node.
  local text = vim.treesitter.get_node_text(node, bufnr)

  -- Remove surrounding quotes if present (YAML quoted strings).
  if text then
    text = text:gsub('^"(.*)"$', "%1")
    text = text:gsub("^'(.*)'$", "%1")
  end

  return text
end

-- Check if a key needs to be quoted for yq (contains spaces or special chars).
local function needs_quoting(key)
  if not key then
    return false
  end
  -- Quote if key contains spaces.
  return key:match("%s") ~= nil
end

-- Format a key for yq path (use bracket notation if needed).
local function format_key(key)
  if needs_quoting(key) then
    return '["' .. key .. '"]'
  end
  return key
end

-- Get the 0-based index of a block_sequence_item among its siblings.
local function get_sequence_item_index(sequence_item_node)
  local parent = sequence_item_node:parent()
  if not parent or parent:type() ~= "block_sequence" then
    return 0
  end

  local index = 0
  for i = 0, parent:named_child_count() - 1 do
    local sibling = parent:named_child(i)
    if sibling:type() == "block_sequence_item" then
      if sibling:id() == sequence_item_node:id() then
        return index
      end
      index = index + 1
    end
  end

  return 0
end

---@param bufnr number
---@return string?
function M.get_path(bufnr)
  -- Get cursor position.
  local win = vim.api.nvim_get_current_win()
  local row, col = unpack(vim.api.nvim_win_get_cursor(win))
  row = row - 1 -- Convert to 0-indexed.

  -- Get Tree-sitter parser and tree.
  local parser = vim.treesitter.get_parser(bufnr, "yaml")
  if not parser then
    return nil
  end

  local trees = parser:parse()
  if not trees or #trees == 0 then
    return nil
  end

  local tree = trees[1]
  local root = tree:root()
  if not root then
    return nil
  end

  -- Get node at cursor position.
  local node = root:named_descendant_for_range(row, col, row, col)
  if not node then
    return nil
  end

  -- Walk up the tree collecting path segments.
  local segments = {}
  local current = node
  local pending_index = nil

  while current do
    local node_type = current:type()

    if node_type == "block_mapping_pair" then
      -- Extract key name.
      local key_fields = current:field("key")
      if key_fields and key_fields[1] then
        local key_text = extract_scalar_text(key_fields[1], bufnr)
        if key_text then
          local formatted_key = format_key(key_text)
          if pending_index ~= nil then
            -- Apply pending index to this key.
            table.insert(
              segments,
              1,
              formatted_key .. "[" .. pending_index .. "]"
            )
            pending_index = nil
          else
            table.insert(segments, 1, formatted_key)
          end
        end
      end
    elseif node_type == "block_sequence_item" then
      -- Calculate and store the index to apply to the next key we encounter.
      pending_index = get_sequence_item_index(current)
    elseif node_type == "document" or node_type == "stream" then
      -- Reached top level, stop walking.
      break
    end

    current = current:parent()
  end

  -- Return "." for root (when no path segments collected).
  if #segments == 0 then
    return "."
  end

  -- Build yq filter path.
  local path = "."
  for i, segment in ipairs(segments) do
    if segment:match('^%[".*"%]%[%d+%]$') then
      -- Bracket notation key with array index: use ["key"][index] notation.
      path = path .. segment
    elseif segment:match('^%[".*"%]') then
      -- Bracket notation key: use ["key"] notation.
      path = path .. segment
    else
      -- Unquoted key (may have array index): use .key or .key[index] notation.
      if i > 1 then
        path = path .. "."
      end
      path = path .. segment
    end
  end

  return path
end

return M
