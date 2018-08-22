#!/bin/sh

if [ ! -x "$(command -v jazzy)" ]
then
echo "Couldn't find jazzy. Install jazzy before building frameworks"
exit 1
fi

jazzy --config ${SRCROOT}/../Documentation/macOS/AppCenter/.jazzy.yaml

FMK_NAME=AppCenter
PRODUCTS_DIR=${SRCROOT}/../AppCenter-SDK-Apple/macOS
INSTALL_DIR=${PRODUCTS_DIR}/${FMK_NAME}.framework
DOCUMENTATION_DIR=${PRODUCTS_DIR}/Documentation/${FMK_NAME}

# Create Documentation directory within folder.
if [ ! -d "${DOCUMENTATION_DIR}" ]
then
mkdir -p "${DOCUMENTATION_DIR}"
fi

# Copy generated documentation into the documentation folder
cp -R "${SRCROOT}/../Documentation/macOS/${FMK_NAME}/Generated/" "${DOCUMENTATION_DIR}"
