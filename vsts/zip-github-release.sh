# Copy LICENSE, README and CHANGELOG
cp LICENSE $(Build.ArtifactStagingDirectory)/AppCenter.framework
cp README.md $(Build.ArtifactStagingDirectory)/AppCenter.framework
cp CHANGELOG.md $(Build.ArtifactStagingDirectory)/AppCenter.framework

# Zip the folder
VERSION=$(cat $(System.DefaultWorkingDirectory)/$(CURRENT_BUILD_VERSION_FILENAME)
cd $(Build.ArtifactStagingDirectory)
zip -r "AppCenter-$(VERSION).framework.zip" AppCenter.framework
