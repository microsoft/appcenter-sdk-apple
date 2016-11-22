# MobileCenter-SDK-iOS Change Log


## Version 0.3.2

This version has some internal changes and bug fixes.

### MobileCenter

* **[Feature]** Add more functionalities for Swift Demo application.
* **[Misc]** Add more logs to provide information of SDK operations.
* **[Misc]** Remove UUID format restriction for app secret.

### MobileCenterCrashes

* **[Feature]** Add CrashProbe cases for testing.
* **[Feature]** Allow wrapper SDKs such as Xamarin to store additiona crash data files.
* **[Bug]** Fix a crash issue when SDK tries to access crash data in the file system.

___

## Version 0.3.1

This is our first public release.

___

## Version 0.3.0

This version introduces **breaking changes**. 
It includes public methods renaming.

### MobileCenter

* **[Breaking]** Method `start:` of class `MSMobileCenter` is renamed `configureWithAppSecret:`.
* **[Breaking]** Method `isInitilized` of class `MSMobileCenter` is renamed `isConfigured`.