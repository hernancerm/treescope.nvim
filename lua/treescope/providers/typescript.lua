-- TypeScript reuses the JavaScript provider because function_declaration,
-- arrow_function, and function_expression node types are identical; type
-- annotations are separate Tree-sitter nodes.
return require("treescope.providers.javascript")
