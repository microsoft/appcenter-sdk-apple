#!/bin/bash

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

help() {
  echo "Usage: $0 {internal|external} -a <azure-storage-account> -k <azure-storage-access-key> -t <github-access-token>"
}

## I. Check parameters
if [ -z $1 ] || ( [ "$1" != "internal" ] && [ "$1" != "external" ] ); then
  help
  exit 1
fi

mode=$1
shift
github_access_token=""

while getopts 'a:k:t:' flag; do
  case "${flag}" in
    a)
      export AZURE_STORAGE_ACCOUNT=${OPTARG}
      ;;
    k)
      export AZURE_STORAGE_ACCESS_KEY=${OPTARG}
      ;;
    t)
      github_access_token=${OPTARG}
      ;;
    *)
      help
      exit 1
      ;;
  esac
done

if [ "$AZURE_STORAGE_ACCOUNT" == "" ] || [ "$AZURE_STORAGE_ACCESS_KEY" == "" ] || [ "$github_access_token" == "" ]; then
  help
  exit 1
fi

## II. Constants
REPOSITORY="$(echo $BUILD_BUILDURI | awk -F "[:]" '{print $2}' | awk -F "[/]" '{print $4"/"$5}' | awk -F "[.]" '{print $1}')"
GITHUB_API_URL_TEMPLATE="https://%s.github.com/repos/%s/%s?access_token=%s%s"
GITHUB_API_HOST="api"
GITHUB_UPLOAD_HOST="uploads"

## III. GitHub API endpoints
REQUEST_URL_REF_TAG="$(printf $GITHUB_API_URL_TEMPLATE $GITHUB_API_HOST $REPOSITORY 'git/refs/tags' $github_access_token)"
REQUEST_URL_TAG="$(printf $GITHUB_API_URL_TEMPLATE $GITHUB_API_HOST $REPOSITORY 'git/tags' $github_access_token)"
REQUEST_REFERENCE_URL="$(printf $GITHUB_API_URL_TEMPLATE $GITHUB_API_HOST $REPOSITORY 'git/refs' $github_access_token)"
REQUEST_RELEASE_URL="$(printf $GITHUB_API_URL_TEMPLATE $GITHUB_API_HOST $REPOSITORY 'releases' $github_access_token)"
REQUEST_UPLOAD_URL_TEMPLATE="$(printf $GITHUB_API_URL_TEMPLATE $GITHUB_UPLOAD_HOST $REPOSITORY 'releases/{id}/assets' $github_access_token '&name={filename}')"

## IV. Get publish version
publish_version="$(grep "VERSION_STRING" $VERSION_FILENAME | head -1 | awk -F "[= ]" '{print $4}')"
echo "Publish version:" $publish_version

# Read publish version for current build
if [ "$mode" == "internal" ]; then
  version=$(cat $CURRENT_BUILD_VERSION_FILENAME)
else
  version=$(cat $ARTIFACT_PATH/version/$CURRENT_BUILD_VERSION_FILENAME)
fi

# Exit if response doesn't contain a version
if [ -z $version ] || [ "$version" == "" ]; then
  echo "Cannot retrieve the latest version"
  echo "Response:" $version
  exit 1
fi
echo "Found publish version for the build: $version"

if [ "$mode" == "internal" ]; then

  ## Change publish version to internal version
  publish_version=$version
  echo "Detected internal release. Publish version is updated to " $publish_version
else

  ## 0. Get artifact filename and commit hash from build
  prerelease=$(echo $ARTIFACT_PATH/zip/*.zip | rev | cut -d/ -f1 | rev)
  zip_filename="$(echo $FRAMEWORKS_ZIP_FILENAME | cut -d. -f1)"
  commit_hash="$(echo $prerelease | sed 's/'$zip_filename'-[[:digit:]]\{1,\}.[[:digit:]]\{1,\}.[[:digit:]]\{1,\}-[[:digit:]]\{1,\}+\(.\{40\}\)\.zip.*/\1/1')"

  # Rename zip archive to $FRAMEWORKS_ZIP_FILENAME
  mv $ARTIFACT_PATH/zip/$prerelease $FRAMEWORKS_ZIP_FILENAME

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
        change_log=$change_log$'\n'$line
      fi

    # If it didn't find changelog for the version
    else

      # If it is the first line of change log for the version
      if [[ "$line" =~ "## Version $publish_version" ]]; then
        change_log="${line}"
        change_log_found=true
      fi
    fi
  done < $CHANGE_LOG_FILENAME
  echo "Change log:" "$change_log"

  ## 2. Create a tag
  echo "Create a tag ($publish_version) for the commit ($commit_hash)"
  resp="$(curl -s -X POST $REQUEST_URL_TAG -d '{
      "tag": "'${publish_version}'",
      "message": "'${publish_version}'",
      "type": "commit",
      "object": "'${commit_hash}'"
    }')"
  sha="$(echo $resp | jq -r '.sha')"

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
  ref="$(echo $resp | jq -r '.ref')"

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
  body="$(jq -n --arg publish_version "$publish_version" --arg change_log "$change_log" '{
      tag_name: $publish_version,
      target_commitish: "master",
      name: $publish_version,
      body: $change_log,
      draft: true,
      prerelease: true
    }')"
  resp="$(curl -s -X POST $REQUEST_RELEASE_URL -d "$body")"
  id="$(echo $resp | jq -r '.id')"

  # Exit if response doesn't contain "id" key
  if [ -z $id ] || [ "$id" == "" ] || [ "$id" == "null" ]; then
    echo "Cannot create a release"
    echo "Response:" $resp
    exit 1
  else
    echo "A release has been created with ID ($id)"
  fi
fi

## V. Upload binary
echo "Upload binaries"
azure telemetry --disable
if [ "$mode" == "internal" ]; then

  # Determine the filename for the release
  filename=$(echo $FRAMEWORKS_ZIP_FILENAME | sed 's/.zip/-'${publish_version}'+'$BUILD_SOURCEVERSION'.zip/g')

  # Replace the latest binary in Azure Storage
  echo "Y" | azure storage blob upload $FRAMEWORKS_ZIP_FILENAME sdk --verbose
else

  # Determine the filename for the release
  filename=$(echo $FRAMEWORKS_ZIP_FILENAME | sed 's/.zip/-'${publish_version}'.zip/g')
fi

# Upload binary to Azure Storage
mv $FRAMEWORKS_ZIP_FILENAME $filename
echo "Y" | azure storage blob upload ${filename} sdk

# Upload binary to GitHub for external release
if [ "$mode" == "external" ]; then
  upload_url="$(echo $REQUEST_UPLOAD_URL_TEMPLATE | sed 's/{id}/'$id'/g')"
  url="$(echo $upload_url | sed 's/{filename}/'${filename}'/g')"
  resp="$(curl -s -X POST -H 'Content-Type: application/zip' --data-binary @$filename $url)"
  id="$(echo $resp | jq -r '.id')"

  # Log error if response doesn't contain "id" key
  if [ -z $id ] || [ "$id" == "" ] || [ "$id" == "null" ]; then
    echo "Cannot upload" $file
    echo "Request URL:" $url
    echo "Response:" $resp
    exit 1
  fi
fi

echo $filename "Uploaded successfully"
