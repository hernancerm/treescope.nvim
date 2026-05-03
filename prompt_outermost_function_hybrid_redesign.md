outermost_function scope, currently there are tree-sitter queries so [m/]m can be enhanced, and also there are providers in lua so the outermost_function appears in the statusline. To support both use cases, just lua is not enough, just tree-sitter queries are also not good enough. A hybrid approach seems to be the best. Let's explore a hybrid approach with the goal of providing [m/]m navigation accurate to what is in the statusline (the lua providers) while keeping the simple depth-agnostic tree-sitter queries.

I have an idea of how this should work.

1. How to show the outermost function in the statusline? The current approach of tree-sitter tree walking through lua providers is the right approach, it's performant, accurate and handles so many edge cases for free (by the nature of tree-walking). This is the way. This is current functionality, keep it.

2. How to go to prev/next outermost function with [m/]m? This is the tricky part that needs to be reworked. Here is my solution: use the existent depth-agnostic tree-sitter queries in @queries/ to find all function matches in the file. Create a new public function in the API that when called does the exact same tree-walking from #1 but at the position of the immediate previous match according to the tree-sitter queries. So far no cursor movement. During this walk, the outermost function is identified, it might be the same function that was started on, or it might be a higer up one. The outermost function found is the target position for the cursor jump. So this approach needs to use both the queries and tree-walking.

Regarding #2, the "new public function in the API" will be 2 functions. The output of treescope.outer_function() will be redesigned to return this:

```lua
{
  text = "myfunction",
  goto_next = function() ... end, -- new function
  goto_prev = function() ... end, -- new function
}
```

After the changes, the current output would then be accessed through treescope.outer_function().text, while going to the prev/next, [m/]m, will be done through treescope.outermost_function():goto_prev() and treescope.outermost_function():goto_next(), respectively.

This solution proposal is a draft, but the core idea I think is right is a hybrid approach for use ase #2 ([m/]m). Let's discuss these questions before implementing the refactor:

1. Does the high level solution make sense to you? Concerns?
2. What is a good design for the API redesign for outermost_function? I want to keep the public functions of treescope limited to setup() and every other function should represent a scope, so I don't want functions like goto_next() which are not a scope themselves. Something I don't quite understand about my proposal is whether :goto_next() needs to use colon, and whether it's best to expose a method for jumping directly rather than to provider the next match.

Let's go one by one on these questions. First let's discuss question 1, then we'll go with 2. If you can create a todo list for these, create one so you remember to cover both questions. Discuss them with me. Start.
