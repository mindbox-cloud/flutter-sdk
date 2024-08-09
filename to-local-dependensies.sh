#!/bin/bash

# Add changelog to the index and create a commit
common_yaml="mindbox/pubspec.yaml"
current_version=$(grep -E '^version: ' "$common_yaml" | cut -d':' -f2)

# Update mindbox_android dependency
if ! grep -q "path: '../mindbox_android'" "$common_yaml"; then
  sed -i '' "s/  mindbox_android:.*/  mindbox_android:\n    path: '..\/mindbox_android'/" $common_yaml
fi

# Update mindbox_ios dependency
if ! grep -q "path: \"..\/mindbox_ios\"" "$common_yaml"; then
  sed -i '' "s/  mindbox_ios:.*/  mindbox_ios:\n    path: \"..\/mindbox_ios\"/" $common_yaml
fi

# Update mindbox_platform_interface dependency in common yaml
if ! grep -q "path: \"..\/mindbox_platform_interface\"" "$common_yaml"; then
  sed -i '' "s/  mindbox_platform_interface:.*/  mindbox_platform_interface:\n    path: \"..\/mindbox_platform_interface\" /" $common_yaml
fi

android_yaml="mindbox_android/pubspec.yaml"
# Update mindbox_platform_interface dependency in android yaml
if ! grep -q "path: \"..\/mindbox_platform_interface\"" "$android_yaml"; then
  sed -i '' "s/  mindbox_platform_interface:.*/  mindbox_platform_interface:\n    path: \"..\/mindbox_platform_interface\" /" $android_yaml
fi

ios_yaml="mindbox_ios/pubspec.yaml"
# Update mindbox_platform_interface dependency in ios yaml
if ! grep -q "path: \"..\/mindbox_platform_interface\"" "$ios_yaml"; then
  sed -i '' "s/  mindbox_platform_interface:.*/  mindbox_platform_interface:\n    path: \"..\/mindbox_platform_interface\" /" $ios_yaml
fi

echo 'Local dependencies updated'
