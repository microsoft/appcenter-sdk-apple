1. Clone repositories:
    https://github.com/hamcrest/OCHamcrest
    https://github.com/jonreid/OCMockito

2. Copy MakeTVOSFramework.sh scripts to Source folder inside root directories of repositories.

3. Inside scripts change target platform if necessary.
    xcodebuild -configuration Release -target libochamcrest -sdk appletvos10.0

4. Switch to appropriate Xcode version depending on target platform.
    xcode-select -switch /path_to_xcode/Content/Developer

5. Run MakeTVOSFramework.sh script.