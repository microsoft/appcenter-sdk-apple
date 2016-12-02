# Mobile Center SDK for iOS Change Log


## Version 0.3.3

This version has dependencies update, data model change and bug fix.

### MobileCenter

* **[Feature]** Add stack trace to Exception model for wrapper SDK.
* **[Misc]** Update OHTTPStubs to 5.2.3 and OCHamcrest to 6.0.0.

### MobileCenterAnalytics

* **[Misc]** Change to only accept NSString keys and values in properties for trackEvent and trackPage.

### Puppet

* **[Bug]** Fix Puppet application that duplicates list of items in Crashes.

___

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