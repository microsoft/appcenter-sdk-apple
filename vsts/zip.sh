#!/bin/bash
folder=AppCenter-SDK-Apple/

# Copy LICENSE, README and CHANGELOG
cp LICENSE $folder
cp README.md $folder
cp CHANGELOG.md $folder

# Zip the folder
zip -r $FRAMEWORKS_ZIP_FILENAME $folder
