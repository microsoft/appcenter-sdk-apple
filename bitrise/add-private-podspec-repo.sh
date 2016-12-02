#!/bin/bash
resp="$(pod repo add $GIT_SPEC_REPO_NAME https://$GITHUB_USER_ACCOUNT:$GITHUB_ACCESS_TOKEN@github.com/Microsoft/$GIT_SPEC_REPO_NAME.git)"
error="$(echo $resp | grep -i error\|fatal)"
if [ "$error" ]; then
  echo "Couldn't add private spec repo"
  exit 1
fi