#!/bin/bash

# Check the current Git branch
current_branch=$(git symbolic-ref --short HEAD)

#if [[ $current_branch != "develop" && ! $current_branch =~ ^release/[0-9]+\.[0-9]+\.[0-9]+(-rc)?$ ]]; then
#  echo "The current Git branch ($current_branch) is not 'develop' or in the format 'release/X.Y.Z' or 'release/X.Y.Z-rc'."
#  exit 1
#fi

# Check if the parameter is provided
read -p "Flutter SDK release version: " version

# Check if the version number matches the semver format
if ! [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+(-rc)?$ ]]; then
  echo "The release version number does not match the semver format (X.Y.Z or X.Y.Z-rc)."
  exit 1
fi

# Create a branch with the version name
branch_name="release/$version"
#git branch $branch_name
#git checkout $branch_name

echo "Branch $branch_name has been created."

# Add changelog to the index and create a commit
common_yaml="mindbox/pubspec.yaml"
current_version=$(grep -E '^version: ' "$common_yaml" | cut -d':' -f2)

sed -i '' "s/^version: .*/version: $version/" $common_yaml
sed -i '' "s/  mindbox_android:.*/  mindbox_android: $version/" $common_yaml
sed -i '' "s/  mindbox_ios:.*/  mindbox_ios: $version/" $common_yaml
sed -i '' "s/  mindbox_platform_interface:.*/  mindbox_platform_interface: $version/" $common_yaml

android_yaml="mindbox_android/pubspec.yaml"
sed -i '' "s/^version: .*/version: $version/" $android_yaml
sed -i '' "s/  mindbox_platform_interface:.*/  mindbox_platform_interface: $version/" $android_yaml

ios_yaml="mindbox_ios/pubspec.yaml"
sed -i '' "s/^version: .*/version: $version/" $ios_yaml
sed -i '' "s/  mindbox_platform_interface:.*/  mindbox_platform_interface: $version/" $ios_yaml

platform_yaml="mindbox_platform_interface/pubspec.yaml"
sed -i '' "s/^version: .*/version: $version/" $platform_yaml

echo "Bump SDK version from $current_version to $version."

git add $platform_yaml
#git add $ios_podspec
git add $ios_yaml
#git add $android_gradle
git add $android_yaml
git add $common_yaml

read -p "Android SDK version: " android_sdk_version

# Check if the version number matches the semver format
if ! [[ $android_sdk_version =~ ^[0-9]+\.[0-9]+\.[0-9]+(-rc)?$ ]]; then
  echo "The Android SDK version number does not match the semver format (X.Y.Z or X.Y.Z-rc)."
  exit 1
fi

read -p "iOS SDK version: " ios_sdk_version

# Check if the version number matches the semver format
if ! [[ $ios_sdk_version =~ ^[0-9]+\.[0-9]+\.[0-9]+(-rc)?$ ]]; then
  echo "The iOS SDK version number does not match the semver format (X.Y.Z or X.Y.Z-rc)."
  exit 1
fi

android_gradle="mindbox_android/android/build.gradle"
sed -i '' "s/    api 'cloud.mindbox:mobile-sdk:.*/    api 'cloud.mindbox:mobile-sdk:$android_sdk_version\'/" $android_gradle
sed -i '' "s/    api 'cloud.mindbox:mindbox-firebase:.*/    api 'cloud.mindbox:mindbox-firebase:$android_sdk_version\'/" $android_gradle
sed -i '' "s/    api 'cloud.mindbox:mindbox-huawei:.*/    api 'cloud.mindbox:mindbox-huawei:$android_sdk_version\'/" $android_gradle

echo "Bump $android_gradle to $android_sdk_version"

ios_podspec="mindbox_ios/ios/mindbox_ios.podspec"

sed -i '' "s/  s.version          = .*/  s.version          = '$ios_sdk_version'/" $ios_podspec
sed -i '' "s/  s.dependency 'Mindbox', .*/  s.dependency 'Mindbox', '$ios_sdk_version'/" $ios_podspec
sed -i '' "s/  s.dependency 'MindboxNotifications', .*/  s.dependency 'MindboxNotifications', '$ios_sdk_version'/" $ios_podspec

echo "Bump $ios_podspec to $ios_sdk_version"

mindbox_ios_changelog="mindbox_ios/CHANGELOG.md"
mindbox_android_changelog="mindbox_android/CHANGELOG.md"
mindbox_changelog="mindbox/CHANGELOG.md"
mindbox_platform_changelog="mindbox_platform_interface/CHANGELOG.md"

changelog="## $version\n\n"
changelog_ios="* Upgrade native iOS SDK dependency to v$ios_sdk_version."
changelog_android="* Upgrade native Android SDK dependency to v$android_sdk_version."

echo -e "${changelog}${changelog_ios}\n\n$(cat $mindbox_ios_changelog)" > $mindbox_ios_changelog
echo -e "${changelog}${changelog_android}\n\n$(cat $mindbox_android_changelog)" > $mindbox_android_changelog
echo -e "${changelog}${changelog_android}\n${changelog_ios}\n\n$(cat $mindbox_platform_changelog)" > $mindbox_platform_changelog
echo -e "${changelog}${changelog_android}\n${changelog_ios}\n\n$(cat $mindbox_changelog)" > $mindbox_changelog

git add $ios_podspec
git add $android_gradle
git add $mindbox_ios_changelog
git add $mindbox_android_changelog
git add $mindbox_changelog
git add $mindbox_platform_changelog

git commit -m "Bump SDK version to $version"