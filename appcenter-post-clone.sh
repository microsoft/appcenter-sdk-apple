#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Download App Center SDK frameworks
curl -O https://mobilecentersdkdev.blob.core.windows.net/sdk/AppCenter-SDK-Apple.zip

# Unzip files to framework location
unzip AppCenter-SDK-Apple.zip

# Update GoogleServices-Info.plist
echo $GOOGLE_SERVICE_INFO_PLIST | base64 -D > $APPCENTER_SOURCE_DIRECTORY/Sasquatch/SasquatchPuppet/GoogleService-Info.plist
echo $GOOGLE_SERVICE_INFO_PLIST | base64 -D > $APPCENTER_SOURCE_DIRECTORY/Sasquatch/SasquatchSwift/GoogleService-Info.plist
