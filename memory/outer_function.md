# Memory Bank: outer_function (Neovim + Tree-sitter)

## Goal
Implement `outer_function() -> string | nil` returning the name of the outermost enclosing function/method at the cursor position using Tree-sitter.

- Return only the function/method name (no parameter list).
- Return nil if no enclosing function is found.
- The implementation must be language-agnostic at the walker level.
- Language-specific semantics are encapsulated in providers.
- Currently supported: Lua, Java, Python.

## Core Algorithm (Language-Agnostic)
1. Determine the Tree-sitter language from the buffer filetype.
2. Get the Tree-sitter node at the current cursor position.
3. Walk upwards through parent nodes until the root is reached.
4. Each time a node qualifies as a "function" for the current language, record it as the current `candidate`.
5. Return the name from the last function node encountered (the outermost one).

Key rule: Outer function = last function encountered while walking upward from the cursor.

## Why Parent-Walking (Not Queries)
- Universal: Works across different Tree-sitter grammars.
- Performance: O(tree height), which is very fast.
- Robust: Less sensitive to grammar changes than complex queries.
- Limitations of Queries: Tree-sitter queries excel at finding nodes but struggle to express "outermost ancestor" or "last enclosing construct" logic naturally.

## Semantics
The "outer function" is the highest function node in the syntax tree that still encloses the cursor. Nested functions do not override outer ones. This is a purely syntactic definition, not a semantic or runtime scope resolution.

## Language Semantics Reference

### Lua
- Nodes: `function_declaration`, `function_definition`.
- Name Extraction: 
    - For declarations, use the `name` field.
    - For definitions (assignments), walk up to the `assignment_statement` and locate the left-hand side identifier/expression.

### Java
- Nodes: `method_declaration`, `constructor_declaration`.
- Exclusions: Lambdas and static initializers are currently ignored.
- Rule: The outermost method is the last method encountered upward, regardless of whether it belongs to a nested class, enum, or record.

### Python
- Nodes: `function_definition`, `async_function_definition`.
- Name Extraction: Access the `name` field which points to the function's identifier.
- Note: Methods are `function_definition` nodes nested inside a `class_definition`; the algorithm correctly identifies them as functions.

## Project Structure
- `lua/treescope/init.lua`: Entry point; implements the shared walker logic.
- `lua/treescope/const.lua`: Shared enums (`ProviderIds`, `ScopeIds`) and constants.
- `lua/treescope/vars_service.lua`: Manages auto-updating buffer variables (`b:treescope_*`).
- `lua/treescope/provider_locator.lua`: Maps filetypes to provider modules and handles dynamic loading.
- `lua/treescope/provider_interface.lua`: Defines the interface for language providers.
- `lua/treescope/providers/`: Directory for language-specific logic (e.g., `lua.lua`, `java.lua`, `python.lua`).

## Dynamic Language Handling
1. Provider Discovery: `provider_locator` identifies the provider ID from `const.ProviderIds` based on filetype and loads the corresponding module from `lua/treescope/providers/`.
2. Parser Initialization: Uses `vim.treesitter.get_parser(bufnr, lang)` to handle the syntax tree.

Provider Interface Requirements:
- `is_function(node) -> boolean`: Predicate to identify function-like nodes.
- `get_function_name(node, bufnr) -> string?`: Logic to extract the display name from a node.

## Responsibility Split
- Shared (Global): Walker logic, cursor-to-node resolution, integration with Neovim (autocmds/vars), and provider discovery.
- Specific (Provider): Defining which node types count as functions and how to extract their names.

## Final Mental Model
- Tree-sitter logic is syntactic.
- "Outer" means structurally outermost in the file.
- The walker algorithm is invariant; only the function predicate and name extraction logic vary by language.

## Explicit Non-Goals
- No semantic analysis or runtime scope resolution.
- No overload disambiguation.
- No lambda support for Java.
- No anonymous Lua functions unless assigned to a variable.

## Invariants for Future Support
- Do not reintroduce filename-based logic for Java or similar languages.
- Do not replace parent-walking with Tree-sitter queries.
- The invariant is: walk upward, last function wins.
