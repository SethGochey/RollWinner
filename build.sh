#!/usr/bin/env bash
# Build a RollWinner release zip locally, and optionally install it into a WoW AddOns folder.
#
# Produces dist/RollWinner-<version>.zip containing a RollWinner/ folder, laid out the same
# way as the zips the BigWigs packager builds in GitHub Actions. Use it to test a build or
# to upload by hand to CurseForge, Wago or WoWInterface.
#
# Usage:
#   ./build.sh [-v <version>] [-a <AddOns path>]
#     -v  Version written into the TOC in place of @project-version@. Defaults to the latest git tag.
#     -a  When set, the built RollWinner folder is also copied into this AddOns folder.
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
version=""
addons=""
while getopts "v:a:" opt; do
  case "$opt" in
    v) version="$OPTARG" ;;
    a) addons="$OPTARG" ;;
    *) echo "usage: $0 [-v version] [-a AddOnsPath]" >&2; exit 1 ;;
  esac
done

if [[ -z "$version" ]]; then
  version="$(git -C "$root" describe --tags --always 2>/dev/null || echo dev)"
  version="${version#v}"
fi

# Files that make up the addon. Everything else in the repo stays out of the zip.
files=(RollWinner.toc RollWinner.lua README.md LICENSE)

dist="$root/dist"
stage="$dist/RollWinner"
rm -rf "$stage"
mkdir -p "$stage"
for f in "${files[@]}"; do cp "$root/$f" "$stage/$f"; done

sed -i '' "s/@project-version@/$version/g" "$stage/RollWinner.toc" 2>/dev/null \
  || sed -i "s/@project-version@/$version/g" "$stage/RollWinner.toc"

zip="$dist/RollWinner-$version.zip"
rm -f "$zip"
(cd "$dist" && zip -qrX "$zip" RollWinner)
echo "Built $zip"

if [[ -n "$addons" ]]; then
  mkdir -p "$addons/RollWinner"
  cp "$stage"/* "$addons/RollWinner/"
  echo "Installed to $addons/RollWinner"
fi
