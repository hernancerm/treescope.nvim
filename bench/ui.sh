#!/bin/sh
# Time `get()` from the statusline in a real UI: Neovim runs in tmux while
# keys are sent one by one, like a person typing, so each key redraws.
# Usage: bench/ui.sh <file>
set -eu

if ! command -v tmux >/dev/null; then
  echo "tmux is required" >&2
  exit 1
fi

file=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
session=treescope-bench

# Own server and no config: the user's sessions stay untouched, and their
# config can't skew timings (e.g. `escape-time` delays `Escape`).
bench_tmux() {
  tmux -L treescope-bench -f /dev/null "$@"
}
trap 'bench_tmux kill-server 2>/dev/null || true; rm -rf "$tmp"' EXIT

wait_for() {
  i=0
  while [ ! -e "$1" ]; do
    i=$((i + 1))
    if [ $i -gt 100 ]; then
      echo "timed out waiting for $1" >&2
      exit 1
    fi
    sleep 0.1
  done
}

send() {
  bench_tmux send-keys -t $session "$@"
}

bench_tmux new-session -d -s $session -x 200 -y 50 \
  "BENCH_ROOT='$root' BENCH_OUT='$tmp/out' BENCH_READY='$tmp/ready' nvim -u '$root/bench/ui.lua' '$file'"
wait_for "$tmp/ready"

send 300G
send ':lua BenchPhase("move")' Enter
sleep 0.5
i=0
while [ $i -lt 200 ]; do
  send j
  sleep 0.02
  i=$((i + 1))
done
sleep 0.5

send ':lua BenchPhase("insert")' Enter o
i=0
while [ $i -lt 200 ]; do
  send -l x
  sleep 0.02
  i=$((i + 1))
done
send Escape
sleep 0.5

send ':lua BenchDump()' Enter
wait_for "$tmp/out"
echo "$(basename "$file")"
cat "$tmp/out"
