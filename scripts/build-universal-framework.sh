FMK_NAME=${PROJECT_NAME}

# Install dir will be the final output to the framework.
# The following line create it in the root folder of the current project.

# Working dir will be deleted after the framework creation.
WRK_DIR=../build
DEVICE_DIR=${WRK_DIR}/Release-iphoneos/${FMK_NAME}.framework
SIMULATOR_DIR=${WRK_DIR}/Release-iphonesimulator/${FMK_NAME}.framework
UNIVERSAL_DIR=${WRK_DIR}/iphoneuniversal
FRAMEWORK=${UNIVERSAL_DIR}/${FMK_NAME}.framework
PRODUCT_DIR=../Products

# //////////////////////////////
# Building Universal Framework
# //////////////////////////////

# Building both architectures.
xcodebuild -configuration "Release" -target "${FMK_NAME}" -sdk iphoneos BUILD_DIR="${WRK_DIR}" BUILD_ROOT="${WRK_DIR}" clean build
xcodebuild -configuration "Release" -target "${FMK_NAME}" -sdk iphonesimulator BUILD_DIR="${WRK_DIR}" BUILD_ROOT="${WRK_DIR}" clean build

# Cleaning old folder for universal build
rm -rf "${UNIVERSAL_DIR}"
mkdir "${UNIVERSAL_DIR}"
mkdir "${FRAMEWORK}"

# Copy files from device build to universal archiv
cp -r "${DEVICE_DIR}/" "${FRAMEWORK}/"

# Uses the Lipo Tool to merge both binary files (i386 + armv6/armv7) into one Universal final product.
lipo -create "${DEVICE_DIR}/${FMK_NAME}" "${SIMULATOR_DIR}/${FMK_NAME}" -output "${FRAMEWORK}/${FMK_NAME}"

cp -r "${UNIVERSAL_DIR}/" "${PRODUCT_DIR}"

#rm -r "${WRK_DIR}"