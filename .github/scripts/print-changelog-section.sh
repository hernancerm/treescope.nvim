#!/usr/bin/env bash

# Prints the body of one version's section of CHANGELOG.md, without its heading.
# Used as the release notes.

set -euo pipefail

version="${1:?usage: print-changelog-section.sh <version>}"

awk -v version="${version}" '
  $0 ~ "^## \\[" version "\\]" { on = 1; next }
  on && /^## \[/ { exit }
  on { print }
' CHANGELOG.md | awk 'NF { blank = 0; body = 1 } !NF { blank++ } body { if (blank < 2) print }'
