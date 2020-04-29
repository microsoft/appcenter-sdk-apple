#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Install dir will be the final output to the framework.
# The following line create it in the root folder of the current project.
PRODUCTS_DIR="${SRCROOT}/../AppCenter-SDK-Apple/"
WORK_DIR="${PRODUCTS_DIR}/xcframework/"

rm -rf ${PROJECT_NAME}.xcframework/
xcodebuild -create-xcframework -framework $WORK_DIR/Release-iphoneos/${PROJECT_NAME}.framework -framework $WORK_DIR/Release-iphonesimulator/${PROJECT_NAME}.framework -framework $WORK_DIR/Release-appletvos/${PROJECT_NAME}.framework -framework $WORK_DIR/Release-appletvsimulator/${PROJECT_NAME}.framework -framework $WORK_DIR/Release-macos/${PROJECT_NAME}.framework -output "$WORK_DIR/Output/${PROJECT_NAME}.xcframework"

rm -rf $WORK_DIR/Release-iphoneos
rm -rf $WORK_DIR/Release-appletvos
rm -rf $WORK_DIR/Release-appletvsimulator
rm -rf $WORK_DIR/Release-macos
rm -rf $WORK_DIR/Release-iphonesimulator

