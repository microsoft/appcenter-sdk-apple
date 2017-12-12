#!/bin/bash

help() {
  echo "Usage: $0 -t <appcenter-access-token>"
}

## I. Check parameter
APP_CENTER_ACCESS_TOKEN=""
while getopts 't:' flag; do
  case "${flag}" in
    t)
      APP_CENTER_ACCESS_TOKEN=${OPTARG}
      ;;
    *)
      help
      exit 1
      ;;
  esac
done

if [ "$APP_CENTER_ACCESS_TOKEN" == "" ]; then
  help
  exit 1
fi

## II. Run App Center Build
$APP_CENTER_CLI_COMMNAD build queue --token $APP_CENTER_ACCESS_TOKEN --branch $BUILD_SOURCEBRANCHNAME --app $APP_CENTER_SASQUATCHOBJC_BUILD_APP_ID
$APP_CENTER_CLI_COMMNAD build queue --token $APP_CENTER_ACCESS_TOKEN --branch $BUILD_SOURCEBRANCHNAME --app $APP_CENTER_SASQUATCHSWIFT_BUILD_APP_ID
$APP_CENTER_CLI_COMMNAD build queue --token $APP_CENTER_ACCESS_TOKEN --branch $BUILD_SOURCEBRANCHNAME --app $APP_CENTER_SASQUATCHMACOBJC_BUILD_APP_ID
$APP_CENTER_CLI_COMMNAD build queue --token $APP_CENTER_ACCESS_TOKEN --branch $BUILD_SOURCEBRANCHNAME --app $APP_CENTER_SASQUATCHMACSWIFT_BUILD_APP_ID