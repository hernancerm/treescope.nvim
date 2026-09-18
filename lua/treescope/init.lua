--- *treescope.txt* Tree-sitter-powered scope discovery.
---
--- MIT License Copyright (c) 2026 Hernán Cervera.
---
--- Contents:
---
--- 1. Introduction                                         |treescope-introduction|
--- 2. Quickstart                                             |treescope-quickstart|
--- 3. Configuration                                       |treescope-configuration|
--- 4. Statusline integration                                 |treescope-statusline|
--- 5. Keymaps                                                   |treescope-keymaps|
--- 6. Scopes                                                     |treescope-scopes|
--- 7. Functions                                               |treescope-functions|
--- 8. Types                                                       |treescope-types|
---
--- ==============================================================================
--- #tag treescope
--- #tag treescope-introduction
--- Introduction ~
---
--- Problem:
---
--- * I want to have the cursor "scope" in my statusline, but I do not like the
---   typical solution of breadcrumbs as that takes too much space. Most of the
---   time, the meaningful scope to me is the outermost function.
---
--- Solution:
---
--- * Get the scope through Tree-sitter, supporting multiple languages. A scope is
---   a thing like a function or a class, see |treescope-scopes|. Read it with
---   |treescope.get()|, or navigate between scopes with |treescope.goto_next()|
---   and friends. Statusline integration is supported via buffer-local
---   variables, refer to |treescope-statusline|.

--- #delimiter
--- #tag treescope-quickstart
--- Quickstart ~
---
--- * No need to call |treescope.setup()|, but you may to configure the plugin.
--- * You need a Tree-sitter parser for the language you want this plugin to work
---   for. This plugin does not support all languages, see supported languages per
---   scope in |treescope-scopes|.
--- * The plugin doesn't create keymaps, you need to define them yourself.
--- * The plugin sets the Lua global `Treescope`, equivalent to
---   `require("treescope")`.
--- * To get the outermost function at the cursor:
---   `require("treescope").get("function").text`.
--- * To jump to the next function:
---   `require("treescope").goto_next("function")`.

local const = require("treescope.const")

local treescope = {}

_G.Treescope = treescope

vim.api.nvim_create_augroup("Treescope", { clear = true })

--- #delimiter
--- #tag treescope.config
--- #tag treescope.default_config
--- #tag treescope-configuration
--- Configuration ~

--- Module setup.
---@param config table? Merged with default config (|treescope.default_config|).
--- The former takes priority on duplicate keys.
function treescope.setup(config)
  config = config or {}
  -- Cleanup.
  if #vim.api.nvim_get_autocmds({ group = "Treescope" }) > 0 then
    vim.api.nvim_clear_autocmds({ group = "Treescope" })
  end
  -- Merge default and user configuration. User config has precedence.
  treescope.config = vim.tbl_deep_extend(
    "force",
    vim.deepcopy(treescope.config or treescope.default_config),
    config
  )
  -- Validate config.
  -- The validity of each buf var is checked during registration.
  vim.validate(
    "treescope.config.buf_vars",
    treescope.config.buf_vars,
    "table",
    true
  )
  -- Register buf vars from config (set auto-update with an autocmd).
  local vars_service = require("treescope.vars_service")
  for _, entry in ipairs(treescope.config.buf_vars) do
    local buf_var = vars_service.parse_buf_var(entry)
    if buf_var ~= nil then
      vars_service.register_buf_var(buf_var, treescope)
    else
      error(
        "Invalid value in config.buf_vars: "
          .. vim.inspect(entry)
          .. ". Allowed scope ids: "
          .. vim.fn.join(vars_service.get_valid_scope_ids(), ", ")
      )
    end
  end
end

--- The merged config (defaults with user overrides) is in `treescope.config`. The
--- default config is in `treescope.default_config`. Below is the default config:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)

treescope.default_config = {
  buf_vars = {},
}
--minidoc_afterlines_end

--- #tag treescope.config.buf_vars
--- `((string|table)[])`
--- Each item is a scope id (see |treescope-scopes|), or a table `{ scope_id,
--- depth = ... }` to use a non-default `depth` (see |treescope.GetOpts|). For
--- each item, Treescope creates a buf-local var named treescope_<scope_id>,
--- with the depth as a suffix when it is not the default. The value is the
--- `text` of the scope, or an empty string. For example:
--- >
---   buf_vars = {
---     "function",                     -- b:treescope_function
---     { "function", depth = "any" },  -- b:treescope_function_any
---   }
--- <

--- #delimiter
--- #tag treescope-statusline
--- Statusline integration ~

--- Let's say you want the scope `function` in your statusline. First of course
--- you need the relevant Tree-sitter parsers installed. Then make sure your
--- plugin config includes the desired scope:
--- >
---   require("treescope").setup({
---     buf_vars = {
---       "function"
---     },
---   })
--- <
--- Now you can reference the buf var in 'statusline' like this:
--- >
---   ${get(b:,'treescope_function','')}
--- <
--- Treescope keeps the value of the buf var updated as the cursor moves. Neovim
--- automatically updates the statusline when a buf var referenced in 'statusline'
--- changes, so there is no need for any custom refresh logic.
---
--- This setup works nicely without a statusline plugin, it also works well with
--- the plugin https://github.com/hernancerm/bareline.nvim and quite likely
--- also plays well with many other statusline plugins.

--- #delimiter
--- #tag treescope-keymaps
--- Keymaps ~

--- The plugin creates no keymaps. To navigate functions with `]m` and `[m` and
--- list them with `<Leader>o`:
--- >
---   -- Python's ftplugin sets buffer-local [m and ]m, which would shadow these.
---   vim.g.no_python_maps = true
---
---   vim.keymap.set({ "n", "x", "o" }, "]m", function()
---     Treescope.goto_next("function", { count = vim.v.count1, set_jump = true })
---   end)
---   vim.keymap.set({ "n", "x", "o" }, "[m", function()
---     Treescope.goto_prev("function", { count = vim.v.count1, set_jump = true })
---   end)
---   -- Mnemonic: o for outline.
---   vim.keymap.set("n", "<Leader>o", function()
---     Treescope.set_loclist("function", { open = true })
---   end)
--- <
--- `count` makes `3]m` work and `set_jump` makes `<C-o>` go back. Mapping in
--- "x" and "o" modes makes `d]m` work.
---
--- Vim has a built-in |]m| motion for Java-like languages. The maps above
--- replace it everywhere, so in a filetype Treescope does not support, `]m`
--- does nothing. To keep the built-in as a fallback:
--- >
---   local function map_motion(lhs, goto_fn)
---     vim.keymap.set({ "n", "x", "o" }, lhs, function()
---       if Treescope.is_supported("function") then
---         goto_fn("function", { count = vim.v.count1, set_jump = true })
---       else
---         vim.cmd.normal({ vim.v.count1 .. lhs, bang = true })
---       end
---     end)
---   end
---   map_motion("]m", Treescope.goto_next)
---   map_motion("[m", Treescope.goto_prev)
--- <

--- #delimiter
--- #tag treescope-scopes
--- Scopes ~

--- A scope is a thing in the file: a function, a class, the namespace, a path.
--- Every function in |treescope-functions| takes a scope id as its first
--- argument. At a glance:
---
---   Scope id     What                                 Depth  Navigation ~
---   "function"   Function or method at the position   yes    yes
---   "class"      Class at the position                yes    yes
---   "namespace"  Namespace or package of the file     no     no
---   "yq_path"    yq expression for the position       no     no
---
--- Depth applies to scopes that nest. Walking the Tree-sitter tree up from
--- the position visits every enclosing scope, and `depth` picks one of them:
---
--- • "outermost" (default): the farthest one, so nested scopes are skipped.
---   This is what you want in a statusline.
--- • "any": the nearest one. In navigation, "any" also means "stop at every
---   scope, nested or not".
---
--- Depth only counts scopes of the same id. Classes are invisible to
--- "function": a method inside an inner class is its own outermost function.
--- Only a function nested in another function is skipped.
---
--- Navigation is available for scopes with many instances per file. See
--- |treescope.list()|, |treescope.goto_prev()|, |treescope.goto_next()| and
--- |treescope.set_loclist()|. On other scopes these functions warn and do
--- nothing.
---
--- Scope ids are also the valid values of |treescope.config.buf_vars|.

--- #tag treescope-scope-function
--- "function" ~
---
--- The function or method enclosing the position. `text` is its name, `node`
--- is the whole definition, `name_node` is the name identifier.
---
--- With the default depth, "M.foo" is the scope given:
--- >lua
---   M.foo = function()
---     local bar = function()
---       local function baz()
---         -- <Cursor Here>.
---       end
---     end
---   end
--- <
--- With `depth = "any"`, the scope is "baz".
---
--- Languages: lua, java, python, clojure, javascript, typescript,
--- javascriptreact (uses the javascript parser), typescriptreact (uses the
--- tsx parser).

--- #tag treescope-scope-class
--- "class" ~
---
--- The class enclosing the position. `text` is its name, `node` is the whole
--- declaration, `name_node` is the name identifier.
---
--- With the default depth, "App" is the scope given:
--- >java
---   public class App {
---       static class Item {
---           void a() {
---               // <Cursor Here>.
---           }
---       }
---   }
--- <
--- With `depth = "any"`, the scope is "Item".
---
--- Languages: java, python, javascript, typescript.

--- #tag treescope-scope-namespace
--- "namespace" ~
---
--- The namespace or package declared at the top of the file. The position
--- does not matter. `text` is the namespace, `node` is the declaration,
--- `name_node` is the name inside it.
---
--- "myapp.core" is the scope given:
--- >clojure
---   (ns myapp.core)
---   (println "Hello World")
---   ; <Cursor Here>.
--- <
--- Languages: clojure, java.

--- #tag treescope-scope-yq_path
--- "yq_path" ~
---
--- A yq filter expression for the position. `text` is the expression. `node`
--- and `name_node` are nil: the expression is built from every ancestor, so no
--- single node owns it.
---
--- ".spring.application.name" is the scope given:
--- >yaml
---   spring:
---     application:
---       # <Cursor On Key Below>.
---       name: my-app
--- <
--- Languages: yaml, json, jsonc (uses the json parser).

--- #delimiter
--- #tag treescope-functions
--- Functions ~

---@private
---@param scope_id string
---@return table scope_module
local function get_scope_module(scope_id)
  vim.validate("scope_id", scope_id, function(id)
    return vim.tbl_contains(vim.tbl_values(const.ScopeIds), id)
  end, "one of: " .. vim.fn.join(vim.tbl_values(const.ScopeIds), ", "))
  return require("treescope.scopes." .. scope_id)
end

---@private
---@param opts table?
---@return const.Depth
local function get_depth(opts)
  local depth = (opts and opts.depth) or const.Depth.OUTERMOST
  vim.validate("opts.depth", depth, function(d)
    return vim.tbl_contains(vim.tbl_values(const.Depth), d)
  end, "one of: " .. vim.fn.join(vim.tbl_values(const.Depth), ", "))
  return depth
end

---@private
---@class treescope.Ctx
---@field bufnr integer
---@field lang string
---@field provider table
---@field root TSNode

---@private
--- Everything needed to resolve {scope_id} in a buffer, or nil when the
--- filetype is not supported or the parser is missing.
---@param scope_id const.ScopeIds
---@param opts table?
---@return treescope.Ctx?
local function get_ctx(scope_id, opts)
  local bufnr = (opts and opts.bufnr) or 0
  if bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local provider, lang =
    require("treescope.provider_locator").get(scope_id, vim.bo[bufnr].filetype)
  if not provider or not lang then
    return
  end
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
  if not ok or not parser then
    return
  end
  local trees = parser:parse()
  if not trees or #trees == 0 then
    return
  end
  local root = trees[1]:root()
  if not root then
    return
  end
  return { bufnr = bufnr, lang = lang, provider = provider, root = root }
end

---@private
--- Position to resolve, 0-indexed. Defaults to the cursor of the current window
--- when it shows {bufnr}, else to the cursor of any window showing {bufnr}.
---@param bufnr integer
---@param opts table?
---@return integer? row
---@return integer? col
local function get_pos(bufnr, opts)
  if opts and opts.pos then
    return opts.pos[1] - 1, opts.pos[2]
  end
  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_buf(win) ~= bufnr then
    win = vim.fn.bufwinid(bufnr)
    if win == -1 then
      return
    end
  end
  local cursor = vim.api.nvim_win_get_cursor(win)
  return cursor[1] - 1, cursor[2]
end

---@private
--- Where navigation lands: the name when there is one, else the node start.
---@param scope treescope.Scope
---@return integer row 0-indexed.
---@return integer col 0-indexed.
local function get_scope_pos(scope)
  local node = scope.name_node or scope.node
  ---@diagnostic disable-next-line: need-check-nil
  local row, col = node:start()
  return row, col
end

---@private
---@param scope_id const.ScopeIds
---@return boolean
local function is_navigable(scope_id)
  return get_scope_module(scope_id).list ~= nil
end

---@private
---@param scope_id const.ScopeIds
local function notify_not_navigable(scope_id)
  vim.notify(
    "treescope: scope '" .. scope_id .. "' does not support navigation",
    vim.log.levels.WARN
  )
end

--- Whether a scope is supported in a buffer, i.e. Treescope has a provider
--- for the buffer's 'filetype'. Does not check that the Tree-sitter parser
--- is installed. Useful to fall back to a built-in motion in a keymap, see
--- |treescope-keymaps|.
---@param scope_id string See |treescope-scopes|.
---@param opts treescope.IsSupportedOpts?
---@return boolean
function treescope.is_supported(scope_id, opts)
  get_scope_module(scope_id)
  local bufnr = (opts and opts.bufnr) or 0
  if bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end
  local provider =
    require("treescope.provider_locator").get(scope_id, vim.bo[bufnr].filetype)
  return provider ~= nil
end

--- Get the scope at a position.
---@param scope_id string See |treescope-scopes|.
---@param opts treescope.GetOpts?
---@return treescope.Scope Empty table when there is no scope at the position,
--- the filetype is not supported or the parser is missing.
function treescope.get(scope_id, opts)
  local scope_module = get_scope_module(scope_id)
  local depth = get_depth(opts)
  local ctx = get_ctx(scope_id, opts)
  if not ctx then
    return {}
  end
  local row, col = get_pos(ctx.bufnr, opts)
  if not row or not col then
    return {}
  end
  return scope_module.get(ctx, row, col, depth)
end

--- List all the scopes in a buffer, sorted by position.
---@param scope_id string A node scope, see |treescope-scopes|.
---@param opts treescope.ListOpts?
---@return treescope.Scope[] Empty when the filetype is not supported or the
--- parser is missing.
function treescope.list(scope_id, opts)
  local scope_module = get_scope_module(scope_id)
  local depth = get_depth(opts)
  if not scope_module.list then
    notify_not_navigable(scope_id)
    return {}
  end
  local ctx = get_ctx(scope_id, opts)
  if not ctx then
    return {}
  end
  return scope_module.list(ctx, depth)
end

---@private
---@param direction "prev"|"next"
---@param scope_id const.ScopeIds
---@param opts treescope.GotoOpts?
local function goto_scope(direction, scope_id, opts)
  opts = opts or {}
  if not is_navigable(scope_id) then
    notify_not_navigable(scope_id)
    return
  end
  local scopes = treescope.list(scope_id, { depth = opts.depth })
  local win = vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(win)
  local cur_row, cur_col = cursor[1] - 1, cursor[2]
  -- Index of the last scope strictly before the cursor, 0 if none.
  local before = 0
  for i, scope in ipairs(scopes) do
    local row, col = get_scope_pos(scope)
    if row < cur_row or (row == cur_row and col < cur_col) then
      before = i
    end
  end
  -- Scopes exactly at the cursor are neither prev nor next, skip them.
  local after = before + 1
  while scopes[after] do
    local row, col = get_scope_pos(scopes[after])
    if row > cur_row or (row == cur_row and col > cur_col) then
      break
    end
    after = after + 1
  end
  local count = opts.count or 1
  local target
  if direction == "prev" then
    target = scopes[before - count + 1]
  else
    target = scopes[after + count - 1]
  end
  if not target then
    return
  end
  if opts.set_jump then
    vim.cmd("normal! m'")
  end
  local row, col = get_scope_pos(target)
  vim.api.nvim_win_set_cursor(win, { row + 1, col })
end

--- Move the cursor to the previous scope in the current buffer. No-op if none.
---@param scope_id string A node scope, see |treescope-scopes|.
---@param opts treescope.GotoOpts?
function treescope.goto_prev(scope_id, opts)
  goto_scope("prev", scope_id, opts)
end

--- Move the cursor to the next scope in the current buffer. No-op if none.
---@param scope_id string A node scope, see |treescope-scopes|.
---@param opts treescope.GotoOpts?
function treescope.goto_next(scope_id, opts)
  goto_scope("next", scope_id, opts)
end

--- Populate the |location-list| of the current window with all the scopes in a
--- buffer.
---@param scope_id string A node scope, see |treescope-scopes|.
---@param opts treescope.SetLoclistOpts?
function treescope.set_loclist(scope_id, opts)
  opts = opts or {}
  local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()
  local scopes = treescope.list(scope_id, opts)
  local items = {}
  for _, scope in ipairs(scopes) do
    local row, col = get_scope_pos(scope)
    table.insert(items, {
      bufnr = bufnr,
      lnum = row + 1,
      col = col + 1,
      text = scope.text or "(anonymous)",
    })
  end
  vim.fn.setloclist(
    0,
    {},
    "r",
    { title = "[Treescope] " .. scope_id, items = items }
  )
  if opts.open then
    vim.cmd("lopen")
  end
end

--- #delimiter
--- #tag treescope-types
--- Types ~

--- #tag treescope.Scope
--- Return value of |treescope.get()| and items of |treescope.list()|.
---@class treescope.Scope
---@field text string? Display string, e.g. the function name. Nil for an
--- anonymous scope.
---@field node TSNode? The whole scope, e.g. the function definition. Nil for
--- the "yq_path" scope: its path is built from all ancestors.
---@field name_node TSNode? The name inside `node`, e.g. the identifier. This is
--- where navigation lands. Nil when `node` is nil or the scope is anonymous.

--- #tag treescope.IsSupportedOpts
---@class treescope.IsSupportedOpts
---@field bufnr integer? Default: current buffer.

--- #tag treescope.GetOpts
---@class treescope.GetOpts
---@field bufnr integer? Default: current buffer.
---@field pos integer[]? `{row, col}`, 1-indexed row and 0-indexed col like
--- |nvim_win_get_cursor()|. Default: cursor of the window showing `bufnr`.
---@field depth "outermost"|"any"? Default: "outermost". Node scopes only.
--- "outermost" is the scope farthest from the position, "any" is the nearest.

--- #tag treescope.ListOpts
---@class treescope.ListOpts
---@field bufnr integer? Default: current buffer.
---@field depth "outermost"|"any"? Default: "outermost". "outermost" skips
--- nested scopes, "any" includes them.

--- #tag treescope.GotoOpts
---@class treescope.GotoOpts
---@field depth "outermost"|"any"? Default: "outermost". "outermost" skips
--- nested scopes, "any" stops at them.
---@field count integer? Default: 1. Scopes to step over. No-op if fewer than
--- count scopes exist in that direction.
---@field set_jump boolean? Default: false. Whether to push a |jumplist| entry.

--- #tag treescope.SetLoclistOpts
---@class treescope.SetLoclistOpts
---@field bufnr integer? Default: current buffer.
---@field depth "outermost"|"any"? Default: "outermost". "outermost" skips
--- nested scopes, "any" includes them.
---@field open boolean? Default: false. Open the location list after populating.

return treescope
