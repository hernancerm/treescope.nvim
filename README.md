<a href="https://github.com/hernancerm/treescope.nvim/actions/workflows/test.yml" target="_blank">
  <img src="https://github.com/hernancerm/treescope.nvim/actions/workflows/test.yml/badge.svg" />
</a>

# Treescope

Tree-sitter-powered scope discovery.

## Features

- Programmatically retrieve scopes relative to the cursor position, powered by Tree-sitter.
- Supported scopes: outermost_function, yq_path and clojure_namespace.
- Easy integration of scopes in statusline through buf vars.

To enhance [m/]m to navigate among outermost functions use the plugin
<https://github.com/nvim-treesitter/nvim-treesitter-textobjects> (this plugin provides queries for
the @treescope_outermost_function capture):

```lua
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = {
    -- Languages supported for `[m` and `]m`:
    -- (See the "Treesitter" section in init.lua for the inlined query definitions).
    "lua",
    "java",
    "python",
    "clojure",
    "javascript",
    "typescript",
  },
  callback = function()
    -- Delete buf key maps if set. Otherwise, the new key maps have no effect. To learn about
    -- overlapping keymaps use `:verbose nmap [m`. These deletions are necessary for Python.
    pcall(vim.keymap.del, { "n" }, "[m", { buffer = 0 })
    pcall(vim.keymap.del, { "n" }, "]m", { buffer = 0 })
    local move = require(plugin.main .. ".move")
    -- Assign new buf key maps.
    vim.keymap.set({ "n", "x", "o" }, "[m", function()
      move.goto_previous_start("@treescope_outermost_function", "textobjects")
    end, { buffer = 0 })
    vim.keymap.set({ "n", "x", "o" }, "]m", function()
      move.goto_next_start("@treescope_outermost_function", "textobjects")
    end, { buffer = 0 })
  end
})
```

## Requirements

- Neovim >= 0.11.0
- Tree-sitter parsers (depends on scope used and specific language). For example, if using the
  outermost_function scope for lua, then the lua parser is required. The help file
  ([treescope.txt](./doc/treescope.txt)) documents the supported langs per scope.

## Installation

Use your favorite package manager. For example, [Lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "hernancerm/treescope.nvim",
  opts = {},
},
```

The function `require("treescope").setup()` needs to be called before the plugin can be used.
Lazy.nvim does this automatically using the snippet above.

## Default config

```lua
local treescope = require("treescope")
treescope.setup()
```

Is equivalent to:

```lua
local treescope = require("treescope")
treescope.setup({
  buf_vars = {},
})
```

## Documentation

Please refer to the help file: [treescope.txt](./doc/treescope.txt).

## Contributing

I welcome issues requesting any behavior change. However, please do not submit a PR unless it's for
a trivial fix.

## License

[MIT](./LICENSE)
