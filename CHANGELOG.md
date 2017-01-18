# Mobile Center SDK for iOS Change Log

## Version 0.3.7

This version has bug fixes.

### MobileCenter

* **[Bug]** Fix crash sending failure callback, http status code now included in forwarded error.
* **[Bug]** Fix http tasks cancelled when expected to be suspended.
* **[Misc]** Display headers in logs for HTTP requests.

___

## Version 0.3.6

This version has bug fixes.

### MobileCenter

* **[Bug]** Change the type of toffset to prevent inaccurate time information for logs.
* **[Bug]** Fix not to send Crashes logs when Crashes service is disabled.
* **[Bug]** Fix CXXException where last exception was missing from crashing thread.

___

## Version 0.3.5

This version has bug fixes.

### MobileCenter

* **[Bug]** PLCrashReporter downgraded to v1.2 to fix duplicate symbols if the application already contains it.

___

## Version 0.3.4

This version has bug fixes and test application improvement.

### MobileCenter

* **[Bug]** Fix Channel that did not call delegate when it is disabled because of 404.
* **[Bug]** Fix the offset unit that was in second to millisecond.

___

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
