#!/bin/bash

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Loop through all the embeded frameworks.
echo "Architecture(s) built for this product: $ARCHS."
for f in $BUILT_PRODUCTS_DIR/$FRAMEWORKS_FOLDER_PATH/*.framework/ ; do

    # Not all the frameworks correctly specify the CFBundleExecutable from their info.plist so default to naming convention.
    FRAMEWORK_NAME=$(basename ${f%.*})

    # lipo -archs would be better but introduced in Xcode 10.1 toolchain only (we still support 10.0).
    FRAMEWORK_ARCHITECTURES=$(lipo -detailed_info "$f/$FRAMEWORK_NAME" | awk '/^architecture/{print $2}' ORS=' ')
    ARCHS_TO_REMOVE=$(comm -13  <(tr ' ' '\n' <<<$ARCHS | sort) <(tr ' ' '\n' <<<$FRAMEWORK_ARCHITECTURES | sort))
    if [ ! -z "$ARCHS_TO_REMOVE" ];  then
        
        # Remove all the extra architecture from this framework at once.
        lipo -remove $(sed 's/ / -remove /g' <<<$ARCHS_TO_REMOVE) "$f/$FRAMEWORK_NAME" -o "$f/$FRAMEWORK_NAME"
        echo "Architecture(s) $(sed 's/\n/ /g' <<<$ARCHS_TO_REMOVE) removed from framework $FRAMEWORK_NAME."
    fi
done
