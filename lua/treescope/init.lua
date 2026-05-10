--- *treescope* Tree-sitter-powered scope discovery.
---
--- MIT License Copyright (c) 2026 Hernán Cervera.
---
--- Contents:
---
--- 1. Introduction                                         |treescope-introduction|
--- 2. Quickstart                                             |treescope-quickstart|
--- 3. Configuration                                       |treescope-configuration|
--- 4. Statusline integration                                 |treescope-statusline|
--- 5. Functions                                               |treescope-functions|
---
--- ==============================================================================
--- #tag treescope-introduction
--- Introduction ~
---
--- Problem:
---
--- * I want to have the cursor "scope" in my statusline, but I do not like the
---   typical solution of breadcrumbs as that takes too much space. Most of the
---   time, the meaningful scope to me is the "outermost function".
---
--- Solution:
---
--- * Get the "outermost function" (|treescope.outermost_function()|) through
---   Tree-sitter, supporting multiple languages. Other scopes are supported too,
---   refer to |treescope-scopes|. Statusline integration is supported via
---   buffer-local variables, refer to |treescope-statusline|.

--- #delimiter
--- #tag treescope-quickstart
--- Quickstart ~
---
--- You need a Tree-sitter parser for the language you want this plugin to work
--- for. This plugin does not support all languages, see supported languages per
--- scope in |treescope-functions|.
---
--- You need to call the |treescope.setup()| function to initialize the plugin.
--- >lua
---   { -- For Lazy.nvim
---     "hernancerm/treescope.nvim",
---     opts = {},
---   }
---<
--- * To have a scope in your statusline, see |treescope-statusline|.
---
--- * To get the scopes using the Lua API, see |treescope-functions|. E.g., to get
---   the outermost function: `require("treescope").outermost_function().text`.

local treescope = {}

treescope.config = {}

local assign_default_config

--- #delimiter
--- #tag treescope.config
--- #tag treescope.default_config
--- #tag treescope-configuration
--- Configuration ~

--- Module setup.
---@param config table? Merged with default config (|treescope.default_config|).
--- The former takes priority on duplicate keys.
function treescope.setup(config)
  assign_default_config()

  -- Validate config.
  if config ~= nil then
    -- Required configuration.
    vim.validate("config.buf_vars", config.buf_vars, "table", true)
    -- The validity of each buf var is checked during registration.
  end

  -- Merged default and user configuration. User config has precedence.
  treescope.config = vim.tbl_deep_extend(
    "force",
    vim.deepcopy(treescope.default_config),
    config or {}
  )

  -- Create clean augroup.
  vim.api.nvim_create_augroup("Treescope", { clear = true })

  -- Register buf vars from config (set auto-update with an autocmd).
  local vars_service = require("treescope.vars_service")
  for _, managed_buf_var in ipairs(treescope.config.buf_vars) do
    local scope_id = vars_service.get_scope_id(managed_buf_var)
    if scope_id ~= nil then
      vars_service.register_buf_var(scope_id, treescope)
    else
      error(
        "Invalid value in config.buf_vars: "
          .. managed_buf_var
          .. ". Allowed values: "
          .. vim.fn.join(vars_service.get_valid_buf_var_names(), ", ")
      )
    end
  end

  _G.Treescope = treescope
end

--- The merged config (defaults with user overrides) is in `treescope.config`. The
--- default config is in `treescope.default_config`. Below is the default config:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
--minidoc_replace_start
assign_default_config = function()
  --minidoc_replace_end
  --minidoc_replace_start {
  treescope.default_config = {
    --minidoc_replace_end
    buf_vars = {},
  }
  --minidoc_afterlines_end
end

-- TODO: buf_vars to list the exact var names, with the "treescope" prefix.

--- #tag treescope.config.buf_vars
--- `(string[])`
--- The valid values are the names of the functions in |treescope-functions|,
--- e.g., "outermost_function". For each item in this list, Treescope creates a
--- buf-local var of the form treescope_<item>, e.g., treescope_outermost_function
--- given the item "outermost_function".

--- #delimiter
--- #tag treescope-statusline
--- Statusline integration ~

--- Let's say you want the scope `outermost_function` in your statusline. First of
--- course you need the relevant Tree-sitter parsers installed. Then make sure
--- your plugin config includes the desired scope:
--- >
---   require("treescope").setup({
---     buf_vars = {
---       "outermost_function"
---     },
---   })
--- <
--- Now you can reference the buf var in 'statusline' like this:
--- >
---   ${get(b:,'treescope_outermost_function','')}
--- <
--- Treescope keeps the value of the buf var updated as the cursor moves. Neovim
--- automatically updates the statusline when a buf var referenced in 'statusline'
--- changes, so there is no need for any custom refresh logic.
---
--- This setup works nicely without a statusline plugin, it also works well with
--- the plugin https://github.com/hernancerm/bareline.nvim and quite likely
--- also plays well with many other statusline plugins.

--- #delimiter
--- #tag treescope-functions
--- #tag treescope-scopes
--- Functions ~

--- Each function in this section corresponds to a scope. Each scope can
--- optionally be exposed as a buf var. See: |treescope.config.buf_vars|.

--- #tag treescope.OutermostFunction
--- Return value of |treescope.outermost_function()|.
---@class treescope.OutermostFunction
---@field text string? Name of outermost function relative to cursor, else nil.
---@field goto_prev fun(opts:table?) Move cursor to prev outermost function.
--- No-op if none. Keys allowed in opts:
--- * count (`integer`) Default: 1. Functions to step over. No-op if fewer than
---   count functions exist in that direction.
--- * set_jump (`boolean`) Default: false. Whether to push a |jumplist| entry.
---@field goto_next fun(opts:table?) Move cursor to next outermost function.
--- No-op if none. Keys allowed in opts:
--- * count (`integer`) Default: 1. Functions to step over. No-op if fewer than
---   count functions exist in that direction.
--- * set_jump (`boolean`) Default: false. Whether to push a |jumplist| entry.
---@field set_loclist fun(opts:table?) Populate |location-list| with all the
--- outermost functions in the current file. Keys allowed in opts:
--- * open (`boolean`) Open the location list after populating it.

--- The "outermost function" is the name of the function or method at the highest
--- level found from walking the Tree-sitter tree upwards from the cursor
--- position. For example, "M.foo" is the outermost function given:
--- >lua
--- M.foo = function()
---   local bar = function()
---     local function baz()
---       -- <Cursor Here>.
---     end
---   end
--- end
--- <
--- Languages supported:
--- • lua
--- • java
--- • python
--- • clojure
--- • javascript
--- • typescript
---@return treescope.OutermostFunction
function treescope.outermost_function()
  return require("treescope.scopes.outermost_function").get_scope()
end

--- #tag treescope.YqPath
--- Return value of |treescope.yq_path()|.
---@class treescope.YqPath
---@field text string? Name of yq path relative to cursor, else nil.

--- The "yq path" is a yq filter expression for the cursor position in YAML
--- files. This scope only works in buffers with a `yaml` 'filetype'. For
--- example, ".spring.application.name" is the path given:
--- >yaml
--- spring:
---   application:
---     # <Cursor On Key Below>.
---     name: my-app
--- <
--- Languages supported:
--- • yaml
--- • json
--- • jsonc (json Tree-sitter parser needed)
---@return treescope.YqPath
function treescope.yq_path()
  return require("treescope.scopes.yq_path").get_scope()
end

--- #tag treescope.Namespace
--- Return value of |treescope.namespace()|.
---@class treescope.Namespace
---@field text string? Name of the file namespace, regardless of cursor, else nil.

--- The "namespace" is the name of the namespace or package declared at the top
--- of the present file. For example, "myapp.core" is the namespace given:
--- >clojure
--- (ns myapp.core)
--- (println "Hello World")
--- ; <Cursor Here>.
--- <
--- Languages supported:
--- • java
--- • clojure
---@return treescope.Namespace
function treescope.namespace()
  return require("treescope.scopes.namespace").get_scope()
end

return treescope
