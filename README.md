<a href="https://github.com/hernancerm/treescope.nvim/actions/workflows/test.yml" target="_blank">
  <img src="https://github.com/hernancerm/treescope.nvim/actions/workflows/test.yml/badge.svg" />
</a>

# Treescope

Tree-sitter-powered scope discovery.

## Features

- Programmatically retrieve scopes relative to the cursor position, powered by Tree-sitter.
- Supported scopes: outer_function, yq_path and clojure_namespace.
- Easy integration of scopes in statusline through buf vars.

## Requirements

- Neovim >= 0.11.0
- Tree-sitter parsers (depends on scope used and specific language). For example, if using the
  outer_function scope for lua, then the lua parser is required. The help file
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
