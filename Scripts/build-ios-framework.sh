#!/bin/sh

# Load custom build config.
if [ -r "${SRCROOT}/../.build_config" ]; then
source "${SRCROOT}/../.build_config"
echo "MS_ARM64E_XCODE_PATH: " $MS_ARM64E_XCODE_PATH
else
echo "Couldn't find custom build config"
fi

# Sets the target folders and the final framework product.
FMK_NAME=$1
TGT_NAME=${FMK_NAME}IOS
FMK_RESOURCE_BUNDLE=${FMK_NAME}Resources

echo "Building ${FMK_NAME} iOS framework."

# Install dir will be the final output to the framework.
# The following line create it in the root folder of the current project.
PRODUCTS_DIR=${SRCROOT}/../AppCenter-SDK-Apple/iOS
INSTALL_DIR=${PRODUCTS_DIR}/${FMK_NAME}.framework

# Working dir will be deleted after the framework creation.
WRK_DIR=build
DEVICE_DIR=${WRK_DIR}/Release-iphoneos
SIMULATOR_DIR=${WRK_DIR}/Release-iphonesimulator

# Make sure we're inside $SRCROOT.
cd "${SRCROOT}"

# Cleaning previous build.
xcodebuild -project "${FMK_NAME}.xcodeproj" -configuration "Release" -target "${TGT_NAME}" clean

# Building both architectures.
xcodebuild -project "${FMK_NAME}.xcodeproj" -configuration "Release" -target "${TGT_NAME}" -sdk iphoneos
xcodebuild -project "${FMK_NAME}.xcodeproj" -configuration "Release" -target "${TGT_NAME}" -sdk iphonesimulator

# Cleaning the oldest.
if [ -d "${INSTALL_DIR}" ]
then
rm -rf "${INSTALL_DIR}"
fi

# Creates and renews the final product folder.
mkdir -p "${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}/Headers"
mkdir -p "${INSTALL_DIR}/Modules"

# Copy the swift import file
cp -f "${SRCROOT}/${FMK_NAME}/Support/iOS.modulemap" "${INSTALL_DIR}/Modules/module.modulemap"

# Copies the headers and resources files to the final product folder.
cp -R "${SRCROOT}/${WRK_DIR}/Release-iphoneos/include/${FMK_NAME}/" "${INSTALL_DIR}/Headers/"

# Copy the resource bundle for App Center Distribute.
if [ -d "${SRCROOT}/${WRK_DIR}/Release-iphoneos/${FMK_RESOURCE_BUNDLE}.bundle" ]; then
echo "Copying resource bundle."
cp -R "${SRCROOT}/${WRK_DIR}/Release-iphoneos/${FMK_RESOURCE_BUNDLE}.bundle" "${PRODUCTS_DIR}" || true
fi

# Create the arm64e slice in Xcode 10.1 and lipo it with the device binary that was created with oldest supported Xcode version.
LIB_IPHONEOS_FINAL="${DEVICE_DIR}/lib${FMK_NAME}.a"
if [ -z "$MS_ARM64E_XCODE_PATH" ] || [ ! -d "$MS_ARM64E_XCODE_PATH" ]; then
echo "Environment variable MS_ARM64E_XCODE_PATH not set or not a valid path."

echo "Use current Xcode version and lipo -create the fat binary."
lipo -create "${LIB_IPHONEOS_FINAL}" "${SIMULATOR_DIR}/lib${FMK_NAME}.a" -output "${INSTALL_DIR}/${FMK_NAME}"

else

# Grep the output of `lipo -archs` if it contains "arm64e". If it does, don't build for arm64e again.
DOES_CONTAIN_ARM64E=`env DEVELOPER_DIR="$MS_ARM64E_XCODE_PATH" /usr/bin/lipo -archs "${LIB_IPHONEOS_FINAL}" | grep arm64e`
if [ ! -z "${DOES_CONTAIN_ARM64E}" ]; then
echo "The binary already contains an arm64e slice."
else

echo "Building the arm64e slice."

# Move binary that was create with old Xcode to temp location.
LIB_IPHONEOS_TEMP_DIR="${DEVICE_DIR}/temp"
mkdir -p "${LIB_IPHONEOS_TEMP_DIR}"
mv "${DEVICE_DIR}/lib${FMK_NAME}.a" "${LIB_IPHONEOS_TEMP_DIR}/lib${FMK_NAME}.a"

# Build with the Xcode version that supports arm64e.
env DEVELOPER_DIR="${MS_ARM64E_XCODE_PATH}" /usr/bin/xcodebuild ARCHS="arm64e" -project "${FMK_NAME}.xcodeproj" -configuration "Release" -target "${TGT_NAME}"

# Lipo the binaries that were built with various Xcode versions.
env DEVELOPER_DIR="${MS_ARM64E_XCODE_PATH}" lipo -create "${LIB_IPHONEOS_TEMP_DIR}/lib${FMK_NAME}.a" "${LIB_IPHONEOS_FINAL}" -output "${LIB_IPHONEOS_FINAL}"
fi

echo "Use arm64e Xcode and lipo -create the fat binary."
env DEVELOPER_DIR="$MS_ARM64E_XCODE_PATH" lipo -create "${LIB_IPHONEOS_FINAL}" "${SIMULATOR_DIR}/lib${FMK_NAME}.a" -output "${INSTALL_DIR}/${FMK_NAME}"

# End of arm64e code block.
fi
