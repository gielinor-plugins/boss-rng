#!/bin/sh
# Builds the zip to upload to mod.io: dist/boss_rng-<version>.zip
# Only the files the game needs are included. Docs, tools and tests are left out.

set -eu

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

version="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' plugin.json)"
out="dist/boss_rng-$version.zip"

mkdir -p dist
rm -f "$out"

files="main.lua plugin.json src"
if [ -d resources ]; then
    files="$files resources"
fi
# shellcheck disable=SC2086
zip -r -X "$out" $files -x "*.DS_Store"

echo "Built $out"
