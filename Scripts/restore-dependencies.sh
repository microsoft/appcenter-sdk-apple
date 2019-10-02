#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

filename=Apple-BYOI-0.0.1.zip
echo "Change a path to $1"
cd $1
if [ -d "Auth0" ] && [ -d "Firebase" ]; then
  echo "Auth0/Firebase folders for iOS exist. Skipping download files."
else
  rm -rf Auth0
  rm -rf Firebase
  curl https://mobilecentersdkdev.blob.core.windows.net/sdk-dependencies/$filename > $filename
  unzip $filename
  rm $filename
fi
