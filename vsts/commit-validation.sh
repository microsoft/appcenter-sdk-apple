#!/bin/bash
if [ -z "$1" ]; then
  echo "This build doesn't have an associated commit hash which is required."
  echo "If this is an ad hoc build, please specify an appropriate commit hash for the build"
  exit 1
else
  echo "Found commit hash:" $1
fi
