#!/bin/sh

source $(dirname "$0")/../build-ios-framework.sh AppCenterIdentity

# Add MSAL.
if [ -z $(otool -L "${INSTALL_DIR}/${FMK_NAME}" | grep 'libMSAL') ]; then
  if [ -z "$MS_ARM64E_XCODE_PATH" ] || [ ! -d "$MS_ARM64E_XCODE_PATH" ]; then
    echo "Use legacy Xcode and link MSAL via libtool."
    libtool -static  "${INSTALL_DIR}/${FMK_NAME}" "${SRCROOT}/../Vendor/iOS/MSAL/MSAL.framework/MSAL" -o "${INSTALL_DIR}/${FMK_NAME}"
  else
    echo "Use arm64e Xcode and link MSAL via libtool."
    env DEVELOPER_DIR="$MS_ARM64E_XCODE_PATH" /usr/bin/libtool -static  "${INSTALL_DIR}/${FMK_NAME}" "${SRCROOT}/../Vendor/iOS/MSAL/MSAL.framework/MSAL" -o "${INSTALL_DIR}/${FMK_NAME}"
  fi
fi

rm -r "${WRK_DIR}"
