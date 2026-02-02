# Memory Bank: `outer_function` (Neovim + Tree-sitter)

## Goal

Implement a Neovim Lua function:

```lua
outer_function() -> string | nil
```

that returns **the name of the outermost enclosing function/method** at the cursor position, using **Tree-sitter**.

* The return value is **only the function/method name** (no parameter list).
* If there is no enclosing function, return `nil`.
* The implementation is **language-agnostic at the walker level**, with **language-specific semantics** encapsulated in helper functions.
* Currently supported languages: **Lua** and **Java**.

---

## Core Algorithm (Language-Agnostic)

1. Determine the Tree-sitter language dynamically from the buffer filetype.
2. Get the Tree-sitter node at the cursor position.
3. Walk **upwards through parent nodes**.
4. Each time a node qualifies as a “function” for the current language:

   * record it as `candidate`
5. Continue walking until the root.
6. Return the **last function seen** (the outermost one).

**Key rule:**

> “Outer function” = the *last* function encountered while walking upward from the cursor.

This rule is **shared by Lua and Java**.

---

## Why Parent-Walking (Not Queries)

* Tree-sitter queries are good at *finding nodes*, not at expressing:

  * “outermost ancestor”
  * “last enclosing construct”
* Parent-walking is:

  * universal across Tree-sitter grammars
  * fast (tree height)
  * robust to grammar changes
* Queries were explored but rejected for this problem.

---

## What “Outer Function” Means (Semantics)

### General Definition

Given a cursor position:

* Walk up the syntax tree.
* Every time you encounter a function/method node, remember it.
* The **outer function** is the *highest* function node that still encloses the cursor.
* Nested functions do **not** override outer ones.

This is **syntactic**, not semantic or runtime scope.

---

## Lua Semantics

### What Counts as a Function

Lua Tree-sitter nodes:

* `function_declaration`

  ```lua
  function foo(x) end
  function M.foo(x) end
  ```
* `function_definition`

  ```lua
  foo = function(x) end
  M.foo = function(x) end
  ```

### How the Name Is Extracted

* `function_declaration`

  * name comes from `name` field
* `function_definition`

  * name comes from the **left-hand side of the enclosing assignment**
  * requires walking:

    ```
    function_definition
      → expression_list
        → assignment_statement
          → variable_list
            → identifier | dot_index_expression
    ```

⚠️ Important Tree-sitter Lua details:

* `variable_list` is **not a field**, it is a positional child.
* `function_definition` is **not a direct child** of `assignment_statement`.

### Lua Example

```lua
M.buffer_lines = function(opts)
  local contents = function(cb)
    local function add_entry(x, co)
      print("hi")
    end
  end
end
```

Cursor at `print("hi")`:

* Functions encountered (bottom → top):

  * `add_entry`
  * `contents`
  * `M.buffer_lines`

✅ Returned value:

```
M.buffer_lines
```

---

## Java Semantics (Final, Corrected Model)

### What Counts as a Function

Java Tree-sitter nodes:

* `method_declaration`
* `constructor_declaration`

Lambdas, static initializers, etc. are **not included**.

---

## Key Java Design Decision (Very Important)

❌ **Rejected approach**
“Toplevel = belongs to the type matching the file name”

✅ **Final rule (same as Lua):**

> The outermost enclosing method is the **last method encountered while walking upward from the cursor**, regardless of which class, enum, interface, or record it belongs to.

This rule:

* matches the Lua semantics
* handles nested types naturally
* reflects how Java code is structured syntactically

---

## Java Example: Nested Types

```java
public record GitRemote(
        Platform platform,
        String repositoryName,
        String ownerName) {

    public enum Platform {
        BITBUCKET_ORG,
        GITHUB_COM;

        public static Platform from(String host) {
            return switch (host) {
                case "bitbucket.org" -> BITBUCKET_ORG;
                case "github.com" -> GITHUB_COM;
                default -> null;
            };
        }
    }
}
```

Cursor at:

```java
default -> null;
```

Ancestor chain includes:

```
switch_expression
→ block
→ method_declaration (from)
→ enum_declaration
→ record_declaration
→ source_file
```

Only one method encountered.

✅ Returned value:

```
from
```

---

## Java Example: Multiple Enclosing Methods

```java
class Outer {
  void a() {
    class Inner {
      void b() {
        System.out.println("hi");
      }
    }
  }
}
```

Cursor inside `println`:

* Functions encountered:

  * `b`
  * `a`

✅ Returned value:

```
a
```

(`a` is the **outermost** enclosing method)

---

## Dynamic Language Handling

The Tree-sitter parser language and language-specific logic are handled dynamically.

1.  **Provider Discovery**: The `treescope.provider_locator` module identifies and loads the appropriate provider based on the buffer's `filetype`. Providers are located in `lua/treescope/providers/`.
2.  **Parser Initialization**:
    ```lua
    local lang = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype)
    local parser = vim.treesitter.get_parser(bufnr, lang)
    ```

Language-specific behavior is encapsulated in a `Provider` interface:

* `is_function(node) -> boolean`
* `get_function_name(node, bufnr) -> string?`

---

## Responsibility Split

### Shared (Language-Agnostic) - `lua/treescope/init.lua`

* Provider lookup via `provider_locator`.
* Cursor → Tree-sitter node resolution.
* Parent-walking algorithm: iterate to root, keep the **last** valid function node.
* Integration: `treescope.setup()` sets an autocmd on `CursorMoved` to update the `treescope_outer_function` buffer variable.

### Language-Specific - `lua/treescope/providers/*.lua`

* Definition of node types that qualify as "functions".
* Logic for extracting the name (handling field names, positional children, or complex assignments).

---

## Final Mental Model (Invariant)

* Tree-sitter is **syntactic**
* “Outer function” means:

  * *structurally outer*, not semantically “main”
* Same walker algorithm for all languages
* Only the function predicate and name extraction differ

---

## Explicit Non-Goals

* No semantic analysis
* No runtime scope resolution
* No overload disambiguation
* No lambda support (Java)
* No anonymous Lua functions unless assigned

---

## Status

* Lua: ✔ fully working (handles `function_declaration` and assignments)
* Java: ✔ fully working (nested types supported)
* Algorithm: stable & refactored (redundant nesting checks removed)
* Design: consistent provider-based architecture

---

### ⚠️ Important Warning for Future Changes

* Do **not** reintroduce filename-based logic for Java
* Do **not** try to replace parent-walking with Tree-sitter queries
* The invariant is: **walk upward, last function wins**
