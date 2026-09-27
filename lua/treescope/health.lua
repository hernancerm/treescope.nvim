local M = {}

function M.check()
  vim.health.start("treescope")
  if vim.fn.has("nvim-0.11") == 1 then
    vim.health.ok("Neovim >= 0.11")
  else
    vim.health.error("Neovim >= 0.11 is required")
  end

  vim.health.start("treescope: Tree-sitter parsers")
  -- Grouped by language, since one parser serves many scopes and filetypes.
  local users = {}
  local supported = require("treescope.provider_locator").get_supported()
  for scope_id, filetypes in pairs(supported) do
    for filetype, lang in pairs(filetypes) do
      users[lang] = users[lang] or {}
      table.insert(users[lang], scope_id .. " (" .. filetype .. ")")
    end
  end
  local langs = vim.tbl_keys(users)
  table.sort(langs)
  for _, lang in ipairs(langs) do
    table.sort(users[lang])
    local used_by = "Used by: " .. table.concat(users[lang], ", ")
    if not vim.treesitter.language.add(lang) then
      vim.health.warn(
        lang .. ": parser not found. " .. used_by,
        "Install the parser, e.g. with nvim-treesitter: `:TSInstall "
          .. lang
          .. "`"
      )
    else
      -- A parser too old or too new for the queries makes them fail to load,
      -- which would otherwise just look like an empty scope.
      local ok, err = pcall(vim.treesitter.query.get, lang, "treescope")
      if ok then
        vim.health.ok(lang .. ": parser found. " .. used_by)
      else
        vim.health.error(
          lang .. ": query failed to load: " .. tostring(err),
          "Update the parser, e.g. with nvim-treesitter: `:TSUpdate "
            .. lang
            .. "`"
        )
      end
    end
  end
end

return M
