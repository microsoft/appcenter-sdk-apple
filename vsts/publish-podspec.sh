#!/bin/bash

help() {
  echo "Usage: $0 {internal|external|test} -a <podspec-repo-user-account> -t <podspec-repo-access-token> -r <podspec-repo-name>"
}

## I. Check parameter
if [ -z $1 ] || ( [ "$1" != "internal" ] && [ "$1" != "external" ] && [ "$1" != "test" ] ); then
  help
  exit 1
fi

mode=$1
shift
user_account=""
access_token=""
repo_name=""
while getopts 'a:t:r:' flag; do
  case "${flag}" in
    a)
      user_account=${OPTARG}
      ;;
    t)
      access_token=${OPTARG}
      ;;
    r)
      repo_name=${OPTARG}
      ;;
    *)
      help
      exit 1
      ;;
  esac
done

if [ "$mode" != "external" ] && ( [ "$user_account" == "" ] || [ "$access_token" == "" ] || [ "$repo_name" == "" ] ); then
  help
  exit 1
fi

## II. Add private pod spec repo

if [ "$mode" == "test" ]; then
  resp="$(pod repo add $repo_name https://$user_account:$access_token@msmobilecenter.visualstudio.com/SDK/_git/$repo_name)"
elif [ "$mode" == "external" ]; then
  ## No ops for external option since this option will use public pod repo.
  resp=""
else
  resp="$(pod repo add $repo_name https://$user_account:$access_token@github.com/$GITHUB_ORG_NAME/$repo_name.git)"
fi

error="$(echo $resp | grep -i 'error\|fatal')"
if [ "$error" ]; then
  echo "Couldn't add private spec repo for $mode"
  exit 1
fi

## III. Get publish version for information
publish_version="$(grep "VERSION_STRING" $VERSION_FILENAME | head -1 | awk -F "[= ]" '{print $4}')"
echo "Publishing podspec for version" $publish_version

if [ "$mode" == "internal" ] || [ "$mode" == "test" ]; then

  if [ "$mode" == "test" ]; then

    # Update podspec change for other platforms
    sed -i '' 's/App\ Center\ Analytics\ (iOS\ and\ macOS)/App\ Center\ Analytics\ (iOS,\ macOS\ and\ tvOS)/g' $PODSPEC_FILENAME
    sed -i '' 's/App\ Center\ Crashes\ (iOS\ and\ macOS)/App\ Center\ Crashes\ (iOS,\ macOS\ and\ tvOS)/g' $PODSPEC_FILENAME
    sed -i '' '34 i\
      \ \ s.tvos.deployment_target = '\''10.0'\''\
      ' $PODSPEC_FILENAME
    sed -i '' '46 i\
      \ \ \ \ ss.tvos.frameworks = '\''UIKit'\''\
      ' $PODSPEC_FILENAME
    sed -i '' '49 i\
      \ \ \ \ ss.tvos.vendored_frameworks = '\"'AppCenter-SDK-Apple/tvOS/AppCenter.framework'\"'\
      ' $PODSPEC_FILENAME
    sed -i '' '58 i\
      \ \ \ \ ss.tvos.frameworks = '\''UIKit'\''\
      ' $PODSPEC_FILENAME
    sed -i '' '61 i\
      \ \ \ \ ss.tvos.vendored_frameworks = '\"'AppCenter-SDK-Apple/tvOS/AppCenterAnalytics.framework'\"'\
      ' $PODSPEC_FILENAME
    sed -i '' '70 i\
      \ \ \ \ ss.tvos.vendored_frameworks = '\"'AppCenter-SDK-Apple/tvOS/AppCenterCrashes.framework'\"'\
      ' $PODSPEC_FILENAME
    sed -i '' 's/Not\ available\ for\ macOS/Not\ available\ for\ macOS\ and\ tvOS/g' README.md
    sed -i '' 's/\(\*\*App\ Center\ Push\*\*\)\(.*\)/\1\2\ **Not available\ for\ tvOS*./g' README.md

    # Add build number to podspec version
    sed -i '' "s/\(s\.version[[:space:]]*=[[:space:]]\)\'.*\'$/\1'$SDK_PUBLISH_VERSION'/1" $PODSPEC_FILENAME

    # Change download URL in podspec
    sed -i '' "s/https:\/\/github\.com\/microsoft\/AppCenter-SDK-Apple\/releases\/download\/#{s.version}\(\/AppCenter-SDK-Apple-\)\(\#{s.version}\)\(.zip\)/https:\/\/mobilecentersdkdev\.blob\.core\.windows\.net\/sdk\1\2+$BUILD_SOURCEVERSION\3/1" $PODSPEC_FILENAME

  fi

  ## 1. Get path of internal podspec local repo
  repo_path="$(pod repo | grep "$repo_name" | grep Path | head -1 | awk -F ": " '{print $2}')"

  ## 2. Update podspec to the internal podspec local repo
  resp="$(pod repo push $repo_name $PODSPEC_FILENAME)"

  echo $resp

  # Check error from the response
  error="$(echo $resp | grep -i 'error\|fatal')"
  if [ "$error" ]; then
    echo "Cannot publish to internal repo"
    exit 1
  fi

  ## 3. Push podspec to the internal podspec remote repo
  cd $repo_path
  git push
  cd $BITRISE_SOURCE_DIR

  echo "Podspec published to $mode repo successfully"

else

  ## 1. Run lint to validate podspec.
  resp="$(pod spec lint $PODSPEC_FILENAME)"
  echo $resp

  # Check error from the response
  error="$(echo $resp | grep -i 'error\|fatal')"
  if [ "$error" ]; then
    echo "Cannot publish to CocoaPods due to spec validation failure"
    exit 1
  fi

  ## 2. Push podspec to CocoaPods
  resp="$(pod trunk push $PODSPEC_FILENAME)"
  echo $resp

  # Check error from the response
  error="$(echo $resp | grep -i 'error\|fatal')"
  if [ "$error" ]; then
    echo "Cannot publish to CocoaPods"
    exit 1
  fi

  echo "Podspec published to CocoaPods successfully"

fi
