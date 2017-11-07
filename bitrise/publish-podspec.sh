#!/bin/bash

## I. Check parameter
if [ -z $1 ] || ( [ "$1" != "internal" ] && [ "$1" != "external" ] && [ "$1" != "test" ] ); then
  echo "Invalid parameter."
  echo "  Usage: $0 {internal|external|test}"
  exit 1
fi

## II. Get publish version for information
publish_version="$(grep "VERSION_STRING" $BITRISE_SOURCE_DIR/$VERSION_FILENAME | head -1 | awk -F "[= ]" '{print $4}')"
echo "Publishing podspec for version" $publish_version

if [ "$1" == "internal" ] || [ "$1" == "test" ]; then

  if [ "$1" == "internal" ]; then

    local_spec_repo_name=$GIT_SPEC_REPO_NAME

  else

    local_spec_repo_name=$VSTS_SPEC_REPO_NAME

    # Revert podspec change for other platforms
    git revert 8a6f317172421c84ef50a62675b3ba64aca53344

    # Add build number to podspec version
    sed "s/\(s\.version[[:space:]]*=[[:space:]]\)\'.*\'$/\1'$SDK_PUBLISH_VERSION'/1" AppCenter.podspec > AppCenter.podspec.tmp; mv AppCenter.podspec.tmp AppCenter.podspec

    # Change download URL in podspec
    sed "s/https:\/\/github\.com\/microsoft\/app-center-sdk-ios\/releases\/download\/#{s.version}\(\/AppCenter-SDK-Apple-\)\(\#{s.version}\)\(.zip\)/https:\/\/mobilecentersdkdev\.blob\.core\.windows\.net\/sdk\1\2+$BITRISE_GIT_COMMIT\3/1" AppCenter.podspec > AppCenter.podspec.tmp; mv AppCenter.podspec.tmp AppCenter.podspec

  fi

  ## 1. Get path of internal podspec local repo
  local_repo_path="$(pod repo | grep "$local_spec_repo_name" | grep Path | head -1 | awk -F ": " '{print $2}')"

  ## 2. Update podspec to the internal podspec local repo
  resp="$(pod repo push $local_spec_repo_name $BITRISE_SOURCE_DIR/$PODSPEC_FILENAME)"

  echo $resp

  # Check error from the response
  error="$(echo $resp | grep -i 'error\|fatal')"
  if [ "$error" ]; then
    echo "Cannot publish to internal repo"
    exit 1
  fi

  ## 3. Push podspec to the internal podspec remote repo
  cd $local_repo_path
  git push
  cd $BITRISE_SOURCE_DIR

  echo "Podspec published to $1 repo successfully"

else

  ## 1. Run lint to validate podspec.
  resp="$(pod spec lint $BITRISE_SOURCE_DIR/$PODSPEC_FILENAME)"
  echo $resp

  # Check error from the response
  error="$(echo $resp | grep -i 'error\|fatal')"
  if [ "$error" ]; then
    echo "Cannot publish to CocoaPods due to spec validation failure"
    exit 1
  fi

  ## 2. Push podspec to CocoaPods
  resp="$(pod trunk push $BITRISE_SOURCE_DIR/$PODSPEC_FILENAME)"
  echo $resp

  # Check error from the response
  error="$(echo $resp | grep -i 'error\|fatal')"
  if [ "$error" ]; then
    echo "Cannot publish to CocoaPods"
    exit 1
  fi

  echo "Podspec published to CocoaPods successfully"

fi
