# Recorded by `record.sh`. See https://github.com/charmbracelet/vhs.

Output demo.mp4

Set Shell zsh
Set Theme "GitHub Dark"
Set FontSize 20
Set Width 1400
Set Height 800
Set Padding 20
Set Margin 60
Set MarginFill "#20642f"
Set WindowBar Colorful
Set WindowBarSize 50
Set BorderRadius 20
Set TypingSpeed 50ms

# `-n` skips the swap file, so a leftover one never pops up a prompt.
Hide
Type "cd files && nvim --clean -n -u ../init.lua app.py cart.test.ts App.java config.yaml README.md"
Enter
Sleep 2s
Show

Sleep 1.5s

# Python: a method inside a class.
Type "/append"
Enter
Sleep 1s
Type ':=Treescope.get("class").text'
Enter
Sleep 2s
Type ':=Treescope.get("function").text'
Enter
Sleep 2.5s

# TypeScript: test callbacks are named by their title.
Type ":next"
Enter
Sleep 1.5s
Type "/apple"
Enter
Sleep 1s
# The prefix makes `Up` recall the "function" line from app.py.
Type ':=Treescope.get("f'
Sleep 0.5s
Up
Sleep 0.8s
Enter
Sleep 2s
Type ':=Treescope.get("function", { depth = "any" }).text'
Enter
Sleep 3s

# Java: the package.
Type ":next"
Enter
Sleep 1.5s
Type "/println"
Enter
Sleep 1s
Type ':=Treescope.get("namespace").text'
Enter
Sleep 2.5s

# YAML: a path to feed to yq.
Type ":next"
Enter
Sleep 1.5s
Type "/url"
Enter
Sleep 1s
Type ':=Treescope.get("yq_path").text'
Enter
Sleep 2.5s

# Markdown: the language of the code fence.
Type ":next"
Enter
Sleep 1.5s
Type "/cart.add"
Enter
Sleep 1s
Type ':=Treescope.get("code_fence").text'
Enter

Sleep 3s
