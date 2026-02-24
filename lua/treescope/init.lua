--- *treescope* Tree-sitter-powered scope discovery.
---
--- MIT License Copyright (c) 2026 Hernán Cervera.
---
--- Contents:
---
--- 1. Introduction                                         |treescope-introduction|
--- 2. Quickstart                                             |treescope-quickstart|
--- 3. Configuration                                       |treescope-configuration|
--- 4. Scopes                                                     |treescope-scopes|
--- 5. Language support                                     |treescope-lang-support|
--- 6. Functions                                               |treescope-functions|
---
--- ==============================================================================
--- #tag treescope-introduction
--- Introduction ~
---
--- Problem:
---
--- * For a long time I've wanted to have the cursor "scope" in my statusline.
---   Typically this would be breadcrumbs, but I want the least amount of info
---   which still proves useful, as horizontal space is precious. I could not find
---   a plugin which returns scopes so each user can integrate them in their
---   statusline in whichever way they want.
---
--- Solution:
---
--- * This plugin. It uses Tree-sitter to get scopes. The scope which motivated me
---   to build this plugin is |treescope.outer_function()|, which concisely gives
---   enough info for me to know where I am.
---
--- * You may use the Lua API, |treescope-functions|, for any programmatic needs
---   you may have. For integrating the scopes to your statusline, I suggest you
---   enable the corresponding buf vars, see |treescope.config.buf_vars|, and
---   reference the buf vars in your statusline with an expression like the
---   following: `${get(b:,'treescope_outer_function','')}`. This way the
---   statusline is automatically updated when the var gets a new value.

--- #delimiter
--- #tag treescope-quickstart
--- Quickstart ~
---
--- You need a Tree-sitter parser for the language you want this plugin to work
--- for. This plugin does not support all languages, see |treescope-lang-support|.
---
--- You need to call the |treescope.setup()| function to initialize the plugin.
--- >lua
---   { -- For Lazy.nvim
---     "hernancerm/treescope.nvim",
---     opts = {}
---   }
---<
--- * To have a scope in your statusline, see |treescope.config.buf_vars|.
---
--- * To get the scopes using the Lua API, see |treescope-functions|. E.g., to get
---   the outer function: `require("treescope").outer_function()`. In this case
---   there is no need to provide special configuration to the plugin.

local const = require("treescope.const")

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
  vim.api.nvim_create_augroup(const.AUGROUP_NAME, { clear = true })

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

--- #tag treescope.config.buf_vars
--- `(string[])`
--- The valid values are scopes from |treescope-scopes|, e.g., `outer_function`.
--- By default, Treescope does not create buf vars. This config key indicates to
--- the plugin to create the buf var corresponding to the scope, and keep it up to
--- date as the cursor moves.
---
--- The intended use case of buf vars is to be used in the statusline via an
--- expression, e.g., `${get(b:,'treescope_outer_function','')}`. If you merely
--- intend to use Treescope through its Lua API, you may ignore this config key.
---
--- The names of the buf vars are `treescope_` followed by the scope. For example,
--- for the scope `outer_function` the buf var is `treescope_outer_function`.

--- #delimiter
--- #tag treescope-scopes
--- Scopes ~

--- Each function in |treescope-functions| corresponds to a scope. The docs of
--- each function explains what each scope means. Each scope can optionally be
--- exposed as a buf var. See: |treescope.config.buf_vars|.
---
--- The complete list of scopes is as follows:
---
--- * `outer_function`
--- * `clojure_namespace`
--- * `yq_path`

--- #delimiter
--- #tag treescope-lang-support
--- Language support ~

--- Language    `outer_function`  `clojure_namespace`  `yq_path`
--- ----------  ----------------  -------------------  ---------
--- Lua         ✓                 n/a                  n/a
--- Java        ✓                 n/a                  n/a
--- Python      ✓                 n/a                  n/a
--- Clojure     ✓                 ✓                    n/a
--- JavaScript  ✓                 n/a                  n/a
--- TypeScript  ✓                 n/a                  n/a
--- YAML        n/a               n/a                  ✓
--- JSON        n/a               n/a                  ✓
--- JSONC       n/a               n/a                  ✓

--- #delimiter
--- #tag treescope-functions
--- Functions ~

--- The "outer function" is the name of the function or method at the highest
--- level found from walking the Tree-sitter tree upwards from the cursor
--- position. For example, "M.foo" is the outer function given:
--- >lua
--- M.foo = function(opts)
---   local bar = function(cb)
---     local function baz(x, co)
---       -- <Cursor Here>.
---     end
---   end
--- end
--- <
---@return string?
function treescope.outer_function()
  local bufnr = vim.api.nvim_get_current_buf()

  -- Validate buffer.
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end

  -- Get filetype once.
  local filetype = vim.bo[bufnr].filetype
  if not filetype or filetype == "" then
    return nil
  end

  -- Get provider.
  local provider_locator = require("treescope.provider_locator")
  local provider = provider_locator.get_outer_function_provider(filetype)
  if provider == nil then
    return nil
  end

  -- Get cursor position.
  local win = vim.api.nvim_get_current_win()
  local row, col = unpack(vim.api.nvim_win_get_cursor(win))
  row = row - 1

  -- Verify buffer hasn't changed.
  if vim.api.nvim_win_get_buf(win) ~= bufnr then
    return nil
  end

  -- Get Tree-sitter language.
  local lang = vim.treesitter.language.get_lang(filetype)
  if not lang then
    return nil
  end

  local parser = vim.treesitter.get_parser(bufnr, lang)
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

  local node = root:named_descendant_for_range(row, col, row, col)
  if not node then
    return nil
  end

  ---@type TSNode?
  local candidate = nil
  ---@type TSNode?
  local cur = node

  -- Walk up: remember the outermost function.
  while cur do
    if provider.is_function(cur) then
      candidate = cur
    end
    cur = cur:parent()
  end

  if not candidate then
    return nil
  end

  return provider.get_function_name(candidate, bufnr)
end

--- The "clojure namespace" is the name of the namespace at the present Clojure
--- file. This scope only works in buffers with a `clojure` 'filetype'. For
--- example, "fwpd.core-test" is the namespace given:
--- >clojure
--- (ns fwpd.core-test
---   (:require [clojure.test :refer :all]
---             [fwpd.core :refer :all]))
--- (deftest a-test
---   (testing "FIXME, I fail."
---     ; <Cursor Here>.
---     (is (= 0 1))))
--- <
---@return string?
function treescope.clojure_namespace()
  local bufnr = vim.api.nvim_get_current_buf()

  -- Validate buffer.
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end

  -- Check filetype is Clojure.
  local filetype = vim.bo[bufnr].filetype
  if not filetype or filetype ~= "clojure" then
    return nil
  end

  -- Get provider.
  local provider_locator = require("treescope.provider_locator")
  local provider = provider_locator.get_clojure_namespace_provider()

  return provider.get_namespace(bufnr)
end

--- The "yq path" is a yq filter expression for the cursor position in YAML
--- files. This scope only works in buffers with a `yaml` 'filetype'. For
--- example, ".spring.application.name" is the path given:
--- >yaml
--- spring:
---   application:
---     # <Cursor On 'name' Key Below>.
---     name: my-app
--- <
---@return string?
function treescope.yq_path()
  local bufnr = vim.api.nvim_get_current_buf()

  -- Validate buffer.
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end

  -- Get provider.
  local provider_locator = require("treescope.provider_locator")
  local provider = provider_locator.get_yq_path_provider(bufnr)

  if not provider then
    return nil
  end

  return provider.get_path(bufnr)
end

return treescope
