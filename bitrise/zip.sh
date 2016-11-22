#!/bin/bash

# Zip the folder & publish to bitrise.
file=MobileCenter-SDK-iOS.zip
zip -r $file MobileCenter-SDK-iOS/
mv $file $BITRISE_DEPLOY_DIR