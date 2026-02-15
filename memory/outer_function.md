# Memory Bank: outer_function (Neovim + Tree-sitter)

## Goal
Implement `outer_function() -> string | nil` returning the name of the outermost enclosing function/method at the cursor position using Tree-sitter.

- Return only the function/method name (no parameter list).
- Return nil if no enclosing function is found.
- The implementation must be language-agnostic at the walker level.
- Language-specific semantics are encapsulated in providers.
- Currently supported: Lua, Java, Python, Clojure, JavaScript.

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
- Method Syntax: Supports Lua's object-oriented method syntax using the `:` operator.
    - Example: `function obj:method() end` returns `"obj:method"`.
    - Example: `function outer.inner:method() end` returns `"outer.inner:method"`.
- Identifier Support: Cursor-on-identifier positioning works for function and method names via `[jw]` key sequences in tests.
    - Identifiers in variable assignments are recognized as function contexts.

### Java
- Nodes: `method_declaration`, `constructor_declaration`.
- Name Extraction: Use the `name` field to extract the method/constructor name.
- Exclusions: Lambdas and static initializers are currently ignored.
- Rule: The outermost method is the last method encountered upward, regardless of whether it belongs to a nested class, enum, or record.
- Static Methods: Static methods (using `static` keyword) are properly recognized and return their method names.
- Nested Classes: Methods inside nested or anonymous inner classes are correctly identified.
- Nested Definitions: Methods containing nested function definitions (via anonymous inner classes) return the enclosing method name.
- Identifier Support: Cursor-on-identifier positioning works for method and constructor names.

### Python
- Nodes: `function_definition`, `async_function_definition`.
- Name Extraction: Access the `name` field which points to the function's identifier.
- Async Support: Both `async def` functions and async methods are fully supported.
- Decorated Functions: Methods with decorators (`@classmethod`, `@staticmethod`) are recognized and return their method names.
- Nested Definitions: Nested function definitions within methods return the enclosing method name.
- Identifier Support: Cursor-on-identifier positioning works for function and method names.
- Note: Methods are `function_definition` nodes nested inside a `class_definition`; the algorithm correctly identifies them as functions.

### Clojure
- Node Type: `list_lit` where the first child is a `sym_lit`.
- Explicit Macro List: The provider uses an **explicit list of supported macros** (`defn`, `deftest`) rather than pattern matching. Each macro is checked by name using `sym_text == "defn" or sym_text == "deftest"`.
  - Rationale: Conservative approach allowing precise control over which macros are recognized as functions. Future macros can be added individually with full understanding of their semantics.
  - Supported: `(defn name ...)` and `(deftest name ...)` patterns.
  - Name Extraction: Extract the second child (a `sym_lit`) which contains the function name.
  - Not Supported: `defmacro`, `defmulti`, `defprivate` (deferred for future consideration after semantic analysis).
- Limitation: Anonymous functions (`fn`) are not included unless assigned to a variable via `(def name (fn ...))`.
- Limitation: `def` with `(fn ...)` requires explicit verification that the third child is an `fn` form.

### JavaScript
- Nodes: `function_declaration`, `arrow_function`, `function_expression`.
- Name Extraction:
    - For declarations (`function foo() {}`): Use the `name` field.
    - For expressions (`const foo = () => {}` or `const foo = function() {}`): Walk up to parent `variable_declarator` and use its `name` field.
    - For identifier nodes (cursor on function name): Return the identifier text directly.
- Async Support: Both sync and async variants are supported (e.g., `async function foo() {}`, `const foo = async () => {}`).
- Identifier Support: Cursor-on-identifier positioning works for function names in assignments via identifier node handling.
- Limitation: Inline/anonymous arrow functions without assignment are ignored.

## Test Coverage

The implementation is comprehensively tested across all supported languages with end-to-end tests:

- **Lua** (`tests/resources/lua.lua`): 16 test cases
  - Basic functions: declarations, local declarations, assignments (with identifier cursor variants)
  - Nested functions: single-level and deeply nested (3 levels)
  - Method syntax: `function obj:method()` and `function outer.inner:method()` (with identifier cursor variants)
  - All tests pass ✅

- **Java** (`tests/resources/java.java`): 10 test cases
  - Constructors and instance methods (with identifier cursor variants)
  - Static methods, generic methods
  - Anonymous inner classes and named inner classes
  - Methods with nested function definitions
  - All tests pass ✅

- **Python** (`tests/resources/python.py`): 12 test cases
  - Function definitions and async functions
  - Nested functions (single-level and deeply nested)
  - Instance methods, async methods, class methods, static methods
  - Methods with nested function definitions
  - All tests pass ✅

- **Clojure** (`tests/resources/clojure.txt`): 9 test cases
  - `defn` declarations with nested functions
  - `def` with anonymous function assignments
  - `deftest` test functions (with identifier cursor variants)
  - All tests pass ✅

- **JavaScript / TypeScript** (`tests/resources/javascript.js`, `typescript.ts`): 12 test cases each
  - Function declarations and async functions
  - Arrow functions and function expressions (with identifier cursor variants)
  - Nested functions (single-level and deeply nested)
  - All tests pass ✅

**Total: 68 tests, all passing.** Test coverage focuses on important cases: basic declarations, nested functions, method variants, decorators, and cursor-on-identifier positioning.

## Project Structure
- `lua/treescope/init.lua`: Entry point; implements the shared walker logic.
- `lua/treescope/const.lua`: Shared enums (`ProviderIds`, `ScopeIds`) and constants.
- `lua/treescope/vars_service.lua`: Manages auto-updating buffer variables (`b:treescope_*`).
- `lua/treescope/provider_locator.lua`: Maps filetypes to provider modules and handles dynamic loading.
- `lua/treescope/provider_interface.lua`: Defines the interface for language providers.
- `lua/treescope/providers/`: Directory for language-specific logic (e.g., `lua.lua`, `java.lua`, `python.lua`, `clojure.lua`, `javascript.lua`).

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
