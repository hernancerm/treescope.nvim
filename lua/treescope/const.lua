return {
  AUGROUP_NAME = "Treescope",
  ---@enum const.LanguageIds
  LanguageId = {
    LUA = "lua",
    JAVA = "java",
    PYTHON = "python",
    CLOJURE = "clojure",
    JAVASCRIPT = "javascript",
    TYPESCRIPT = "typescript",
    YAML = "yaml",
  },
  ---@enum const.ScopeIds
  ScopeIds = {
    OUTER_FUNCTION = "outer_function",
    CLOJURE_NAMESPACE = "clojure_namespace",
    YAML_PATH = "yaml_path",
  },
}
