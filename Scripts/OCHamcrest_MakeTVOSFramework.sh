# First build the OS X framework to get its folder structure.
xcodebuild -configuration Release -target OCHamcrest -sdk macosx

# We'll copy the OS X framework to a new location, then modify it in place.
OSX_FRAMEWORK="build/Release/OCHamcrest.framework/"
TVOS_FRAMEWORK="build/Release/OCHamcrestTVOS.framework/"

# Trigger builds of the static library for both the simulator and the device.
xcodebuild -configuration Release -target libochamcrest -sdk appletvos10.0
OUT=$?
if [ "${OUT}" -ne "0" ]; then
    echo Device build failed
    exit ${OUT}
fi
xcodebuild -configuration Release -target libochamcrest -sdk appletvsimulator10.0
OUT=$?
if [ "${OUT}" -ne "0" ]; then
    echo Simulator build failed
    exit ${OUT}
fi

# Copy the OS X framework to the new location.
mkdir -p "${TVOS_FRAMEWORK}"
rsync -q -a --delete "${OSX_FRAMEWORK}" "${TVOS_FRAMEWORK}"

# Rename the main header.
mv "${TVOS_FRAMEWORK}/Headers/OCHamcrest.h" "${TVOS_FRAMEWORK}/Headers/OCHamcrestTVOS.h"

# Update all imports to use the new framework name.
IMPORT_EXPRESSION="s/#import <OCHamcrest/#import <OCHamcrestTVOS/g;"
find "${TVOS_FRAMEWORK}" -name '*.h' -print0 | xargs -0 perl -pi -e "${IMPORT_EXPRESSION}"

# Delete the existing (OS X) library and the link to it.
rm "${TVOS_FRAMEWORK}/OCHamcrest" "${TVOS_FRAMEWORK}/Versions/Current/OCHamcrest"

# Create a new library that is a fat library containing both static libraries.
DEVICE_LIB="build/Release-appletvos/libochamcrest.a"
SIMULATOR_LIB="build/Release-appletvsimulator/libochamcrest.a"
OUTPUT_LIB="${TVOS_FRAMEWORK}/Versions/Current/OCHamcrestTVOS"

lipo -create "${DEVICE_LIB}" "${SIMULATOR_LIB}" -o "${OUTPUT_LIB}"

# Add a symlink, as required by the framework.
ln -s Versions/Current/OCHamcrestTVOS "${TVOS_FRAMEWORK}/OCHamcrestTVOS"

# Update the name in the plist file.
NAME_EXPRESSION="s/OCHamcrest/OCHamcrestTVOS/g;"
perl -pi -e "${NAME_EXPRESSION}" "${TVOS_FRAMEWORK}/Resources/Info.plist"
