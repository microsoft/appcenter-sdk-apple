#!/bin/bash

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Copy LICENSE, README and CHANGELOG
cp LICENSE $FRAMEWORKS_ZIP_FOLDER
cp README.md $FRAMEWORKS_ZIP_FOLDER
cp CHANGELOG.md $FRAMEWORKS_ZIP_FOLDER

# Zip the folder
zip -r -y $FRAMEWORKS_ZIP_FILENAME $FRAMEWORKS_ZIP_FOLDER
