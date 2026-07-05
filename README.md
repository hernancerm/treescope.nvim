<a href="https://github.com/hernancerm/treescope.nvim/actions/workflows/ci.yml" target="_blank">
  <img src="https://github.com/hernancerm/treescope.nvim/actions/workflows/ci.yml/badge.svg" />
</a>

# Treescope

Tree-sitter-powered scope discovery.

## Features

- Programmatically retrieve scopes relative to the cursor position, powered by Tree-sitter.
- Supported scopes: outermost_function, yq_path and clojure_namespace.
- Easy integration of scopes in statusline through buf vars.

## Requirements

- Neovim >= 0.11.0
- Tree-sitter parsers (depends on scope used and specific language). For example, if using the
  outermost_function scope for lua, then the lua parser is required. The help file
  ([treescope.txt](./doc/treescope.txt)) documents the supported langs per scope.

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
