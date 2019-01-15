#!/bin/sh

OS_NAME=$1
FMK_NAME=$2
PRODUCTS_DIR="${SRCROOT}/../AppCenter-SDK-Apple/$1"
INSTALL_DIR="${PRODUCTS_DIR}/${FMK_NAME}.framework"
DOCUMENTATION_DIR="${PRODUCTS_DIR}/Documentation/${FMK_NAME}"

if [ ! -x "$(command -v jazzy)" ]
then
echo "Couldn't find jazzy. Install jazzy before building frameworks"
exit 1
fi

jazzy --config "${SRCROOT}/../Documentation/${OS_NAME}/${FMK_NAME}/.jazzy.yaml"

# Create Documentation directory within folder.
if [ ! -d "${DOCUMENTATION_DIR}" ]
then
mkdir -p "${DOCUMENTATION_DIR}"
fi

# Copy generated documentation into the documentation folder.
cp -R "${SRCROOT}/../Documentation/${OS_NAME}/${FMK_NAME}/Generated/" "${DOCUMENTATION_DIR}"
