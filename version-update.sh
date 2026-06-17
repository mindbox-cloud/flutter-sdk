#!/usr/bin/env bash
set -euo pipefail
VERSION="${1:?usage: version-update.sh <version>}"
sed -i -e "s|mindbox: ^[0-9].[0-9].[0-9]|mindbox: ^${VERSION}|" README.md