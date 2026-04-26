You are helping craft a Tree-sitter query for the `outermost_function` scope in treescope.nvim for the filetype: **$ARGUMENTS**.

## Step 1 — Read the provider

Read `lua/treescope/providers/outermost_function/$ARGUMENTS.lua` and understand:
- Which node types `is_function()` considers a function/method.
- How `get_function_name()` extracts the name (which named field holds the identifier).

## Step 2 — Gather inputs from the user

Ask the user for the following, all in one message:

1. **Reference code** — paste the code directly, or give a file path you can read.
2. **Tree-sitter tree** — the full tree for that reference code (they can get it with `:InspectTree` in Neovim or `nvim-treesitter`'s playground).
3. *(Optional)* **Starter query** — a partial query that already works for some cases, plus an explanation of what it still gets wrong (e.g., "also matches nested lambdas").
4. *(Optional)* **Screenshot** — an image of `:InspectTree` showing how the starter query currently matches in the source buffer. Use this to visually confirm which captures are highlighted and identify the unwanted matches.

Wait for the user's reply before continuing.

## Step 3 — Craft the query

Using the provider logic and the tree structure, write a Tree-sitter query that:
- Captures the name node of every outermost function with `@treescope_outermost_function`.
- Matches *exactly* the node types that `is_function()` accepts.
- Uses **structural parent constraints** (not `#has-ancestor?` / `#not-has-ancestor?` predicates) to exclude function nodes that are nested inside another function node.
- If a starter query was provided, builds on it and fixes the reported gaps.

## Step 4 — Explain

For each pattern in the query, briefly explain why the structural constraint correctly excludes nested cases for this language.
