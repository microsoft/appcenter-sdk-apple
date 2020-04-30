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
xcodebuild -create-xcframework -framework $WORK_DIR/Release-iphoneos/${PROJECT_NAME}.framework -framework $WORK_DIR/Release-iphonesimulator/${PROJECT_NAME}.framework -framework $WORK_DIR/Release-appletvos/${PROJECT_NAME}.framework -framework $WORK_DIR/Release-appletvsimulator/${PROJECT_NAME}.framework -framework $WORK_DIR/Release-macos/${PROJECT_NAME}.framework -output "$OUTPUT/${PROJECT_NAME}.xcframework"

# Clean build frameworks which was used to create XCFramework.
rm -rf $WORK_DIR/Release-*/${PROJECT_NAME}.framework
