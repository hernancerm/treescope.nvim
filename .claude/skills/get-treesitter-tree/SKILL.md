---
name: get-treesitter-tree
description: Extract and display the tree-sitter parse tree for a code snippet, producing output identical to Neovim's :InspectTree command — node types, anonymous tokens, and [row, col] ranges. Use this skill whenever the user wants to inspect or debug a tree-sitter AST, understand what node types wrap a piece of syntax, explore parse trees, or sends the /get-treesitter-tree command. Also trigger for phrasings like "show me the AST for this", "what tree-sitter node is X", "parse this with tree-sitter", or "inspect tree for this code".
---

# get-treesitter-tree

Runs Neovim headlessly to produce the exact `:InspectTree` output for a code snippet — same node types, same `[row, col] - [row, col]` ranges, same anonymous token literals. Nothing is reimplemented; Neovim does all the work.

The temp file is always named `.txt`. The extension is irrelevant because the filetype is set explicitly via `-c "set filetype=..."` — Neovim's ftdetect never gets a chance to guess.

## Input format

```
/get-treesitter-tree <nvim-filetype>
<code — one or more lines>
```

**`nvim-filetype`** is the name Neovim uses for `:set filetype=`. Common values:

`javascript` · `typescript` · `python` · `rust` · `lua` · `go` · `c` · `cpp` · `ruby` · `sh` · `json` · `yaml` · `html` · `css`

## Handling missing input

If the user sends `/get-treesitter-tree` with no arguments, or the message is missing the filetype or the code, ask for the two pieces before proceeding:

1. The nvim filetype name (e.g. `javascript`, `python`, `rust`)
2. The code snippet to parse

## Executing the command

Once you have `LANG` and `CODE`, run the following in `bash_tool`.

### Step 1 — write the code file

The file is always `.txt`; the filetype is set explicitly, so the extension does not matter.

Use a single-quoted heredoc with a collision-resistant delimiter — `__TS_CODE_FENCE__` will not appear literally in virtually any real source code:

```bash
CODE_FILE="/tmp/ts_code_$$.txt"

cat > "$CODE_FILE" << '__TS_CODE_FENCE__'
<paste CODE here verbatim — do not escape anything>
__TS_CODE_FENCE__
```

### Step 2 — write the Lua capture script

```bash
LUA_FILE="/tmp/ts_lua_$$.lua"

cat > "$LUA_FILE" << '__TS_LUA_FENCE__'
-- Snapshot which buffer is current before InspectTree opens its split
local orig_buf = vim.api.nvim_get_current_buf()

-- Open the tree view (creates a new split and makes it current)
vim.treesitter.inspect_tree()

-- Grab the new current buffer — this is the tree buffer
local tree_buf = vim.api.nvim_get_current_buf()

if tree_buf ~= orig_buf then
  local lines = vim.api.nvim_buf_get_lines(tree_buf, 0, -1, false)
  io.write(table.concat(lines, '\n') .. '\n')
  io.flush()
else
  io.stderr:write('tree-sitter-skill: inspect_tree did not open a new buffer\n')
end

vim.cmd('qall!')
__TS_LUA_FENCE__
```

### Step 3 — run Neovim headlessly

```bash
nvim --headless -n \
  -c "set filetype=${LANG}" \
  -c "luafile ${LUA_FILE}" \
  "$CODE_FILE" 2>/dev/null
```

Flag rationale:
- `--headless` — no TUI, but full config + plugins load, so nvim-treesitter parsers are present
- `-n` — no swapfile; avoids swap-exists prompts that would stall headless mode
- `-c "set filetype=..."` — sets the filetype (and triggers parser attachment) before the Lua script runs
- `-c "luafile ..."` — runs the capture script after the file and filetype are ready
- `2>/dev/null` — suppresses plugin startup warnings that would pollute stdout

### Step 4 — clean up

```bash
rm -f "$CODE_FILE" "$LUA_FILE"
```

### Step 5 — display the output

Wrap the captured stdout in a fenced code block with no language tag and show it to the user:

````
```
(program [0, 0] - [3, 0]
  (function_declaration [0, 0] - [2, 1]
    ...))
```
````

## Failure modes and fixes

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Empty output, exit 0 | Parser not installed for this filetype | Run `:TSInstall <lang>` in Neovim first |
| `E319: No such group or event` or similar | Plugin load error; harmless | Already suppressed by `2>/dev/null` |
| `tree-sitter-skill: inspect_tree did not open a new buffer` | Very old Neovim (pre-0.9) | Upgrade to Neovim ≥ 0.9 |
| Garbled output with NUL bytes | Binary content in code snippet | Not supported; tree-sitter parsers expect valid text |

## Full example

**User prompt:**
```
/get-treesitter-tree javascript
function greet(name) {
  return "hello, " + name;
}
```

**Assembled bash invocation (what you run in bash_tool):**
```bash
CODE_FILE="/tmp/ts_code_$$.txt"
LUA_FILE="/tmp/ts_lua_$$.lua"

cat > "$CODE_FILE" << '__TS_CODE_FENCE__'
function greet(name) {
  return "hello, " + name;
}
__TS_CODE_FENCE__

cat > "$LUA_FILE" << '__TS_LUA_FENCE__'
local orig_buf = vim.api.nvim_get_current_buf()
vim.treesitter.inspect_tree()
local tree_buf = vim.api.nvim_get_current_buf()
if tree_buf ~= orig_buf then
  local lines = vim.api.nvim_buf_get_lines(tree_buf, 0, -1, false)
  io.write(table.concat(lines, '\n') .. '\n')
  io.flush()
else
  io.stderr:write('tree-sitter-skill: inspect_tree did not open a new buffer\n')
end
vim.cmd('qall!')
__TS_LUA_FENCE__

nvim --headless -n \
  -c "set filetype=javascript" \
  -c "luafile ${LUA_FILE}" \
  "$CODE_FILE" 2>/dev/null

rm -f "$CODE_FILE" "$LUA_FILE"
```

**Expected output (displayed to user):**
```
(program [0, 0] - [3, 0]
  (function_declaration [0, 0] - [2, 1]
    name: (identifier [0, 9] - [0, 14])
    parameters: (formal_parameters [0, 14] - [0, 20]
      (identifier [0, 15] - [0, 19]))
    body: (statement_block [0, 21] - [2, 1]
      (return_statement [1, 2] - [1, 27]
        (binary_expression [1, 9] - [1, 26]
          left: (string [1, 9] - [1, 19])
          right: (identifier [1, 22] - [1, 26]))))))
```
