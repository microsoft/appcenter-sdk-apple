#!/bin/bash

# Constants
REPOSITORY="$(echo $GIT_REPOSITORY_URL | awk -F "[:]" '{print $2}' | awk -F "[.]" '{print $1}')"
GITHUB_API_URL_TEMPLATE="https://%s.github.com/repos/%s/%s?access_token=%s%s"
GITHUB_API_HOST="api"
GITHUB_UPLOAD_HOST="uploads"
BINARY_FILE_FILTER="*.framework.zip"
JQ_COMMAND=$BITRISE_DEPLOY_DIR/jq

# GitHub API endpoints
REQUEST_URL_REF_TAG="$(printf $GITHUB_API_URL_TEMPLATE $GITHUB_API_HOST $REPOSITORY 'git/refs/tags' $GITHUB_ACCESS_TOKEN)"
REQUEST_URL_TAG="$(printf $GITHUB_API_URL_TEMPLATE $GITHUB_API_HOST $REPOSITORY 'git/tags' $GITHUB_ACCESS_TOKEN)"
REQUEST_REFERENCE_URL="$(printf $GITHUB_API_URL_TEMPLATE $GITHUB_API_HOST $REPOSITORY 'git/refs' $GITHUB_ACCESS_TOKEN)"
REQUEST_RELEASE_URL="$(printf $GITHUB_API_URL_TEMPLATE $GITHUB_API_HOST $REPOSITORY 'releases' $GITHUB_ACCESS_TOKEN)"
REQUEST_UPLOAD_URL_TEMPLATE="$(printf $GITHUB_API_URL_TEMPLATE $GITHUB_UPLOAD_HOST $REPOSITORY 'releases/{id}/assets' $GITHUB_ACCESS_TOKEN '&name={filename}')"

# 0. Check parameter
if [ -z $1 ] || ( [ "$1" != "internal" ] && [ "$1" != "external" ] ); then
  echo "Invalid parameter.";
  echo "  Usage: $0 {internal|external}";
  exit 1;
fi

# 1. Get publish version
publish_version="$(grep "VERSION_STRING" $BITRISE_SOURCE_DIR/$VERSION_FILE | head -1 | awk -F "[= ]" '{print $4}')"
echo "Publish version:" $publish_version

# Process additional steps to generate version for internal release.
if [ "$1" == "internal" ]; then

  # 2. Get tags
  echo "Get all tags to determine a build number"
  build_number=0
  resp="$(curl -s $REQUEST_URL_REF_TAG)"
  refs="$(echo $resp | $JQ_COMMAND -c .[])"

  # Exit if response doesn't contain an array
  if [ -z $refs ] || [ "$refs" == "" ] || [ "$refs" == "null" ]; then
    echo "Cannot retrieve tags"
    echo "Response:" $resp
    exit 1 
  fi

  # 3. Extract build number and update version
  for ref in $refs
  do
    type="$(echo $ref | $JQ_COMMAND -r '.object.type')"
    if [ "$type" == "tag" ]; then
      tag="$(echo $ref | $JQ_COMMAND -r '.ref')"
      version="$(echo $tag | awk -F "[/]" '{print $3}')"
      if [[ "$version" == $publish_version-* ]]; then
        forth_number="$(echo $version | awk -F "[-]" '{print $2}')"
        forth_number=$(($forth_number + 1))
        if [ $forth_number -gt $build_number ]; then
          build_number=$forth_number
        fi
      fi
    fi
  done
  publish_version=$publish_version-$build_number
  echo "New version:" $publish_version

fi

# 4. Create a tag
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

# 5. Create a reference
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
  echo "A reference has been created to ${ref}"
fi

# 6. Create a release
echo "Create a release for the tag ($publish_version)"
resp="$(curl -s -X POST $REQUEST_RELEASE_URL -d '{
    "tag_name": "'${publish_version}'",
    "target_commitish": "master",
    "name": "'${publish_version}'",
    "body": "",
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

# 7. Upload binaries
cd $BITRISE_DEPLOY_DIR # This is required, file upload via curl doesn't properly work with absolute path

echo "Upload binaries"
upload_url="$(echo $REQUEST_UPLOAD_URL_TEMPLATE | sed 's/{id}/'$id'/g')"
total_count=0
succeeded_count=0
for file in $BITRISE_DEPLOY_DIR/$BINARY_FILE_FILTER
do
  total_count=$(($total_count + 1))
  url="$(echo $upload_url | sed 's/{filename}/'${file##*/}'/g')"
  resp="$(curl -s -X POST -H 'Content-Type: application/zip' --data-binary @${file##*/} $url)"
  id="$(echo $resp | $JQ_COMMAND -r '.id')"

  # Log error if response doesn't contain "id" key
  if [ -z $id ] || [ "$id" == "" ] || [ "$id" == "null" ]; then
    echo "Cannot upload" $file
    echo "Request URL:" $url
    echo "Response:" $resp
  else
    succeeded_count=$(($succeeded_count + 1))
    echo $file "Uploaded successfully"
  fi
done

# 8. Clean up
rm -rf $JQ_COMMAND

# Exit if upload failed at least one binary
if [ $succeeded_count -eq $total_count ]; then
  echo $succeeded_count "binaries have been uploaded successfully"
else
  echo "Failed to upload $(($total_count - $succeeded_count)) binaries."
  exit 1
fi
