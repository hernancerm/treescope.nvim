-- Loaded by `demo.tape` on top of `nvim --clean`, so the demo is stock Neovim plus treescope.

local repo = vim.fs.dirname(
  vim.fs.dirname(vim.fs.abspath(debug.getinfo(1, "S").source:sub(2)))
)
vim.opt.rtp:prepend(repo)
-- Stock Neovim ships few parsers (e.g. no python). These are the ones `make test` installs.
vim.opt.rtp:append(vim.fs.joinpath(repo, "deps", "parsers"))

require("treescope").setup({ buf_vars = { "function" } })

-- The stock statusline, with the function right before the ruler.
vim.o.statusline =
  vim.o.statusline:gsub("%%=", "%%=%%{get(b:,'treescope_function','')}  ", 1)
