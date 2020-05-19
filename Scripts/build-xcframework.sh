#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Work dir is directory where all XCFramework artifacts is stored.
WORK_DIR="${SRCROOT}/../AppCenter-SDK-Apple/xcframework"

# Work dir will be the final output to the framework.
XC_FRAMEWORK_PATH="${WORK_DIR}/Output/${PROJECT_NAME}.xcframework"

# Clean previus XCFramework build.
rm -rf ${PROJECT_NAME}.xcframework/

# Build XCFramework.
function SetXcBuildCommandFramework() {
    FRAMEWORK_PATH="$WORK_DIR/Release-$1/${PROJECT_NAME}.framework"
    [ -e "$FRAMEWORK_PATH" ] && XC_BUILD_COMMAND="$XC_BUILD_COMMAND -framework $FRAMEWORK_PATH";
}

# Create a cycle instead next lines
SetXcBuildCommandFramework "iphoneos"
SetXcBuildCommandFramework "iphonesimulator"
SetXcBuildCommandFramework "appletvos"
SetXcBuildCommandFramework "appletvsimulator"
SetXcBuildCommandFramework "macos"

XC_BUILD_COMMAND="xcodebuild -create-xcframework $XC_BUILD_COMMAND -output $XC_FRAMEWORK_PATH"
eval "$XC_BUILD_COMMAND"


