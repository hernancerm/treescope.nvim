<a href="https://github.com/hernancerm/treescope.nvim/actions/workflows/ci.yml" target="_blank">
  <img src="https://github.com/hernancerm/treescope.nvim/actions/workflows/ci.yml/badge.svg" />
</a>

# Treescope

Tree-sitter-powered scope discovery.

## Features

- Programmatically retrieve scopes relative to the cursor position, powered by Tree-sitter.
- Supported scopes: function, class, code_fence, namespace and yq_path.
- Navigate between functions, classes or code fences (`goto_prev`, `goto_next`, location list).
- Easy integration of scopes in statusline via buf vars.

## Requirements

- Neovim >= 0.12.0
- Tree-sitter parsers (depends on scope used and specific language). For example, if using the
  function scope for lua, then the lua parser is required. The help file
  ([treescope.txt](./doc/treescope.txt)) documents the supported langs per scope.
  Run `:checkhealth treescope` to see which parsers are missing.

## Installation

Install with your favorite package manager. For example, using Neovim's builtin package manager,
[vim.pack](https://neovim.io/doc/user/pack/#vim.pack):

```lua
vim.pack.add({
  "https://github.com/hernancerm/treescope.nvim",
})
```

Some things to notice:

- `require("treescope").setup()` does **not** need to be called. You may call it to configure the plugin.
- The plugin sets the Lua global `Treescope`, equivalent to `require("treescope")`.
- The plugin does **not** create keymaps.

## Keymaps

The plugin creates no keymaps. A minimal setup to navigate functions with `]m` and `[m`, and list
them with `<Leader>o`:

```lua
-- Don't shadow `[m`/`]m`.
vim.g.no_python_maps = true
vim.keymap.set({ "n", "x", "o" }, "]m", function()
  Treescope.goto_next("function", { count = vim.v.count1, set_jump = true })
end)
vim.keymap.set({ "n", "x", "o" }, "[m", function()
  Treescope.goto_prev("function", { count = vim.v.count1, set_jump = true })
end)
-- Mnemonic: o for outline.
vim.keymap.set("n", "<Leader>o", function()
  Treescope.set_loclist("function", { open = true })
end)
```

See `:help treescope-keymaps` for keeping Vim's built-in `]m` as a fallback in unsupported filetypes.

## Default config

```lua
require("treescope").setup({
  buf_vars = {},
})
```

## Documentation

Please refer to the help file: [treescope.txt](./doc/treescope.txt) (`:help treescope.txt`).

## Contributing

I welcome issues requesting any behavior change. However, please do not submit a PR unless it's for
a trivial fix.

## License

[MIT](./LICENSE)
