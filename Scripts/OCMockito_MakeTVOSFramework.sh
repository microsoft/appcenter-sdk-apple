# First build the OS X framework to get its folder structure.
xcodebuild -configuration Release -target OCMockito -sdk macosx

# We'll copy the OS X framework to a new location, then modify it in place.
OSX_FRAMEWORK="build/Release/OCMockito.framework/"
TVOS_FRAMEWORK="build/Release/OCMockitoTVOS.framework/"

# Trigger builds of the static library for both the simulator and the device.
xcodebuild -configuration Release -target libocmockito -sdk appletvos10.0
OUT=$?
if [ "${OUT}" -ne "0" ]; then
    echo Device build failed
    exit ${OUT}
fi
xcodebuild -configuration Release -target libocmockito -sdk appletvsimulator10.0
OUT=$?
if [ "${OUT}" -ne "0" ]; then
    echo Simulator build failed
    exit ${OUT}
fi

# Copy the OS X framework to the new location.
mkdir -p "${TVOS_FRAMEWORK}"
rsync -q -a --delete "${OSX_FRAMEWORK}" "${TVOS_FRAMEWORK}"

# Rename the main header.
mv "${TVOS_FRAMEWORK}/Headers/OCMockito.h" "${TVOS_FRAMEWORK}/Headers/OCMockitoTVOS.h"

# Update all imports to use the new framework name.
IMPORT_EXPRESSION="s/#import <OCMockito/#import <OCMockitoTVOS/g;"
find "${TVOS_FRAMEWORK}" -name '*.h' -print0 | xargs -0 perl -pi -e "${IMPORT_EXPRESSION}"

# Delete the existing (OS X) library and the link to it.
rm "${TVOS_FRAMEWORK}/OCMockito" "${TVOS_FRAMEWORK}/Versions/Current/OCMockito"

# Create a new library that is a fat library containing both static libraries.
DEVICE_LIB="build/Release-appletvos/libocmockito.a"
SIMULATOR_LIB="build/Release-appletvsimulator/libocmockito.a"
OUTPUT_LIB="${TVOS_FRAMEWORK}/Versions/Current/OCMockitoTVOS"

lipo -create "${DEVICE_LIB}" "${SIMULATOR_LIB}" -o "${OUTPUT_LIB}"

# Add a symlink, as required by the framework.
ln -s Versions/Current/OCMockitoTVOS "${TVOS_FRAMEWORK}/OCMockitoTVOS"

# Update the name in the plist file.
NAME_EXPRESSION="s/OCMockito/OCMockitoTVOS/g;"
perl -pi -e "${NAME_EXPRESSION}" "${TVOS_FRAMEWORK}/Resources/Info.plist"
