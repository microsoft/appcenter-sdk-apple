#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Reads release notes for the release.
# Usage: get-release-notes.sh [<version>]

PROJECT_DIR="$(dirname "$0")/.."
CHANGELOG_FILE="$PROJECT_DIR/CHANGELOG.md"

change_log_found=false
while IFS='' read -r line || -n "$line" ]]; do

# If it is reading change log for the version
if $change_log_found; then

  # If it reads end of change log for the version
  if [[ "$line" =~ "___" ]]; then
    break

  # Append the line
  else
    echo "$line"
  fi

# If it didn't find changelog for the version
else

  # If it is the first line of change log for the version
  if [[ "$line" =~ "## Version $1" ]]; then
    echo "$line"
    change_log_found=true
  fi
fi
done < $CHANGELOG_FILE
