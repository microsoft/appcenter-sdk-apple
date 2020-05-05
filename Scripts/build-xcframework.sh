#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Work dir is directory where all XCFramework artifacts is stored.
WORK_DIR="${SRCROOT}/../AppCenter-SDK-Apple/xcframework"

# Work dir will be the final output to the framework.
OUTPUT="${WORK_DIR}/Output"

# Clean previus XCFramework build.
rm -rf ${PROJECT_NAME}.xcframework/

# Build XCFramework.
function SetXcBuildCommandFramework() {
    FRAMEWORK_PATH="$WORK_DIR/Release-$1/${PROJECT_NAME}.framework"
    [ -e "$FRAMEWORK_PATH" ] && XC_BUILD_COMMAND="$XC_BUILD_COMMAND -framework $FRAMEWORK_PATH";
    
    local RES_FILE_PATH="$WORK_DIR/Release-$1/AppCenterDistributeResources.bundle"
    if [[ ${PROJECT_NAME} == "AppCenterDistribute" ]] && [[ $1 == "iphoneos" || $1 == "iphonesimulator" ]] && [ -e "${RES_FILE_PATH}" ]; then
        mv "${RES_FILE_PATH}" "${FRAMEWORK_PATH}"
    fi
}

# Create a cycle instead next lines
SetXcBuildCommandFramework "iphoneos"
SetXcBuildCommandFramework "iphonesimulator"
SetXcBuildCommandFramework "appletvos"
SetXcBuildCommandFramework "appletvsimulator"
SetXcBuildCommandFramework "macos"

XC_BUILD_COMMAND="xcodebuild -create-xcframework $XC_BUILD_COMMAND -output $OUTPUT/${PROJECT_NAME}.xcframework"
eval "$XC_BUILD_COMMAND"

# Clean build frameworks which was used to create XCFramework.
rm -rf $WORK_DIR/Release-*/${PROJECT_NAME}.framework
