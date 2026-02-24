-- JSONC reuses the JSON provider; node types are identical (JSONC only adds
-- comment nodes, which the provider already handles).
return require("treescope.providers.yq_path.json")
