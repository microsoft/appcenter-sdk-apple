#!/bin/bash

# Constants
REPOSITORY="$(echo $GIT_REPOSITORY_URL | awk -F "[:]" '{print $2}' | awk -F "[.]" '{print $1}')"
GITHUB_API_URL_TEMPLATE="https://%s.github.com/repos/%s/%s?access_token=%s%s"
GITHUB_API_HOST="api"
GITHUB_UPLOAD_HOST="uploads"
BINARY_FILE="MobileCenter-SDK-iOS.zip"
JQ_COMMAND=$BITRISE_DEPLOY_DIR/jq

# GitHub API endpoints
REQUEST_URL_REF_TAG="$(printf $GITHUB_API_URL_TEMPLATE $GITHUB_API_HOST $REPOSITORY 'git/refs/tags' $GITHUB_ACCESS_TOKEN)"
REQUEST_URL_TAG="$(printf $GITHUB_API_URL_TEMPLATE $GITHUB_API_HOST $REPOSITORY 'git/tags' $GITHUB_ACCESS_TOKEN)"
REQUEST_REFERENCE_URL="$(printf $GITHUB_API_URL_TEMPLATE $GITHUB_API_HOST $REPOSITORY 'git/refs' $GITHUB_ACCESS_TOKEN)"
REQUEST_RELEASE_URL="$(printf $GITHUB_API_URL_TEMPLATE $GITHUB_API_HOST $REPOSITORY 'releases' $GITHUB_ACCESS_TOKEN)"
REQUEST_UPLOAD_URL_TEMPLATE="$(printf $GITHUB_API_URL_TEMPLATE $GITHUB_UPLOAD_HOST $REPOSITORY 'releases/{id}/assets' $GITHUB_ACCESS_TOKEN '&name={filename}')"

## I. Check parameter
if [ -z $1 ] || ( [ "$1" != "internal" ] && [ "$1" != "external" ] ); then
  echo "Invalid parameter.";
  echo "  Usage: $0 {internal|external}";
  exit 1;
fi

## II. Get publish version
publish_version="$(grep "VERSION_STRING" $BITRISE_SOURCE_DIR/$VERSION_FILENAME | head -1 | awk -F "[= ]" '{print $4}')"
echo "Publish version:" $publish_version

if [ "$1" == "internal" ]; then

  ## 1. Get the latest version
  echo "Get the latest version to determine a build number"
  build_number=0
  resp="$(curl -s $INTERNAL_RELEASE_VERSION_FILENAME)"
  version="$(echo $resp | $JQ_COMMAND -r '.version')"

  # Exit if response doesn't contain an array
  if [ -z $version ] || [ "$version" == "" ] || [ "$version" == "null" ]; then
    echo "Cannot retrieve the latest version"
    echo "Response:" $resp
    exit 1
  fi

  # Determine the next version
  if [[ "$version" == $publish_version-* ]]; then
    build_number="$(echo $version | awk -F "[-]" '{print $2}')"
    build_number=$(($build_number + 1))
  fi

  publish_version=$publish_version-$build_number
  echo "New version:" $publish_version

  ## 2. Update version file
  echo {\"version\":\"$publish_version\"} > ios_version.txt
  azure telemetry --disable
  echo "Y" | azure storage blob upload ios_version.txt sdk
  rm ios_version.txt

else

  ## 1. Extract change log
  change_log_found=false
  change_log=""
  while IFS='' read -r line || -n "$line" ]]; do

    # If it is reading change log for the version
    if $change_log_found; then

      # If it reads end of change log for the version
      if [[ "$line" =~ "___" ]]; then
        break

      # Append the line
      else
        change_log="$change_log\n$line"
      fi

    # If it didn't find changelog for the version
    else

      # If it is the first line of change log for the version
      if [[ "$line" =~ "## Version $publish_version" ]]; then
        change_log="$line"
        change_log_found=true
      fi
    fi
  done < $CHANGE_LOG_FILENAME
  echo "Change log:" $change_log

  ## 2. Create a tag
  echo "Create a tag ($publish_version) for the commit ($GIT_CLONE_COMMIT_HASH)"
  resp="$(curl -s -X POST $REQUEST_URL_TAG -d '{
      "tag": "'${publish_version}'",
      "message": "'${publish_version}'",
      "type": "commit",
      "object": "'${GIT_CLONE_COMMIT_HASH}'"
    }')"
  sha="$(echo $resp | $JQ_COMMAND -r '.sha')"

  # Exit if response doesn't contain "sha" key
  if [ -z $sha ] || [ "$sha" == "" ] || [ "$sha" == "null" ]; then
    echo "Cannot create a tag"
    echo "Response:" $resp
    exit 1 
  else
    echo "A tag has been created with SHA ($sha)"
  fi

  ## 3. Create a reference
  echo "Create a reference for the tag ($publish_version)"
  resp="$(curl -s -X POST $REQUEST_REFERENCE_URL -d '{
      "ref": "refs/tags/'${publish_version}'",
      "sha": "'${sha}'"
    }')"
  ref="$(echo $resp | $JQ_COMMAND -r '.ref')"

  # Exit if response doesn't contain "ref" key
  if [ -z $ref ] || [ "$ref" == "" ] || [ "$ref" == "null" ]; then
    echo "Cannot create a reference"
    echo "Response:" $resp
    exit 1 
  else
    echo "A reference has been created to $ref"
  fi

  ## 4. Create a release
  echo "Create a release for the tag ($publish_version)"
  resp="$(curl -s -X POST $REQUEST_RELEASE_URL -d '{
      "tag_name": "'${publish_version}'",
      "target_commitish": "master",
      "name": "'${publish_version}'",
      "body": "'${change_log}'",
      "draft": true,
      "prerelease": true
    }')"
  id="$(echo $resp | $JQ_COMMAND -r '.id')"

  # Exit if response doesn't contain "id" key
  if [ -z $id ] || [ "$id" == "" ] || [ "$id" == "null" ]; then
    echo "Cannot create a release"
    echo "Response:" $resp
    exit 1 
  else
    echo "A release has been created with ID ($id)"
  fi

fi

## III. Upload binary
cd $BITRISE_DEPLOY_DIR # This is required, file upload via curl doesn't properly work with absolute path
echo "Upload binaries"
upload_url="$(echo $REQUEST_UPLOAD_URL_TEMPLATE | sed 's/{id}/'$id'/g')"
filename=$(echo $BINARY_FILE | sed 's/.zip/-'${publish_version}'.zip/g')
mv $BINARY_FILE $filename

# Upload binary to Azure Storage
resp="$(echo "N" | azure storage blob upload ${filename} sdk | grep overwrite)"
if [ "$resp" ]; then
  echo "${filename} already exists"
  exit 1
fi

# Upload binary to GitHub for external release
if [ "$1" == "external" ]; then
  url="$(echo $upload_url | sed 's/{filename}/'${filename}'/g')"
  resp="$(curl -s -X POST -H 'Content-Type: application/zip' --data-binary @$filename $url)"
  id="$(echo $resp | $JQ_COMMAND -r '.id')"

  # Log error if response doesn't contain "id" key
  if [ -z $id ] || [ "$id" == "" ] || [ "$id" == "null" ]; then
    echo "Cannot upload" $file
    echo "Request URL:" $url
    echo "Response:" $resp
    exit 1
  fi
fi

echo $filename "Uploaded successfully"

## Clean up
rm -rf $JQ_COMMAND
