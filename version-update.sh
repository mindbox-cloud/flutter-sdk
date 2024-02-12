#!/bin/bash
VERSION=$1
sed -i -e "s|mindbox: ^[0-9].[0-9].[0-9]|mindbox: ^${VERSION}|" README.md