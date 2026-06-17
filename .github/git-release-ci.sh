#!/usr/bin/env bash
set -euo pipefail

# Creates a GitHub release for a single Flutter SDK package.
# Flutter SDK is a monorepo of independently-versioned packages, so this is
# called once per published package (mindbox, mindbox_android, mindbox_ios,
# mindbox_platform_interface) with that package's tag/title.
#
# Usage: git-release-ci.sh <tag> <title> <branch>
tag="${1:?usage: git-release-ci.sh <tag> <title> <branch>}"
title="${2:?usage: git-release-ci.sh <tag> <title> <branch>}"
branch="${3:?usage: git-release-ci.sh <tag> <title> <branch>}"

notes="Auto-generated release. Check more details at [Mindbox Flutter SDK Documentation](https://developers.mindbox.ru/docs/flutter-sdk)"

# Idempotent: a re-run of a release must not fail on an already-published tag.
if gh release view "$tag" >/dev/null 2>&1; then
  echo "Release $tag already exists — skipping."
  exit 0
fi

echo "Creating release $tag on branch $branch"
gh release create "$tag" --target "$branch" --title "$title" --notes "$notes"
