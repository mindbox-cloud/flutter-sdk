#!/bin/bash

# Add changelog to the index and create a commit
common_yaml="mindbox/pubspec.yaml"
current_version=$(grep -E '^version: ' "$common_yaml" | cut -d':' -f2)

sed -i '' "s/  mindbox_android:.*/  mindbox_android:\n    path: '..\/mindbox_android'/" $common_yaml
sed -i '' "s/  mindbox_ios:.*/  mindbox_ios:\n    path: \"..\/mindbox_ios\"/" $common_yaml
sed -i '' "s/  mindbox_platform_interface:.*/  mindbox_platform_interface:\n    path: \"..\/mindbox_platform_interface\" /" $common_yaml

android_yaml="mindbox_android/pubspec.yaml"
sed -i '' "s/  mindbox_platform_interface:.*/  mindbox_platform_interface:\n    path: \"..\/mindbox_platform_interface\" /" $android_yaml

ios_yaml="mindbox_ios/pubspec.yaml"
sed -i '' "s/  mindbox_platform_interface:.*/  mindbox_platform_interface:\n    path: \"..\/mindbox_platform_interface\" /" $ios_yaml