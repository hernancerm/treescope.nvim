#!/usr/bin/env bash

## Record `demo.mp4` from `demo.tape`. Run from anywhere: `demo/record.sh`.

set -euo pipefail

demo="$(cd "$(dirname "$0")" && pwd -P)"
repo="$(dirname "${demo}")"

# `init.lua` takes the parsers from `make test`. Without one, its scope is just empty on camera.
for lang in python typescript java yaml markdown; do
  if [[ ! -f "${repo}/deps/parsers/parser/${lang}.so" ]]; then
    echo "missing the ${lang} parser, run \`make test\` once first" >&2
    exit 1
  fi
done

cd "${demo}"
vhs demo.tape
