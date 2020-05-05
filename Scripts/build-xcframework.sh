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
XC_BUILD_COMMAND="xcodebuild -create-xcframework"

function  SET_XC_BUILD_COMMAND_FRAMEWORK() {
    FRAMEWORK_PATH="$WORK_DIR/Release-$1/${PROJECT_NAME}.framework"
    [ -e "$FRAMEWORK_PATH" ] && XC_BUILD_COMMAND="$XC_BUILD_COMMAND -framework $FRAMEWORK_PATH";
}

# Create a cycle instead next lines
SET_XC_BUILD_COMMAND_FRAMEWORK "iphoneos"
SET_XC_BUILD_COMMAND_FRAMEWORK "iphonesimulator"
SET_XC_BUILD_COMMAND_FRAMEWORK "appletvos"
SET_XC_BUILD_COMMAND_FRAMEWORK "appletvsimulator"
SET_XC_BUILD_COMMAND_FRAMEWORK "macos"

XC_BUILD_COMMAND="$XC_BUILD_COMMAND -output  $OUTPUT/${PROJECT_NAME}.xcframework"
eval "$XC_BUILD_COMMAND"

# Clean build frameworks which was used to create XCFramework.
rm -rf $WORK_DIR/Release-*/${PROJECT_NAME}.framework
