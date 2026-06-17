#!/usr/bin/env bash
set -euo pipefail
VERSION="${1:?usage: version-update.sh <version>}"
sed -i -e "s|mindbox: ^[0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\}|mindbox: ^${VERSION}|" README.md