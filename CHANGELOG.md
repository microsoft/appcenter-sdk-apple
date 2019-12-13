# App Center SDK for iOS, macOS and tvOS Change Log

## Version 2.5.3

### App Center

* **[Fix]** Improve log messages for errors when it failed to read/write auth token history.

### App Center Auth

* **[Fix]** Fix build warnings when adding App Center Auth framework in project.

### App Center Crashes

* **[Improvement]**  Report additional details for macOS exceptions thrown on the main thread.
* **[Fix]** Fix to send crashes when an application was launched in background and enters foreground.
* **[Fix]** Validate error attachment size to avoid server error or out of memory issues (using the documented limit which is 7MB).
* **[Fix]** Fix an issue where crash might contain incorrect data if two consecutive crashes occurred in a previous version of the application.

### App Center Distribute

* **[Fix]** Fix missing alert dialogs in apps that use iOS 13's new `UIScene` API (multiple scenes are not yet supported).
* **[Fix]** Fix an issue where users would sometimes be prompted multiple times to sign in with App Center.

___

## Version 2.5.1

### App Center

* **[Fix]** Fix warnings in Xcode 11 when SDK is installed via CocoaPods.

___

## Version 2.5.0

### App Center

* **[Fix]** Fix header issues with projects not using clang modules.

### App Center Crashes

* **[Feature]** iOS and macOS extensions support.

### App Center Data

* **[Fix]** Reduce retries on Data-related operations to fail fast and avoid the perception of calls "hanging".
* **[Fix]** Fix an issue where the optional delegate method `data:didCompletePendingOperation:forDocument:withError:` would throw an exception if not implemented (when using `MSData.setRemoteOperationDelegate`).

___

## Version 2.4.0

### App Center

* **[Feature]** App Center now supports Carthage integration.

### App Center Auth

* **[Fix]** Fix token storage initialization if services are started via `[MSAppCenter startService:]` method.
* **[Fix]** Redirect URIs are now hidden in logs.
* **[Fix]** Fix interactive sign in on iOS 13. Temporary fix, will be revisited in the future.
* **[Feature]** Updated the Microsoft Authentication Library dependency to v0.7.0.

### App Center Analytics

* **[Fix]** Fix crash involving SDK's `ms_viewWillAppear` method.

### App Center Crashes

* **[Behavior change]** `MSCrashesDelegate` callback methods are now invoked on the main thread (`crashes:willSendErrorReport:`,  `crashes:didSucceedSendingErrorReport:`, and `crashes:didFailSendingErrorReport:withError:`).

### App Center Data

* **[Breaking change]** Rename delegate method `data:didCompletePendingOperation:forDocument:withError:` from `MSRemoteOperationDelegate` to `data:didCompleteRemoteOperation:forDocumentMetadata:withError:`.

___

## Version 2.3.0

### App Center Auth

* **[Feature]** App Center Auth logging now includes MSAL logs.

### App Center Crashes

* **[Feature]** Catch "low memory warning" and provide the API to check if it has happened in last session: `MSCrashes.hasReceivedMemoryWarningInLastSession()`.
* **[Fix]** Fix main thread checker's warning during crash processing on macOS.

### App Center Distribute

* **[Fix]** Obfuscate app secret value that appears as URI part in verbose logs for in-app updates.

___

## Version 2.2.0

### App Center

* **[Feature]** Now supports tvOS.
* **[Feature]** Add `isRunningInAppCenterTestCloud` in `MSAppCenter` to provide method to check if the application is running in Test Cloud.
* **[Fix]** Drop and recreate the database when it is corrupted.

### App Center Analytics

* **[Feature]** Now supports tvOS.

### App Center Crashes

* **[Feature]** Now supports tvOS.

### App Center Data

* **[Feature]** Add support for offline list of documents.
* **[Feature]** Change the default time-to-live (TTL) from 1 day to infinite (never expire).
* **[Feature]** Add `readOptions` parameter to the `list` API.
* **[Feature]** Serialize `nil` and `NSNull` document values.

### App Center Distribute

* **[Fix]** Fix crash when an application was minimized on trying to reinstall after setup failure. 

___

## Version 2.1.0

### App Center

* **[Fix]** Remove Keychain permission pop-up on macOS.
* **[Fix]** Improve encryption security.

### App Center Analytics

* **[Feature]** Support setting latency of sending events via `[MSAnalytics setTransmissionInterval:]`.

### App Center Auth

* **[Feature]** Expose the ID Token and Access Token JWTs in the `MSUserInformation` object passed to the sign in callback.
* **[Fix]** Fix changing signing status may cause logs (e.g., events) to be delayed.
* **[Fix]** Validate custom URL scheme before starting Auth and log an error message when it is invalid.
* **[Fix]** Fix rare condition where a user is prompted again for their credentials instead of refreshing the token silently.

### App Center Data

* **[Fix]** Fix an issue where invalid characters in the document ID are accepted at creation time but causing errors while trying to read or delete the document. The characters are `#`, `\`, `/`, `?`, and all whitespaces.
* **[Feature]** Added `setRemoteOperationDelegate` method to set a delegate to be notified of a pending operation being executed when the client device goes from offline to online.

___

## Version 2.0.1

Version 2.0.1 of the App Center SDK includes two new modules: Auth and Data. This version has a **breaking change**, it only supports Xcode 10.0.0+.

### App Center Auth

App Center Auth is a cloud-based identity management service that enables you to authenticate users and manage their identities. You can also leverage user identities in other App Center services. **iOS only, not available for macOS*.

### App Center Data

The App Center Data service provides functionality enabling developers to persist app data in the cloud in both online and offline scenarios. This enables you to store and manage both user-specific data as well as data shared between users and across platforms. **iOS only, not available for macOS*.

### App Center Crashes

* **[Feature]** After calling `[MSAuth signInWithCompletionHandler:]`, the next crashes are associated with an `accountId` corresponding to the signed in user. This is a different field than the `userId` set by `[MSAppCenter setUserId:]`. Calling `[MSAuth signOut]` stops the `accountId` association for the next crashes.
* **[Fix]** Print an error and return immediately when calling `[MSCrashes notifyWithUserConfirmation:]` with confirmation handlers not implemented.

### App Center Distribute

* **[Fix]** Starting the application with "Guided Access" enabled blocks the update flow since in-app update is not possible in this mode.

### App Center Push

* **[Feature]** After calling `[MSAuth signInWithCompletionHandler:]`, the push installation is associated to the signed in user with an `accountId` and can be pushed by using the `accountId` audience. This is a different field than the `userId` set by `[MSAppCenter setUserId:]`. The push installation is also updated on calling `[MSAuth signOut]` to stop the association.
* **[Fix]** Fix updating push installation when setting the user identifier via  `[MSAppCenter setUserId:]`.

___

## Version 1.14.0

### App Center

* **[Fix]** Fix a crash in case decrypting a value failed.

### App Center Analytics

* **[Feature]** Preparation work for a future change in transmission protocol and endpoint for Analytics data on macOS. There is no impact on your current workflow when using App Center.

### App Center Push

* **[Fix]** Fix crash on invoking an optional push callback when it isn't implemented in the push delegate.

___

## Version 1.13.2

### App Center

* **[Fix]** Fix a crash if database query failed.

### App Center Distribute

* **[Fix]** Fix a race condition crash on upgrading the application to newer version.

___

## Version 1.13.1

### App Center

* **[Fix]** Fix a possible deadlock if the SDK is started from a background thread.
* **[Feature]** Add class method  `+ [MSAppCenter setCountryCode:]` that allows manually setting the country code on platforms where there is no carrier information available.

___

## Version 1.13.0

### App Center

* **[Fix]** Fix issue where the SDK source could not be built in a directory that contains escaped characters (applies to all modules).

### App Center Analytics

* **[Feature]** Preparation work for a future change in transmission protocol and endpoint for Analytics data. There is no impact on your current workflow when using App Center.

___

## Version 1.12.0

### App Center

* **[Feature]** Allow users to set userId that applies to crashes, error and push logs. This feature adds an API, but is not yet supported on the App Center backend.
* **[Fix]** Do not delete old logs when trying to add a log larger than the maximum storage capacity.
* **[Fix]** Fix minimum storage size verification to match minimum possible value.
* **[Fix]** Fix reporting carrier information using new iOS 12 APIs when running on iOS 12+.
* **[Fix]** Fix a memory leak issue during executing SQL queries.
* **[Fix]** Fix a keychain permission issue on macOS applications.
* **[Feature]** Add preview support for arm64e CPU architecture.

### App Center Analytics

* **[Feature]** Add preview support for arm64e CPU architecture.

### App Center Crashes

* **[Feature]** Add preview support for arm64e CPU architecture by using PLCrashReporter 1.2.3-rc1. PLCrashReporter 1.2.3-rc1 is a fork of the official repository and can be found at [https://github.com/Microsoft/PLCrashReporter](https://github.com/Microsoft/PLCrashReporter). It is maintained by the [App Center](https://appcenter.ms) team and based on PLCrashReporter 1.2.1 (commit [fda23306](https://github.com/Microsoft/PLCrashReporter/tree/fda233062b5586f5d01cc527af643168665226c0)) with additional fixes and changes.

### App Center Distribute

* **[Feature]** Add preview support for arm64e CPU architecture.

### App Center Push

* **[Feature]** Add preview support for arm64e CPU architecture.

___

## Version 1.11.0

### App Center

* **[Fix]** Fix an issue where concurrent modification of custom properties was not thread safe.
* **[Fix]** Fix validating and discarding Not a Number (NaN) and infinite double values for custom properties.
* **[Fix]** Use standard SQL syntax to avoid affecting users with custom SQLite libraries.
* **[Fix]** Get database page size dynamically to support custom values.

### App Center Analytics

* **[Feature]** Add new trackEvent APIs that take priority (normal or critical) of event logs. Events tracked with critical flag will take precedence over all other logs except crash logs (when AppCenterCrashes is enabled), and only be dropped if storage is full and must make room for newer critical events or crashes logs.

### App Center Crashes

* **[Fix]** Do not force crash macOS application on uncaught exception. If you need this behavior you can set the special flag yourself:

    ```objc
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"NSApplicationCrashOnExceptions" : @YES }];
    ```

### App Center Push

* **[Fix]** Fix `push:didReceivePushNotification:` callback not triggered on notification tapped or received in foreground when a `UNUserNotificationCenterDelegate` is set.  If you have implemented this delegate please remove any call to the `MSPush#didReceiveRemoteNotification:` method as it's now handled by the new [User Notification Center Delegate Forwarder](https://docs.microsoft.com/appcenter/sdk/push/ios).

___

## Version 1.10.1

This version contains a bug fix for macOS.

### App Center Crashes

* **[Fix]** Fix a regression that was introduced in 1.10.0 on macOS. It caused crash reports to contain an incomplete list of loaded binary images.

___

## Version 1.10.0

### App Center

* **[Fix]** Add missing network request error logging.
* **[Feature]** Add a `setMaxStorageSize` API which allows setting a maximum size limit on the local SQLite storage.

### App Center Analytics

* **[Feature]** Add `pause`/`resume` APIs which pause/resume sending Analytics logs to App Center.
* **[Feature]** Adding support for typed properties. Note that these APIs still convert properties back to strings on the App Center backend. More work is needed to store and display typed properties in the App Center portal. Using the new APIs now will enable future scenarios, but for now the behavior will be the same as it is for current event properties.
* **[Feature]** Preparation work for a future change in transmission protocol and endpoint for Analytics data. There is no impact on your current workflow when using App Center.
* **[Fix]** Fix an bug where nested custom properties for an event would not pass validation.

### App Center Crashes

* **[Fix]** Fix the list of binary images in crash reports for arm64e-based devices.

### App Center Distribute

* **[Fix]** Fix translation of closing a dialog in Portuguese.

___

## Version 1.9.0

This version contains bug fixes and a feature.

### App Center

* **[Fix]** Fix a potential deadlock that can freeze the application launch causing the iOS watchdog to kill the application.

### App Center Crashes

* **[Fix]** The above deadlock was mostly impacting the Crashes module.

### App Center Analytics

* **[Feature]** Preparation work for a future change in transmission protocol and endpoint for Analytics data. There is no impact on your current workflow when using App Center.

___

## Version 1.8.0

This version contains bug fixes and a feature.

### App Center Distribute

* **[Fix]** Fix in-app update occasional initialization failure caused by deletion of update token/group id on HTTP status code '0'.
* **[Fix]** Fix Chinese translation of "side-loading".

### App Center Analytics

* **[Feature]** Preparation work for a future change in transmission protocol and endpoint for Analytics data. There is no impact on your current workflow when using App Center.

___

## Version 1.7.1

This version contains a bug fix.

### App Center

* **[Fix]** Fix duplicate symbol errors discovered when using Xamarin wrapper SDK.

___

## Version 1.7.0

This version contains a new feature and an improvement.

### App Center

* **[Improvement]** Gzip is used over HTTPS when request size is larger than 1.4KB.

### App Center Analytics

* **[Feature]** Preparation work for a future change in transmission protocol and endpoint for Analytics data. There is no impact on your current workflow when using App Center.

___

## Version 1.6.1

This version contains bug fixes. 

### App Center Crashes

* **[Fix]** Fix an issue in breadcrumbs feature when events are being tracked on the main thread just before a crash.
* **[Fix]** Fix an issue with cached logs for breadcrumbs feature which are sometimes not sent during app start.

___

## Version 1.6.0

This version contains an improvement and bug fixes. Any macOS app with unsent logs prior to the update will discard these logs.

### App Center

* **[Fix]** Fix non app store macOS apps were sharing the same DB. 

### App Center Analytics

* **[Improvement]** Analytics now allows a maximum of 20 properties by event, each property key and value length can be up to 125 characters long.

### App Center Crashes

* **[Fix]** Fix enabling uncaught exception handler when a wrapper SDK is in use. 

___

## Version 1.5.0

This version contains a new feature.

### App Center Distribute

* **[Feature]** Add Session statistics for distribution group.

___

## Version 1.4.0

This version contains a new feature.

### App Center Distribute

* **[Feature]** Add reporting of downloads for in-app update.
* **[Improvement]** Add distribution group to all logs that are sent.

___

## Version 1.3.0

This version has a **breaking change** as the SDK now requires iOS 9 or later. It also contains a bug fix and an improvement.

### App Center

* **[Improvement]** Successful configuration of the SDK creates a success message in the console with log level INFO instead of ASSERT. Errors during configuration will still show up in the console with the log level ASSERT.

### App Center Crashes

* **[Fix]** Fix an issue where crashes were not reported reliably in some cases when used in Xamarin apps or when apps would take a long time to launch.

___

## Version 1.2.0

This version has a **breaking change** with bug fixes and improvements.

### App Center

* **[Fix]** Fix an issue that enables internal services even if App Center was disabled in previous sessions.
* **[Fix]** Fix an issue not to delete pending logs after maximum retries.

### App Center Crashes

* **[Improvement]** Improve session tracking to get appropriate session information for crashes if an application also uses Analytics.

### App Center Push

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

### App Center

* **[Fix]** Fix a locale issue that doesn't properly report system locale if an application doesn't support current language.
* **[Improvement]** Change log level to make HTTP failures more visible, and add more logs.

### App Center Distribute

* **[Improvement]** Add Portuguese to supported languages, see [this folder](https://github.com/microsoft/appcenter-sdk-apple/tree/develop/AppCenterDistribute/AppCenterDistribute/Resources) for a list of supported languages.
* **[Improvement]** Users with app versions that still use Mobile Center can directly upgrade to versions that use this version of App Center, without the need to reinstall.

___

## Version 1.0.1

This version contains a bug fix that is specifically for the App Center SDK for React Native.

### App Center Crashes

* **[Fix]** Fix an issue that impacted the App Center SDK for React Native.

## Version 1.0.0

### General Availability (GA) Announcement.
This version contains **breaking changes** due to the renaming from Mobile Center to App Center. In the unlikely event there was data on the device not sent prior to the update, that data will be discarded. This version introduces macOS support (preview).

### App Center

* **[Feature]** Now supports macOS (preview).
* **[Fix]** Don't send startService log while SDK is disabled.

### App Center Analytics

* **[Feature]** Now supports macOS (preview).

### App Center Crashes

* **[Feature]** Now supports macOS (preview).

### App Center Push

* **[Feature]** Now supports macOS (preview).

### App Center Distribute

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

* **[Fix]** Workaround a bug on iOS 11 where the Safari in-app page remains stuck activating in-app update. It is now opening the Safari app.
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

* **[Fix]** Fixes two bugs that caused error logs to be associated with wrong session information.

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

* **[Bug]** Fix a potential crash that occurred in case the request for updates returned a 200 but the data was empty.

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

* **[Bug]** Fixed navigation issues in Puppet app.
 
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

* **[Bug]** Revert recent Crashes implementations of buffering logs and retrieving device information from past sessions in version 0.4.2 due to regression.

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
* **[Feature]** Allow wrapper SDKs such as Xamarin to store additional crash data files.
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
