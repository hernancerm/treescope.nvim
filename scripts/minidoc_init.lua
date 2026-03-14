-- Intended use cases of this file:
-- - `make docs`: For headless Neovim instance to generate Vim help file(s).

-- Set up for headless Neovim. Intended for `make docs`.
-- Why `nvim_list_uis` condition: Headless Neovim instances (like the one spawned with `make`) use
-- the `mini.doc` file (`doc.lua`) from the `deps` dir, while non-headless Neovim instances (like
-- when user uses Neovim as usual) have access to whatever version of `mini.doc` they have
-- installed.
if #vim.api.nvim_list_uis() == 0 then
  -- Add `deps` to 'runtimepath' to be able to use `test.lua`.
  vim.cmd("set rtp+=deps")
  -- Set up `mini.doc`.
  local mini_doc = require("doc");
  mini_doc.setup()
  -- Generate help file(s).
  -- This generation depends on `./scripts/minidoc.lua`.
  mini_doc.generate()
  vim.cmd("qall!")
end


