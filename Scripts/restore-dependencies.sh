#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

filename=Apple-BYOI-0.0.1.zip
echo "Change a path to $1"
cd $1
if [ -d "$1/Auth0" ] && [ -d "$1/Firebase" ]; then
  echo "Auth0/Firebase folders for iOS exist. Skipping download files."
else
  rm -rf $1/Auth0
  rm -rf $1/Firebase
  wget https://mobilecentersdkdev.blob.core.windows.net/sdk-dependencies/$filename
  unzip $filename
  rm $filename
fi
