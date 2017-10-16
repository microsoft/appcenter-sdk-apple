#!/bin/bash

## I. Check parameter
if [ -z $1 ] || ( [ "$1" != "vsts" ] && [ "$1" != "github" ] ); then
  echo "Invalid parameter.";
  echo "  Usage: $0 {vsts|github}";
  exit 1;
fi

## II. Add private pod spec repo

if [ "$1" == "vsts" ]; then

  resp="$(pod repo add $VSTS_SPEC_REPO_NAME https://$VSTS_USER_ACCOUNT:$VSTS_ACCESS_TOKEN@msmobilecenter.visualstudio.com/SDK/_git/$VSTS_SPEC_REPO_NAME)"

else

  resp="$(pod repo add $GIT_SPEC_REPO_NAME https://$GITHUB_USER_ACCOUNT:$GITHUB_ACCESS_TOKEN@github.com/Microsoft/$GIT_SPEC_REPO_NAME.git)"

fi

error="$(echo $resp | grep -i 'error\|fatal')"
if [ "$error" ]; then
  echo "Couldn't add private spec repo for $1"
  exit 1
fi
