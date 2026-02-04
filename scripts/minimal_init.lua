-- See: <https://github.com/echasnovski/mini.nvim/blob/main/TESTING.md>.

-- Add current directory to 'runtimepath' to be able to use 'lua' files.
vim.cmd([[let &rtp.=",".getcwd()]])

-- Set up `mini.test` only when calling headless Neovim (like with `make test`).
if #vim.api.nvim_list_uis() == 0 then
  -- Add `deps` dir to 'runtimepath' to be able to use `test.lua` and nvim-treesitter.
  vim.cmd([[let &rtp.=",".getcwd()."/deps"]])

  -- Bootstrap nvim-treesitter for parser management
  local install_dir = vim.fs.joinpath(vim.fn.getcwd(), "deps", "parsers")
  require("nvim-treesitter").setup({
    install_dir = install_dir,
  })

  -- Set up `mini.test`.
  require("test").setup()
end
