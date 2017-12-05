#!/usr/bin/env bash

# Change directory to repository root
cd ..

# Download App Center SDK frameworks
curl -O https://mobilecentersdkdev.blob.core.windows.net/sdk/AppCenter-SDK-Apple.zip

# Unzip files to framework location
unzip AppCenter-SDK-Apple.zip
