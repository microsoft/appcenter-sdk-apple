#!/bin/bash
file=AppCenter-SDK-Apple.zip
folder=AppCenter-SDK-Apple/

# Copy LICENSE, README and CHANGELOG
cp LICENSE $folder
cp README.md $folder
cp CHANGELOG.md $folder

# Zip the folder & publish to bitrise.
zip -r $file $folder
mv $file $BITRISE_DEPLOY_DIR
