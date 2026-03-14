-- See: <https://github.com/echasnovski/mini.nvim/blob/main/TESTING.md>.

-- Intended use cases of this file:
-- - `mini.test` tests: For child Neovim instances to be able to require the plugin and deps.
-- - `make test`: For headless Neovim instance to run tests.

-- Add cwd to 'runtimepath' to be able to require files in `./lua/` dir.
-- Purpose: `mini.test` child Neovim instances can:
-- - `require("treescope")`
vim.cmd([[let &rtp.=",".getcwd()]])

-- Set up for headless Neovim. Intended for `make test`.
-- Purpose: `mini.test` child Neovim instances can:
-- - `require("nvim-treesitter")`
-- - `require("mini.test")`
-- Why `nvim_list_uis` condition: Headless Neovim instances (like the one spawned with `make`) use
-- the plugins from the `deps` dir, while non-headless Neovim instances (like when user uses Neovim
-- as usual) do not have access to the plugins in the `deps` dir.
if #vim.api.nvim_list_uis() == 0 then
  vim.cmd([[let &rtp.=",".getcwd()."/deps/nvim-treesitter"]])
  vim.cmd([[let &rtp.=",".getcwd()."/deps/mini.test"]])
  -- Set up `nvim-treesitter`.
  -- This plugin significantly facilitates installing Tree-sitter parsers, which the tests need.
  -- There does not seem to be a way to download pre-built parsers for any arbitrary language, and
  -- compiling each parser is not practical due to the amount of languages.
  local install_dir = vim.fs.joinpath(vim.fn.getcwd(), "deps", "parsers")
  require("nvim-treesitter").setup({
    install_dir = install_dir,
  })
  -- Set up `mini.test`.
  require("mini.test").setup()
end
