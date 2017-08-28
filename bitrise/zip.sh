#!/bin/bash
file=MobileCenter-SDK-Apple.zip
folder=MobileCenter-SDK-Apple/

# Copy LICENSE, README and CHANGELOG
cp LICENSE $folder
cp README.md $folder
cp CHANGELOG.md $folder

# Zip the folder & publish to bitrise.
zip -r $file $folder
mv $file $BITRISE_DEPLOY_DIR
