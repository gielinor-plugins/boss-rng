#!/bin/sh
# Copies the plugin into the beta client's dev_plugins folder for testing.
# Afterwards, run "prl boss_rng" in the game console.
#
# Override the target with BOSS_RNG_DEV_DIR if your client lives somewhere else.

set -eu

root="$(cd "$(dirname "$0")/.." && pwd)"
target="${BOSS_RNG_DEV_DIR:-$HOME/Jagex/RuneScape-BETA/dev_plugins/boss_rng}"

# Only ever replace a folder inside dev_plugins.
case "$target" in
    */dev_plugins/*) ;;
    *) echo "Refusing to copy into $target (not inside dev_plugins)" >&2; exit 1 ;;
esac

rm -rf "$target"
mkdir -p "$target"
cp "$root/main.lua" "$root/plugin.json" "$target/"
if [ -d "$root/src" ]; then
    cp -R "$root/src" "$target/"
fi
if [ -d "$root/resources" ]; then
    cp -R "$root/resources" "$target/"
fi
# Dev-only test bosses and probes. Gitignored and never packaged.
if [ -d "$root/dev" ]; then
    cp -R "$root/dev" "$target/"
fi

echo "Copied to $target"
