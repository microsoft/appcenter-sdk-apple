#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Download App Center SDK frameworks
curl -O https://mobilecentersdkdev.blob.core.windows.net/sdk/AppCenter-SDK-Apple.zip

# Unzip files to framework location
unzip AppCenter-SDK-Apple.zip

# Move app-secret's values for Apple apps to config.
b64FileName="appcenter-sdk-apple-test-apps-secrets.b64"
echo ${APPLE_APP_SECRETS} >> ${b64FileName}
base64 -D -i ${b64FileName} -o "Config/AppCenterSecrets.xcconfig"
