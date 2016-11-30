#!/bin/bash

## I. Get publish version for information
publish_version="$(grep "VERSION_STRING" $BITRISE_SOURCE_DIR/$VERSION_FILE | head -1 | awk -F "[= ]" '{print $4}')"
echo "Publishing podspec for version" $publish_version

## II. Get path of internal podspec local repo
local_repo_path="$(pod repo | grep "$GIT_SPEC_REPO_NAME" | grep Path | head -1 | awk -F ": " '{print $2}')"

## III. Update podspec to the internal podspec local repo
resp="$(pod repo push $GIT_SPEC_REPO_NAME $BITRISE_SOURCE_DIR/$PODSPEC_FILENAME --allow-warnings)"
echo $resp
error="$(echo $resp | grep -i error\|fatal)"
if [ "$error" ]; then
  echo "Cannot publish to private repo"
  exit 1
fi

## IV. Push podspec to the interanl podspec remote repo
cd $local_repo_path
git push
cd $BITRISE_SOURCE_DIR