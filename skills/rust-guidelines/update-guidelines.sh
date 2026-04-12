#!/usr/bin/env bash
# Refreshes guidelines.txt from Microsoft's Rust guidelines bundle.
# Strips the site header; kept content starts at the "# AI Guidelines" heading.
set -euo pipefail

URL="https://microsoft.github.io/rust-guidelines/agents/all.txt"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${SCRIPT_DIR}/guidelines.txt"

tmp_full="$(mktemp)"
tmp_body="$(mktemp)"
trap 'rm -f -- "$tmp_full" "$tmp_body"' EXIT

curl -fsSL "$URL" -o "$tmp_full"

awk '/^# AI Guidelines$/ { p = 1 } p' "$tmp_full" > "$tmp_body"

if [[ ! -s "$tmp_body" ]]; then
  echo "error: download empty or missing '# AI Guidelines' marker" >&2
  exit 1
fi

mv -f -- "$tmp_body" "$OUT"
trap - EXIT
rm -f -- "$tmp_full"

echo "Updated: $OUT ($(wc -l < "$OUT" | tr -d ' ') lines)"
