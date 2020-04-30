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

# Create a cycle instead next lines
PLATFORM_NAME="iphoneos"
FRAMEWORK_PATH="$WORK_DIR/Release-${PLATFORM_NAME}/${PROJECT_NAME}.framework"
[ -e "$FRAMEWORK_PATH" ] && XC_BUILD_COMMAND="$XC_BUILD_COMMAND -framework $FRAMEWORK_PATH"

PLATFORM_NAME="iphonesimulator"
FRAMEWORK_PATH="$WORK_DIR/Release-${PLATFORM_NAME}/${PROJECT_NAME}.framework"
[ -e "$FRAMEWORK_PATH" ] && XC_BUILD_COMMAND="$XC_BUILD_COMMAND -framework $FRAMEWORK_PATH"

PLATFORM_NAME="appletvos"
FRAMEWORK_PATH="$WORK_DIR/Release-${PLATFORM_NAME}/${PROJECT_NAME}.framework"
[ -e "$FRAMEWORK_PATH" ] && XC_BUILD_COMMAND="$XC_BUILD_COMMAND -framework $FRAMEWORK_PATH"

PLATFORM_NAME="appletvsimulator"
FRAMEWORK_PATH="$WORK_DIR/Release-${PLATFORM_NAME}/${PROJECT_NAME}.framework"
[ -e "$FRAMEWORK_PATH" ] && XC_BUILD_COMMAND="$XC_BUILD_COMMAND -framework $FRAMEWORK_PATH"

PLATFORM_NAME="macos"
FRAMEWORK_PATH="$WORK_DIR/Release-${PLATFORM_NAME}/${PROJECT_NAME}.framework"
[ -e "$FRAMEWORK_PATH" ] && XC_BUILD_COMMAND="$XC_BUILD_COMMAND -framework $FRAMEWORK_PATH"

XC_BUILD_COMMAND="$XC_BUILD_COMMAND -output  $OUTPUT/${PROJECT_NAME}.xcframework"
eval "$XC_BUILD_COMMAND"

# Clean build frameworks which was used to create XCFramework.
rm -rf $WORK_DIR/Release-*/${PROJECT_NAME}.framework
