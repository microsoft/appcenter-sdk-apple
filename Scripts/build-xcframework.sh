#!/bin/sh

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

# Work dir is directory where all XCFramework artifacts is stored.
WORK_DIR="${SRCROOT}/../AppCenter-SDK-Apple/xcframework"

# Work dir will be the final output to the framework.
XC_FRAMEWORK_PATH="${WORK_DIR}/Output/${PROJECT_NAME}.xcframework"

# Dir where catalyst build framewrok stored after build
CATALYST_BUILD_DIR="build/Release-maccatalyst/"

# Clean previus XCFramework build.
rm -rf ${PROJECT_NAME}.xcframework/

# Build and move mac catalyst framework
xcodebuild -project "${PROJECT_NAME}.xcodeproj" -configuration "Release" -scheme "${PROJECT_NAME} iOS Framework" -destination 'platform=macOS,variant=Mac Catalyst' 
cp -R "$CATALYST_BUILD_DIR" "${XCFRAMEWORK_DIR}"

# Create a command to build XCFramework.
for SDK in iphoneos iphonesimulator appletvos appletvsimulator macOS maccatalyst; do
    FRAMEWORK_PATH="$WORK_DIR/Release-$SDK/${PROJECT_NAME}.framework"
    [ -e "$FRAMEWORK_PATH" ] && XC_BUILD_COMMAND="$XC_BUILD_COMMAND -framework $FRAMEWORK_PATH";
done
XC_BUILD_COMMAND="xcodebuild -create-xcframework $XC_BUILD_COMMAND -output $XC_FRAMEWORK_PATH"

#Build XCFramework
eval "$XC_BUILD_COMMAND"

RES_FILE_PATH="$WORK_DIR/Release-iphoneos/AppCenterDistributeResources.bundle"
if [[ ${PROJECT_NAME} == "AppCenterDistribute" ]] && [ -e "${RES_FILE_PATH}" ]; then
    mv "${RES_FILE_PATH}" "${XC_FRAMEWORK_PATH}"
fi

