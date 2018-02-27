# App Center SDK for iOS and macOS Change Log

## Version 1.5.0

This version contains a new feature.

### AppCenterDistribute

* **[Feature]** Add Session statistics for distribution group.

___

## Version 1.4.0

This version contains a new feature.

### AppCenterDistribute

* **[Feature]** Add reporting of downloads for in-app update.
* **[Improvement]** Add distribution group to all logs that are sent.

___

## Version 1.3.0

This version has a **breaking change** as the SDK now requires iOS 9 or later. It also contains a bug fix and an improvement.

### AppCenter

* **[Improvement]** Successful configuration of the SDK creates a success message in the console with log level INFO instead of ASSERT. Errors during configuration will still show up in the console with the log level ASSERT.

### AppCenterCrashes

* **[Fix]** Fix an issue where crashes were not reported reliably in some cases when used in Xamarin apps or when apps would take a long time to launch.

___

## Version 1.2.0

This version has a **breaking change** with bug fixes and improvements.

### AppCenter

* **[Fix]** Fix an issue that enables internal services even if App Center was disabled in previous sessions.
* **[Fix]** Fix an issue not to delete pending logs after maximum retries.

### AppCenterCrashes

* **[Improvement]** Improve session tracking to get appropriate session information for crashes if an application also uses Analytics.

### AppCenterPush

* **[Fix]** Fix "Missing Push Notification Entitlement" warning message after uploading an application to TestFlight and publishing to App Store.
* **[Improvement]** In previous versions, it was required to add code to `application:didReceiveRemoteNotification:fetchCompletionHandler` callback in your application delegate if you or 3rd party libraries already implemented this callback. This is no longer necessary.
    This is a **breaking change** for some use cases because it required modifications in your code. Not changing your implementation might cause push notifications to be received twice.
    * If you don't see any implementation of `application:didReceiveRemoteNotification:fetchCompletionHandler` callback in your application delegate, you don't need to do anything, there is no breaking change for you.
    * If you want to keep automatic forwarding disabled, you also don't need to do anything.
    * If your application delegate contains implementation of `application:didReceiveRemoteNotification:fetchCompletionHandler`, you need to remove the following code from your implementation of the callback. This is typically the case when you or your 3rd party libraries implement the callback.


      **Objective-C**
      ```objc
      BOOL result = [MSPush didReceiveRemoteNotification:userInfo];
      if (result) {
          completionHandler(UIBackgroundFetchResultNewData);
      } else {
          completionHandler(UIBackgroundFetchResultNoData);
      }
      ```

      **Swift**
      ```swift
      let result: Bool = MSPush.didReceiveRemoteNotification(userInfo)
      if result {
          completionHandler(.newData)
      }
      else {
          completionHandler(.noData)
      }
      ```

___

## Version 1.1.0

This version contains a bug fix and improvements.

### AppCenter

* **[Fix]** Fix a locale issue that doesn't properly report system locale if an application doesn't support current language.
* **[Improvement]** Change log level to make HTTP failures more visible, and add more logs.

### AppCenterDistribute

* **[Improvement]** Add Portuguese to supported languages, see [this folder](https://github.com/Microsoft/AppCenter-SDK-Apple/tree/develop/AppCenterDistribute/AppCenterDistribute/Resources) for a list of supported languages.
* **[Improvement]** Users with app versions that still use Mobile Center can directly upgrade to versions that use this version of App Center, without the need to reinstall.

___

## Version 1.0.1

This version contains a bug fix that is specifically for the App Center SDK for React Native.

### AppCenterCrashes

* **[Fix]** Fix an issue that impacted the App Center SDK for React Native.

## Version 1.0.0

### General Availability (GA) Announcement.
This version contains **breaking changes** due to the renaming from Mobile Center to App Center. In the unlikely event there was data on the device not sent prior to the update, that data will be discarded. This version introduces macOS support (preview).

### AppCenter

* **[Feature]** Now supports macOS (preview).
* **[Fix]** Don't send startService log while SDK is disabled.

### AppCenterAnalytics

* **[Feature]** Now supports macOS (preview).

### AppCenterCrashes

* **[Feature]** Now supports macOS (preview).

### AppCenterPush

* **[Feature]** Now supports macOS (preview).

### AppCenterDistribute

* **[Fix]** Fix a bug where unrecoverable HTTP error wouldn't popup the reinstall app dialog after an app restart.
* **[Improvement]** Adding missing translations.
* **[Known bug]** Checking for last updates will fail if the app was updating from a Mobile Center app. A pop up will show next time the app is restarted to ask for reinstallation.

___

## Version 0.14.1

This version contains bug fixes.

### MobileCenterCrashes

* **[Fix]** PLCrashReporter updated to v1.2.3, it fixes a recursion when processing exceptions.

### MobileCenterPush

* **[Fix]** Receiving a notification without message now forwards the message as a `nil` string instead of an `NSNull` object to the `MSPush` delegate.

___

## Version 0.14.0

This version contains improvements and a feature.

### MobileCenterDistribute

* **[Improvement]** More languages supported for localized texts, see [this folder](https://github.com/Microsoft/mobile-center-sdk-ios/tree/develop/MobileCenterDistribute/MobileCenterDistribute/Resources) for a list of supported languages.
* **[Improvement]** When in-app updates are disabled because of side-loading, a new dialog will inform user instead of being stuck on a web page. Dialog actions offer ignoring in-app updates or following a link to re-install from the portal. This new dialog has texts that are not localized yet.

### MobileCenterPush

* **[Feature]** Push now registers notifications on device simulators even though iOS won't produce a push token.

___

## Version 0.13.0

This version contains bug fixes and a new API.

### MobileCenter

* **[Feature]** Added an `sdkVersion` method to get the current version of Mobile Center SDK programmatically.
* **[Fix]** Fixed a database open failure when Mobile Center SDK is used with any other SQLite related libraries.

### MobileCenterCrashes

* **[Fix]** Fixed not sending crash logs when an application is crashed and relaunched from multitasking view.

### MobileCenterPush

* **[Fix]** Fixed sending push installation log twice after fresh install.

___

## Version 0.12.3

This version contains a bug fix when the frameworks are integrated on applications which are built on Xcode 8.

___

## Version 0.12.2

This version contains a bug fix and improvements. **Verified all functionalities against iOS 11 GM.**

### MobileCenterCrashes

* **[Improvement]** Added a millisecond precision to crash logs for more accurate log time.

### MobileCenterDistribute

* **[Improvement]** Improved swizzling behavior for deprecated `openURL` method if it is used by applications.
* **[Fix]** Fixed being stuck on activating in-app update. It is back to open Safari in-app page for activation.

___

## Version 0.12.1

This version contains bug fixes.

### MobileCenterCrashes

* **[Fix]** Fixed missing logs sent to server on crash.

### MobileCenterDistribute

* **[Fix]** Workaraound a bug on iOS 11 where the Safari in-app page remains stuck activating in-app update. It is now opening the Safari app.
* **[Fix]** Fixed update won't start until the app is explicitly closed on iOS 11.

___

## Version 0.12.0

This version contains bug fixes, an improvement and a new feature. When you update to this release, there will be **potential data loss** if an application installed with previous versions of MobileCenter SDK on devices that has pending logs which are not sent to server yet at the time of the application is being updated.

### MobileCenter

* **[Improvement]** Changed to send one crash or error attachment log at a time to prevent HTTP requests become bigger.
* **[Fix]** Fixed database access failure when an application contains other SQLite libraries for custom database.

### MobileCenterCrashes

* **[Fix]** Fixed duplicated logs sent to server on crash.

### MobileCenterDistribute

* **[Feature]** New feature that allows to share your applications to anyone with public link.

___

## Version 0.11.2

This version contains a bug fix that wasn't properly fixed in the previous release.

### MobileCenterCrashes

* **[Fix]** Fixed a bug that the Crashes picked up one next session after previous crash.

___

## Version 0.11.1

This version contains bug fixes and an improvement that changes the current behavior.

### MobileCenter

* **[Fix]** Fix bugs that sent multiple or empty service start logs at launch time.

### MobileCenterAnalytics

* **[Improvement]** Send truncated event name and properties instead of skipping it if its lengths are beyond the limits.

### MobileCenterCrashes

* **[Fix]** Fixes two bugs that caused error logs to be assiciated with wrong session information.

___

## Version 0.11.0

This version has a **breaking change** in the Crashes module and contains other bug fixes and improvements.

### MobileCenter

* **[Fix]** Fix a bug that caused logs to be discarded when re-enabling the sending of logs [#639](https://github.com/Microsoft/mobile-center-sdk-ios/pull/639).
* **[Misc]** This release replaces the file-based persistence with a sqlite-based implementation. This change does not require any change from your side.

### MobileCenterCrashes

* [**Breaking**] The SDK now uses Mach Exception Handling by default. Use `[MSCrashes disableMachExceptionHandler]`/`MSCrashes.disableMachExceptionHandler()` to disable that behavior. `[MSCrashes enableMachExceptionHandler]`/`MSCrashes.enableMachExceptionHandler()` has been removed [#637](https://github.com/Microsoft/mobile-center-sdk-ios/pull/637).

### MobileCenterPush

* **[Fix]** Fix a crash that was related to push notifications that were not intended for Mobile Center [#651](https://github.com/Microsoft/mobile-center-sdk-ios/pull/651).

___

## Version 0.10.1

This version contains a bug fix for crash attachments.

### MobileCenterCrashes

* **[Fix]** Fix crash attachments which were broken in 0.10.0. 

___

## Version 0.10.0

This version has **breaking changes**.
It contains improvements and new features.

### Integration using cocoapods

* **[Breaking]** The subspecs for cocoapods are now called `Analytics`, `Crashes`, `Distribute` and `Push` instead of `MobileCenter{MODULENAME}`.

### MobileCenter

* **[Feature]** It's possible to define custom properties. Custom properties can be used for various purposes, e.g. to segment users for targeted push notifications.

### MobileCenterCrashes

* **[Improvement]** The sdk now logs a warning in case more than two attachments have been attached to a crash. 

### MobileCenterDistribute

* **[Bug]** Fix a potential crash that occured in case the request for updates returned a 200 but the data was empty.

___

## Version 0.9.0

This version has **breaking changes**.
It contains improvements and new features.

### MobileCenter

* **[Feature]** Mobile Center now automatically forwards your application delegate's methods to the SDK. This is made possible by using method swizzling. It greatly improves the SDK integration but there is a possibility of conflicts with other third party libraries or the application delegate itself. In this case you may want to disable the Mobile Center application delegate forwarder by adding the `MobileCenterAppDelegateForwarderEnabled` tag to your Info.plist file and set it to `0`, doing so will disable application delegate forwarding for all Mobile Center services.

### MobileCenterCrashes

* **[Feature]** Crashes can now have attachments.

### MobileCenterDistribute

* **[Breaking]** The `openUrl:` API is renamed `openURL:` and returns `YES` if the URL is intended for Mobile Center Distribute and your application, `NO` otherwise.

* **[Breaking]** The application delegate `openURL` method(s) are now automatically forwarded to the SDK by default. The Mobile Center Distribute `openURL` can be removed from your application delegate's `openURL` method(s). If you decide to keep it then you will have to disable the Mobile Center application delegate forwarder.

### MobileCenterPush

* **[Breaking]** The application delegate `didRegisterForRemoteNotificationsWithDeviceToken`, `didFailToRegisterForRemoteNotificationsWithError`, `didReceiveRemoteNotification` methods are now automatically forwarded to the SDK by default. The corresponding APIs from Mobile Center Push can be removed from your application delegate's methods. If you decide to keep them then you will have to disable the Mobile Center application delegate forwarder.

___

## Version 0.8.1

This version contains a bug fix.

### MobileCenter

* **[Bug]** Fix logs not sent while application is back in foreground.

___

## Version 0.8.0

This release adds the Mobile Center Push module and contains additional improvements. The various test apps now contain individual icons so they are easily distinguishable when they are installed on a device.

### MobileCenter

* **[Improvement]** In case the developer has turned on a more verbose log level, the whole response body is logged to the Console.

### MobileCenterCrashes

* **[Improvement]** We have fixed a couple of log messages that indicated that something was going wrong when setting up Mobile Center Crashes when everything was actually working as expected. This confused a lot of people.

### MobileCenterPush

* **[Feature]** This is the first release that contains Mobile Center Push.

___

## Version 0.7.0

This version contains bug fixes, improvements and new features.

### MobileCenter

* **[Misc]** Change Channel to handle logs based on service instead of priority.
* **[Misc]** Fix all compile warnings and set configuration to consider all warnings as errors.

### MobileCenterAnalytics

* **[Misc]** Events have some validation and you will see the following in logs:
 
    * An error if the event name is null, empty or longer than 256 characters (event is not sent in that case).
    * A warning for invalid event properties (the event is sent but without invalid properties):
 
       * More than 5 properties per event (in that case we send only 5 of them and log warnings).
       * Property key null, empty or longer than 64 characters.
       * Property value null or longer than 64 characters.

### MobileCenterCrashes

* **[Misc]** Update PLCrashReporter to 1.2.2.

### MobileCenterDistribute

* **[Feature]** New Distribute delegate to provide an ability of in-app update customization.
* **[Feature]** New default update dialog with release notes view.

___

## Version 0.6.1

This version contains some bug fixes, improvements under the hood and renamed the demo apps to Sasquatch to be consistent with the Android SDK.

### MobileCenter

* **[Misc]** Limit UIKit usage.

### MobileCenterCrashes

* **[Bug]** Fix bug in LogBuffer implementation.

### MobileCenterDistribute

* **[Feature]**  Show an alert in case the update UI is shown but Distribute has been disabled.
* **[Bug]** Exit the app in case of a mandatory update on iOS 10.

### Puppet

* **[Bug]** Fixed navigaton issues in Puppet app.
 
### SasquatchSwift

* **[Feature]** Add ViewController that allows enabling/disabling Distribute. 

___

## Version 0.6.0

### MobileCenter

* **[Bug]** `setLogUrl` API can now be called at anytime.
* **[Bug]** 401 HTTP errors (caused by invalid appSecret) are now considered unrecoverable and are not retried.
* **[Misc]** A new log is sent to server when MobileCenter is started with the list of MobileCenter services used in the application.

### MobileCenterAnalytics

* **[Bug]** Fix session Id's toffset matching.

### MobileCenterCrashes

* **[Bug]** Restore log buffering and retrieving of device information from past sessions, log deduplication improved, crash logs not buffered.

### MobileCenterDistribute

* **[Feature]**  New service called Distribute to enable in-app updates for your Mobile Center builds.

___

## Version 0.5.1

This version reverts new implementations introduced in version 0.4.2.

### MobileCenterCrashes

* **[Bug]** Revert recent Crashes implementions of buffering logs and retrieving device information from past sessions in version 0.4.2 due to regression.

___

## Version 0.5.0

This version has a **breaking change**.

### MobileCenter

* **[Misc]** setServerUrl method has renamed to setLogUrl.

___

## Version 0.4.2

This version has features that are related to the quality of the provided crash reports as well as improvements under the hood across all parts of the SDK.

### MobileCenter

* **[Feature]** Services are now initialized depending on their priority and not by the order they are passed-in during initialization.
* **[Misc]** OCMock has been updated to version 3.4
* **[Misc]** We have made improvements to code formatting throughout the project.

### MobileCenterCrashes

* **[Feature]** Crashes now buffers logs to make sure no logs are lost in case of a crash. 
* **[Feature]** Crashes now retrieves the device information at the time of the crash by using a history of device information.
* **[Feature]** Crashes now has a property to enable the Mach exception handler. Please make sure to read the section in the readme about this feature.

___

## Version 0.4.1

This version has a bug fix.

### MobileCenterCrashes

* **[Bug]** Fix missing frames in thread for Crashes.

___

## Version 0.4.0

This version has **breaking changes**.

### MobileCenterCrashes

* **[Feature]** Remove attachmentWithCrashes method in Crashes delegate that is not supported by backend.

___

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
