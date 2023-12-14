#!/bin/bash

# Check if the parameter is provided
if [ $# -eq 0 ]; then
  echo "Please provide the release version number as a parameter."
  exit 1
fi

# Check if the version number matches the semver format
if ! [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+(-rc)?$ ]]; then
  echo "The release version number does not match the semver format (X.Y.Z or X.Y.Z-rc)."
  exit 1
fi

# Check the current Git branch
current_branch=$(git symbolic-ref --short HEAD)

if [[ $current_branch != "develop" && ! $current_branch =~ ^release/[0-9]+\.[0-9]+\.[0-9]+(-rc)?$ ]]; then
  echo "The current Git branch ($current_branch) is not 'develop' or in the format 'release/X.Y.Z' or 'release/X.Y.Z-rc'."
  exit 1
fi

# Create a branch with the version name
version=$1
branch_name="release/$version"
git branch $branch_name
git checkout $branch_name

# Add changelog to the index and create a commit
common_yaml="mindbox/pubspec.yaml"
current_version=$(grep -E '^version: ' "$common_yaml" | cut -d':' -f2)

sed -i '' "s/^version: .*/version: $version/" $common_yaml
sed -i '' "s/  mindbox_android:.*/  mindbox_android: \^$version/" $common_yaml
sed -i '' "s/  mindbox_ios:.*/  mindbox_ios: \^$version/" $common_yaml
sed -i '' "s/  mindbox_platform_interface:.*/  mindbox_platform_interface: \^$version/" $common_yaml

android_yaml="mindbox_android/pubspec.yaml"
sed -i '' "s/^version: .*/version: $version/" $android_yaml
sed -i '' "s/  mindbox_platform_interface:.*/  mindbox_platform_interface: \^$version/" $android_yaml

android_gradle="mindbox_android/android/build.gradle"
sed -i '' "s/  implementation 'cloud.mindbox:mobile-sdk:.*/  implementation 'cloud.mindbox:mobile-sdk:$version\'/" $android_gradle

ios_yaml="mindbox_ios/pubspec.yaml"
sed -i '' "s/^version: .*/version: $version/" $ios_yaml
sed -i '' "s/  mindbox_platform_interface:.*/  mindbox_platform_interface: \^$version/" $ios_yaml

ios_podspec="mindbox_ios/ios/mindbox_ios.podspec"

sed -i '' "s/  s.version          = .*/  s.version          = '$version'/" $ios_podspec
sed -i '' "s/  s.dependency 'Mindbox', .*/  s.dependency 'Mindbox', '$version'/" $ios_podspec
sed -i '' "s/  s.dependency 'MindboxNotifications', .*/  s.dependency 'MindboxNotifications', '$version'/" $ios_podspec

platform_yaml="mindbox_platform_interface/pubspec.yaml"
sed -i '' "s/^version: .*/version: $version/" $platform_yaml

echo "Bump SDK version from $current_version to $version."

git add $platform_yaml
git add $ios_podspec
git add $ios_yaml
git add $android_gradle
git add $android_yaml
git add $common_yaml

git commit -m "Bump SDK version to $version"

$mindbox_ios_changelog = "mindbox_ios/CHANGELOG.md"
$mindbox_android_changelog = "mindbox_android/CHANGELOG.md"
$mindbox_changelog = "mindbox/CHANGELOG.md"
$mindbox_platform_changelog = "mindbox_platform_interface/CHANGELOG.md"

$changelog = "## $version\n\n* Upgrade native SDK dependency to v$version.\n\n"

echo -e "$changelog$(cat $mindbox_ios_changelog)" > $mindbox_ios_changelog
echo -e "$changelog$(cat $mindbox_android_changelog)" > $mindbox_android_changelog
echo -e "$changelog$(cat $mindbox_platform_changelog)" > $mindbox_platform_changelog
echo -e "$changelog$(cat $mindbox_changelog)" > $mindbox_changelog

echo "Branch $branch_name has been created."