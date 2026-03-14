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
-- - `require("test")`
-- Why `nvim_list_uis` condition: Headless Neovim instances (like the one spawned with `make`) use
-- the `mini.test` file (`test.lua`) from the `deps` dir, while non-headless Neovim instances (like
-- when user uses Neovim as usual) have access to whatever version of `mini.doc` they have
-- installed.
if #vim.api.nvim_list_uis() == 0 then
  -- Add `./deps/` dir to 'runtimepath' to be able to use `test.lua` and `nvim-treesitter`.
  vim.cmd([[let &rtp.=",".getcwd()."/deps"]])
  -- Set up `nvim-treesitter`.
  -- This plugin significantly facilitates installing Tree-sitter parsers, which the tests need.
  -- There does not seem to be a way to download pre-built parsers for any arbitrary language, and
  -- compiling each parser is not practical due to the amount of languages.
  local install_dir = vim.fs.joinpath(vim.fn.getcwd(), "deps", "parsers")
  require("nvim-treesitter").setup({
    install_dir = install_dir,
  })
  -- Set up `mini.test`.
  require("test").setup()
end
