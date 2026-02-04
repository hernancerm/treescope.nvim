-- See: <https://github.com/echasnovski/mini.nvim/blob/main/TESTING.md>.

-- Add cwd to 'runtimepath' to be able to use 'lua' files of the cwd.
-- Purpose: mini.test child Neovim instances can:
-- - `require("treescope")`
vim.cmd([[let &rtp.=",".getcwd()]])

-- Set up for headless Neovim. Intended for `make test`.
-- Purpose: mini.test child Neovim instances can:
-- - `require("nvim-treesitter")`
-- - `require("test")`
if #vim.api.nvim_list_uis() == 0 then
  -- Add `deps` dir to 'runtimepath' to be able to use `test.lua` and `nvim-treesitter`.
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
