# Demo

The video at the top of the main README is recorded from `demo.tape` with
[VHS](https://github.com/charmbracelet/vhs).

## Record

Install VHS once (it pulls in `ttyd` and `ffmpeg`):

```sh
brew install vhs
```

Run `make test` once, for the Tree-sitter parsers. Then, from anywhere:

```sh
demo/record.sh
```

It writes `demo/demo.mp4` in about 45s. The mp4 is git-ignored.

## Publish

GitHub only plays a README video uploaded through its website, not an mp4 in the repo:

1. On github.com, edit `README.md` and drag `demo/demo.mp4` into the editor.
2. GitHub replaces it with a `https://github.com/user-attachments/assets/...` URL.
3. Put that URL on its own line, below the one-line description, replacing the old one.

## Edit

- `demo.tape`: the steps. See the [VHS docs](https://github.com/charmbracelet/vhs#vhs-command-reference).
- `init.lua`: loaded on top of `nvim --clean`: treescope, the parsers and the statusline.
- `files/`: the files opened in the demo. The tape moves the cursor with `/search`, so renaming a
  searched word means updating its line in `demo.tape`.
