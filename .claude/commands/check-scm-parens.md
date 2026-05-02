Check parenthesis balance in a Tree-sitter `.scm` query file.

File to check: **$ARGUMENTS**

Run the following Python snippet with the Bash tool:

```bash
python3 -c "
import sys
path = '$ARGUMENTS'
content = open(path).read()
lines = content.split('\n')

# Overall balance
opens = content.count('(')
closes = content.count(')')
print(f'Overall: {opens} opens, {closes} closes, diff={opens - closes}')
print()

# Split into pattern blocks: a block starts at any non-empty, non-comment line
# after a run of blank/comment-only lines.
blocks = []
block_lines = []
block_start = None

for i, line in enumerate(lines, 1):
    stripped = line.strip()
    is_blank_or_comment = stripped == '' or stripped.startswith(';')

    if not is_blank_or_comment:
        if block_start is None:
            block_start = i
        block_lines.append((i, line))
    else:
        if block_lines:
            blocks.append((block_start, block_lines))
            block_lines = []
            block_start = None

if block_lines:
    blocks.append((block_start, block_lines))

# Report any unbalanced block
any_bad = False
for start, blines in blocks:
    o = sum(l.count('(') for _, l in blines)
    c = sum(l.count(')') for _, l in blines)
    if o != c:
        any_bad = True
        end = blines[-1][0]
        print(f'UNBALANCED lines {start}-{end}: {o} opens, {c} closes (diff={o-c})')
        # Show running balance per line within the block
        depth = 0
        for lineno, l in blines:
            for ch in l:
                if ch == '(':
                    depth += 1
                elif ch == ')':
                    depth -= 1
            print(f'  line {lineno:4d} balance={depth:+d}  {l.rstrip()}')

if not any_bad:
    print('All pattern blocks are balanced.')
"
```

After running, report:
- Whether the file is balanced overall.
- For each unbalanced block: the line range, the open/close counts, and the per-line running balance (so the exact line where the imbalance accumulates is visible).
- What the correct close count should be (the same as the open count for that block).
