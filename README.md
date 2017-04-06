[![Build Status](https://www.bitrise.io/app/e5b1a2ef546331fb.svg?token=Orwi_AVAExLTuN1ZAzvbFQ&branch=develop)](https://www.bitrise.io/app/e5b1a2ef546331fb)
[![codecov](https://codecov.io/gh/Microsoft/mobile-center-sdk-ios/branch/develop/graph/badge.svg?token=6dlCB5riVi)](https://codecov.io/gh/Microsoft/mobile-center-sdk-ios)
[![CocoaPods](https://img.shields.io/cocoapods/v/MobileCenter.svg)](https://cocoapods.org/pods/MobileCenter)
[![CocoaPods](https://img.shields.io/cocoapods/dt/MobileCenter.svg)](https://cocoapods.org/pods/MobileCenter)
[![license](https://img.shields.io/badge/license-MIT%20License-00AAAA.svg)](https://github.com/Microsoft/mobile-center-sdk-ios/blob/develop/LICENSE)

# Mobile Center SDK for iOS

## Introduction

Add Mobile Center services to your app and collect crash reports and understand user behavior by analyzing the session, user and device information for your app. The SDK currently supports the following services:

1. **Analytics**: Mobile Center Analytics helps you understand user behavior and customer engagement to improve your iOS app. The SDK automatically captures session count, device properties like model, OS version etc. and pages. You can define your own custom events to measure things that matter to your business. All the information captured is available in the Mobile Center portal for you to analyze the data.

2. **Crashes**: The Mobile Center SDK will automatically generate a crash log every time your app crashes. The log is first written to the device's storage and when the user starts the app again, the crash report will be forwarded to Mobile Center. Collecting crashes works for both beta and live apps, i.e. those submitted to App Store. Crash logs contain valuable information for you to help resolve the issue. Crashes uses PLCrashReporter 1.2.1.

3. **Distribute**: The Mobile Center SDK will let your users install a new version of the app when you distribute it via Mobile Center. With a new version of the app available, the SDK will present an update dialog to the users to either download or ignore the latest version. Once they tap "Download", the SDK will start to update your application. Note that this feature will `NOT` work if your app is deployed to the app store, if you are developing locally or if the app is a running with the DEBUG configuration.

This document contains the following sections:

1. [Prerequisites](#1-prerequisites)
2. [Integrate the SDK](#2-integrate-the-sdk)
3. [Start the SDK](#3-start-the-sdk)
4. [Analytics APIs](#4-analytics-apis)
5. [Crashes APIs](#5-crashes-apis)
6. [Distribute APIs](#6-distribute-apis)
7. [Advanced APIs](#7-advanced-apis)
8. [Troubleshooting](#8-troubleshooting)
9. [Contributing](#9-contributing)
10. [Contact](#10-contact)

Let's get started with setting up the Mobile Center SDK in your app to use these services.

## 1. Prerequisites

Before you begin, please make sure that the following prerequisites are met:

* An iOS project that is set up in Xcode 8.0 on macOS 10.11 or later.
* The minimum OS target supported by the Mobile Center SDK is iOS 8.0 or later.
* If you are using cocoapods, please use cocoapods 1.1.1 or later.
* This readme assumes that you are using Objective-C or Swift 3 syntax and that you want to integrate all services.

## 2. Integrate the SDK

The Mobile Center SDK is designed with a modular approach – you only need to integrate the modules of the services that you are interested in.

You can either integrate the MobileCenter SDK by adding it's binaries to your Xcode project (Step 2.1), or by using Cocoapods (Step 2.2).

### 2.1 Integration by copying the binaries into your project

Below are the steps on how to integrate the compiled libraries in your Xcode project to setup the Mobile Center SDK for your iOS app.

1. Download the [Mobile Center SDK](https://github.com/Microsoft/mobile-center-sdk-ios/releases) frameworks provided as a zip file.

2. Unzip the file and you will see a folder called `MobileCenter-SDK-iOS` that contains different frameworks for each Mobile Center service. There is a framework called `MobileCenter`, which is required in the project as it contains the logic for persistence, forwarding,... . 

3. [Optional] Create a subdirectory for 3rd-party-libraries.
	* As a best practice, 3rd-party libraries usually reside inside a subdirectory, so if you don't have your project organized with a subdirectory for libraries, now would be a great start for it. This subdirectory is often called `Vendor`.
	* Create a group called `Vendor` inside your Xcode project to mimic your file structure on disk.

4. Open Finder and copy the previously unzipped `MobileCenter-SDK-iOS` folder into your project's folder at the location where you want it to reside. 
   
5. Add the SDK frameworks and resources to the project in Xcode:
    * Make sure the Project Navigator is visible (⌘+1).
    * Now drag and drop `MobileCenter.framework`, `MobileCenterAnalytics.framework`, `MobileCenterCrashes.framework`, `MobileCenterDistribute.framework` and `MobileCenterDistributeResources.bundle` from Finder (the ones inside the Vendor folder) into Xcode's Project Navigator on the left side. Note that `MobileCenter.framework` is required to start the SDK. So make sure it's added to your project, otherwise the other modules won't work and your app won't compile.
    * A dialog will appear again. Make sure your app target is checked. Then click Finish.

Now that you've integrated the frameworks in your application, it's time to start the SDK and make use of the Mobile Center services.

### 2.2 Integration using Cocoapods

[CocoaPods](http://cocoapods.org/) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like Mobile Center in your projects. To learn how to setup CocoaPods for your project, visit [the official CocoaPods website](http://cocoapods.org/).

1. Add the following to your `podfile` to include all services into your app. This will pull in `MobileCenter`, `MobileCenterAnalytics` and `MobileCenterCrashes`. Alternatively, you can specify which services you want to use in your app. Each service has it's own `subspec` and they all rely on `MobileCenter`. It will get pulled in automatically.

	```ruby
	 # Use the following line to use all services.
	pod 'MobileCenter'
		  
	# Use the following lines if you want to specify the individual services you want to use.
	pod 'MobileCenter/MobileCenterAnalytics'
	pod 'MobileCenter/MobileCenterCrashes'
	pod 'MobileCenter/MobileCenterDistribute`
	```

2. Run `pod install` to install your newly defined pod, open your `.xcworkspace` and it's time to start the SDK and make use of the Mobile Center services.

## 3. Start the SDK

To start the Mobile Center SDK in your app, follow these steps:

### 1. Add `import` statements  
You need to add import statements for MobileCenter, MobileCenterAnalytics, MobileCenterCrashes and MobileCenterDistribute modules before starting the SDK. If you have chosen to only use a subset of Mobile Center's services, just add the import for MobileCenter and the one for the service that you want to use.
    
**Objective-C**   
Open your AppDelegate.m file and add the following lines at the top of the file below your own import statements.   
    
```objectivec
@import MobileCenter;
@import MobileCenterAnalytics;
@import MobileCenterCrashes;
@import MobileCenterDistribute;
```

**Swift**   
Open your AppDelegate.swift file and add the following lines.   
    
```swift
import MobileCenter
import MobileCenterAnalytics
import MobileCenterCrashes
import MobileCenterDistribute
``` 

### 2. Start the SDK

Mobile Center provides you with four modules to get started: `MobileCenter` (required), `MobileCenterAnalytics`,  `MobileCenterCrashes` and  `MobileCenterDistribute` (all but the first one are optional). In order to use Mobile Center services, you need to opt in for the module(s) that you'd like, meaning by default no modules are started and you will have to explicitly call each of them - Analytics, Crashes and Distribute when starting the SDK.

**Objective-C** 

Add the following line to start the SDK in your app's AppDelegate.m class in the `application:didFinishLaunchingWithOptions:` method.  
    
```objectivec
[MSMobileCenter start:@"{Your App Secret}" withServices:@[[MSAnalytics class], [MSCrashes class], [MSDistribute class]]];
```

**Swift**   

Insert the following line to start the SDK in your app's AppDelegate.swift class in the `application(_:didFinishLaunchingWithOptions:)` method.   
    
```swift
MSMobileCenter.start("{Your App Secret}", withServices: [MSAnalytics.self, MSCrashes.self, MSDistribute.self])
```    
    
You can also copy paste the `start` method call from the Overview page on Mobile Center portal once your app is selected. It already includes the App Secret so that all the data collected by the SDK corresponds to your application. Make sure to replace `{Your App Secret}` text with the actual value for your application.
    
The example above shows how to use the `start` method and include all the services offered in the SDK. If you wish not to use any of these services - say Analytics, remove the parameter from the method call above. Note that, unless you explicitly specify each module as parameters in the start method, you can't use that Mobile Center service. Also, the `start` API can be used only once in the lifecycle of your app – all other calls will log a warning to the console and only the modules included in the first call will be available.

### 3. Enable MSDistribute to provide in-app-updates

1. Open your `Info.plist`.
2. Add a new key for `URL types` or `CFBundleURLTypes` (in case Xcode displays your `Info.plist` as source code).
3. Change the key of the first child item to URL Schemes or `CFBundleURLSchemes`.
4. Enter `mobilecenter-${APP_SECRET}` as the URL scheme and replace `${APP_SECRET}` with the App Secret of your app.
5. Implement the `openURL`-callback in your `AppDelegate` to enable in-app-updates.

**Objective-C**

```objectivec
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
         
  // Pass the url to MSDistribute.
  [MSDistribute openUrl:url];
  return YES;
}

```

**Swift**

```swift
func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
    
  // Pass the URL to MSDistribute.
  MSDistribute.open(url as URL!)
  return true
}
```

## 4. Analytics APIs

### Track Session and device properties

Once the Analytics module is included in your app and the SDK is started, it will automatically track sessions, device properties like OS version, model, manufacturer etc. and you don’t need to add any additional code.

Look at the section above on how to [Start the SDK](#3-start-the-sdk) if you haven't started it yet.

### Custom events

You can track your own custom events with specific properties to know what's happening in your app, understand user actions, and see the aggregates in the Mobile Center portal. Once you have started the SDK, use the `trackEvent` method to track your events with properties.

**Objective-C**

```objectivec
NSDictionary *properties = @{@"Category" : @"Music", @"FileName" : @"favorite.avi"};
[MSAnalytics trackEvent:@"Video clicked" withProperties: properties];
```

**Swift**

```swift
MSAnalytics.trackEvent("Video clicked", withProperties: ["Category" : "Music", "FileName" : "favorite.avi"])
```    
    
Properties for events are entirely optional. If you just want to track an event use this sample instead:

**Objective-C**
    
```objectivec
[MSAnalytics trackEvent:@"Video clicked"];
```

**Swift**
    
```swift
MSAnalytics.trackEvent("Video clicked")
```

### Enable or disable Analytics

You can change the enabled state of the Analytics service at runtime by calling the `setEnabled` method. If you disable it, the SDK will not collect any more analytics information for the app. To re-enable it, pass `true` as a parameter in the same method.

**Objective-C**

```objectivec
[MSAnalytics setEnabled:NO];
```

**Swift**

```swift
MSAnalytics.setEnabled(false)
```

You can also check if the service is enabled or not using the `isEnabled` method:

**Objective-C**

```objectivec
BOOL enabled = [MSAnalytics isEnabled];
```

**Swift**

```swift
var enabled = MSAnalytics.isEnabled()
```
    
## 5. Crashes APIs

Once you set up and start the Mobile Center SDK to use the Crashes service in your application, the SDK will automatically start logging any crashes in the devices local storage. When the user opens the application again after a crash, all pending crash logs will automatically be forwarded to Mobile Center and you can analyze the crash along with the stack trace on the Mobile Center portal. Refer to the section to [Start the SDK](#3-start-the-sdk) if you haven't done so already.

### Generate a test crash:
The SDK provides you with a static API to generate a test crash for easy testing of the SDK:

**Objective-C**

```objectivec
[MSCrashes generateTestCrash];
```

**Swift**

```swift
MSCrashes.generateTestCrash()
```

**Note that this API will only work for development and test apps. The method will not be functioning once the app is distributed through the App Store.**

### Did the app crash in the last session?

At any time after starting the SDK, you can check if the app crashed in the previous session:

**Objective-C**

```objectivec
[MSCrashes hasCrashedInLastSession];
```

**Swift**

```swift
MSCrashes.hasCrashedInLastSession()
```

### Details about the last crash

If your app crashed previously, you can get details about the last crash:

**Objective-C**

```objectivec
MSErrorReport *crashReport = [MSCrashes lastSessionCrashReport];
```

**Swift**

```swift
var crashReport = MSCrashes.lastSessionCrashReport()
```

### Enable or disable Crashes

You can disable and opt out of using Crashes by calling the `setEnabled` API and the SDK will collect no more crashes for your app. Use the same API to re-enable it by passing `YES` or `true` as a parameter.

**Objective-C**

```objectivec
[MSCrashes setEnabled:NO];
```

**Swift**

```swift
MSCrashes.setEnabled(false)
```
    
You can also check if the service is enabled or not using the `isEnabled` method:

**Objective-C**

```objectivec
BOOL enabled = [MSCrashes isEnabled];
```

**Swift**

```swift
var enabled = MSCrashes.isEnabled()
```

### Advanced Scenarios

If you are using the Crashes service, you can customize the way the SDK handles crashes. The `MSCrashesDelegate`-protocol describes methods to wait for user confirmation and register for callbacks that inform your app about the sending status.

#### Register as a delegate

 **Objective-C**
 
```objectivec
[MSCrashes setDelegate:self];
```

**Swift**

```swift
MSCrashes.setDelegate(self)
```

The SDK provides the following delegate methods.  
    
#### Should the crash be processed?

Implement the following delegate methods if you'd like to decide if a particular crash needs to be processed or not. For example - there could be some system level crashes that you'd want to ignore and don't want to send to Mobile Center.

**Objective-C**

```objectivec
- (BOOL)crashes:(MSCrashes *)crashes shouldProcessErrorReport:(MSErrorReport *)errorReport {
  return YES; // return YES if the crash report should be processed, otherwise NO.
}
```

**Swift**

```swift
func crashes(_ crashes: MSCrashes!, shouldProcessErrorReport errorReport: MSErrorReport!) -> Bool {
	objectivecreturn true; // return true if the crash report should be processed, otherwise false.
}
```
        
#### User confirmation

By default the SDK automatically sends crash reports to Mobile Center. However, the SDK exposes a callback where you can tell it to await user confirmation before sending any crash reports. This requires at least one additional step.

#### Step 1: Set a user confirmation handler.
	
Your app is responsible for obtaining confirmation, e.g. through a dialog prompt with one of these options - "Always Send", "Send", and "Don't Send". You need inform the SDK about the users input and the crash will handled accordingly. The method takes a block as a parameter, use it to pass in your logic to present the UI to confirm a crash report. As of iOS 8, `UIAlertView` has been deprecated in favor of `UIAlertController`. MobileCenterCrashes itself does not contain logic to show a confirmation to the user, but our Sample apps `Puppet` and `Demo` include [a reference implementation](https://github.com/Microsoft/mobile-center-sdk-ios/tree/develop/Vendor/MSAlertController/MSAlertController.h) which will be used in the following code snippets. For a full implementation, clone this repo and check out our apps **Puppet** and **Demo** and copy `MSAlertViewController` to your app. 

**Objective-C**
	
```objectivec
 // Use MSAlertViewController to show a dialog to the user where they can choose if they want to provide a crash report.
MSAlertController *alertController = [MSAlertController alertControllerWithTitle:@"The app quit unexpectedly."
                                                                         message:@"Would you like to send an anonymous report so we can fix the problem?"];

// Add a "No"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationDontSend
[alertController addCancelActionWithTitle:@"Don't Send"
                                  handler:^(UIAlertAction *action) {
                                      [MSCrashes notifyWithUserConfirmation:MSUserConfirmationDontSend];
 								   }];

// Add a "Yes"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationSend
[alertController addDefaultActionWithTitle:@"Send"
                                   handler:^(UIAlertAction *action) {
                                       [MSCrashes notifyWithUserConfirmation:MSUserConfirmationSend];
								   }];

// Add a "No"-Button and call the notifyWithUserConfirmation-callback with MSUserConfirmationAlways
[alertController addDefaultActionWithTitle:@"Always Send"
                                   handler:^(UIAlertAction *action) {
                                       [MSCrashes notifyWithUserConfirmation:MSUserConfirmationAlways];
                                   }];
// Show the alert controller.
[alertController show];
	
	
	// 2. You could also iterate over the array of error reports and base your decision on them.
		
return YES; // Return YES if the SDK should await user confirmation, otherwise NO.
}
```
	
**Swift**
	
```swift
MSCrashes.setUserConfirmationHandler({ (errorReports: [MSErrorReport]) in
	  
	// Present your UI to the user, e.g. an UIAlertView.

   var alert = MSAlertController(title: "The app quit unexpectedly.",
   										message: "Would you like to send an anonymous report so we can fix the problem?")            
   
   alert?.addDefaultAction(withTitle: "Yes", handler: {
   		MSCrashes.notify(with: MSUserConfirmation.send)
   })
   
   alert?.addDefaultAction(withTitle: "Always", handler: {
       MSCrashes.notify(with: MSUserConfirmation.always)
   })
            
   alert?.addCancelAction(withTitle: "No", handler: {
       MSCrashes.notify(with: MSUserConfirmation.dontSend)
   })
	  
	return true // Return true if the SDK should await user confirmation, otherwise return false.
})
```

#### Step 2: If you are using a different approach than the MSAlertController to present UI to your user.
	    
The code above already calls the `MSCrashes`-API to notify the crashes service about the users decision.
If you are not using this implementation, make sure to return `YES`/`true` in step 1, present your custom UI to the user to obtain user permission and message the SDK with the result using the following API. If you are using a UIAlertView for this, you would call it from within your implementation of the `alertView:clickedButtonAtIndex:`-callback.

**Objective-C**
	
```objectivec
// Depending on the users's choice, call notifyWithUserConfirmation: with the right value.
[MSCrashes notifyWithUserConfirmation:MSUserConfirmationDontSend];
[MSCrashes notifyWithUserConfirmation:MSUserConfirmationAlways];
[MSCrashes notifyWithUserConfirmation:MSUserConfirmationSend];
```
	
**Swift**
	
```swift
// Depending on the user's choice, call notify(with:) with the right value.
MSCrashes.notify(with: MSUserConfirmation.dontSend)
MSCrashes.notify(with: MSUserConfirmation.send)
MSCrashes.notify(with: MSUserConfirmation.always)

```

### Sending status

If you want know the status of the crash sending, maybe to present custom UI like a spinner, the Crashes services offers 3 callbacks to notify the host app about the sending status.

#### Before sending a crash report

This callback will be invoked just before the crash is sent to Mobile Center:

**Objective-C**

```objectivec
- (void)crashes:(MSCrashes *)crashes willSendErrorReport:(MSErrorReport *)errorReport {
   // Your code, e.g. to present a custom UI.
}
```

**Swift**

```swift
func crashes(_ crashes: MSCrashes!, willSend errorReport: MSErrorReport!) {
   // Your code, e.g. to present a custom UI.
}

```

#### Sending a crash report was successfull

This callback will be invoked after sending a crash report succeeded:

**Objective-C**

```objectivec
- (void)crashes:(MSCrashes *)crashes didSucceedSendingErrorReport:(MSErrorReport *)errorReport {
   	// Your code, e.g. to hide the custom UI.
}
```

**Swift**

```swift
func crashes(_ crashes: MSCrashes!, didSucceedSending errorReport: MSErrorReport!) {
   	// Your code, e.g. to hide the custom UI.
}
```

#### Sending a crash report failed

This callback will be invoked after sending a crash report failed:

**Objective-C**

```objectivec
- (void)crashes:(MSCrashes *)crashes didFailSendingErrorReport:(MSErrorReport *)errorReport withError:(NSError *)error {
  	// Your code, e.g. to hide the custom UI.
}
```

**Swift**

```swift
func crashes(_ crashes: MSCrashes!, didFailSending errorReport: MSErrorReport!, withError error: Error!) {
   	// Your code, e.g. to hide the custom UI.    
}
```

### Enabling Mach exception handling  

By default, the SDK is using the safe and proven in-process BSD Signals for catching crashes. This means, that some causes for crashes, e.g. stack overflows, cannot be detected. Using a Mach exception server instead allows to detect some of those crash causes but comes with the risk of using unsafe means to detect them.

The `enableMachExceptionMethod` provides an option to enable catching fatal signals via a Mach exception server instead.

The SDK will not check if the app is running in an AppStore environment or if a debugger was attached at runtime because some developers chose to do one or both at their own risk.

**We strongly advice NOT to enable Mach exception handler in release versions of your apps!**

The Mach exception handler executes in-process and will interfere with debuggers when they attempt to suspend all active threads (which will include the Mach exception handler). Mach-based handling should _NOT_ be used when a debugger is attached. The SDK will not enable crash reporting if the app is **started** with the debugger running. If you attach the debugger **at runtime**, this may cause issues if the Mach exception handler is enabled!

If you want or need to enable the Mach exception handler, you _MUST_ call this method _BEFORE_ starting the SDK.

Your typical setup code would look like this:

**Objective-C**

```objectivec
[MSCrashes enableMachExceptionHandler];
[MSMobileCenter start:@"YOUR_APP_ID" withServices:@[[MSAnalytics class], [MSCrashes class]]];
```

**Swift**

```swift
 MSCrashes.enableMachExceptionHandler()
 MSMobileCenter.start("YOUR_APP_ID", withServices: [MSAnalytics.self, MSCrashes.self])
```


## 6. Distribute APIs

You can easily let your users get the latest version of your app by integrating the `Distribute` service of the Mobile Center SDK. Please follow the paragraph in [Start the SDK](#3-start-the-sdk) to setup the Distribute service.

Once that is done, the SDK checks for new updates once per the app's lifetime. If the app is currently in the foreground or suspended in the background, you might need to kill the app to get the latest update. If it finds a new update, users will see a dialog with three options - `Download`, `Postpone` and `Ignore`. If the user presses `Download`, the SDK will trigger the new version to be installed. `Postpone` will delay the download until the app is opened again. `Ignore` will not prompt the user again for that particular app version.

### Localization of the update UI

You can easily provide your own resource strings if you'd like to localize the text displayed in the update dialog. Look at the string files [here](https://github.com/Microsoft/mobile-center-sdk-ios/blob/develop/MobileCenterDistribute/MobileCenterDistribute/Resources/en.lproj/MobileCenterDistribute.strings). Use the same string name and specify the localized value to be reflected in the dialog in your own app resource files.  

### Enable or disable Distribute

You can change the enabled state by calling the `setEnabled` API. If you disable it, the SDK will not prompt your users when a new version is available for install. To re-enable it, pass `YES` or `true` as a parameter in the same method.

**Objective-C**

```objectivec
[MSDistribute setEnabled:NO];
```

**Swift**

```swift
MSDistribute.setEnabled(false)
```
    
You can also check if the service is enabled or not using the `isEnabled` method:
  
**Objective-C**

```objectivec
BOOL enabled = [MSDistribute isEnabled];
```

**Swift**

```swift
var enabled = MSDistribute.isEnabled()
```

## 7. Advanced APIs

### Logging

You can control the amount of log messages by the SDK that show up. Use the `setLogLevel` API to enable additional logging while debugging. By default, it is set to `MSLogLevelAssert` for App Store environment, `MSLogLevelWarning` otherwise.

**Objective-C**

```objectivec
[MSMobileCenter setLogLevel:MSLogLevelVerbose];
```

**Swift**

```swift
MSMobileCenter.setLogLevel(MSLogLevel.Verbose)
```

### Get install identifier

The SDK creates a UUID for each device once the app is installed. This identifier remains the same for a device when the app is updated and a new one is generated only when the app is re-installed. The following API is useful for debugging purposes:

**Objective-C**

```objectivec
NSUUID *installId = [MSMobileCenter installId];
```

**Swift**

```swift
var installId = MSMobileCenter.installId()
```

### Enable/Disable the Mobile Center SDK

If you want the Mobile Center SDK to be disabled completely, use the `setEnabled` API. When disabled, the SDK will not forward any information to Mobile Center.

**Objective-C**
	
```objectivec
[MSMobileCenter setEnabled:NO];
```
	
**Swift**
	
```swift
MSMobileCenter.setEnabled(false)
```
        
## 8. Troubleshooting

* `Unable to find a specification for MobileCenter` error when using CocoaPods in your app?   
  
  If you are using Cocoapods to install Mobile Center in your app and run into an error with the message - `Unable to find a specification for MobileCenter`, run `pod repo update` in your terminal. It will sync the latest podspec files for you. Then try `pod install` which should install Mobile Center modules in your app.

* How long to wait for crashes to appear on the portal?   
  
  After restarting the app after the crash and with a working internet connection, the crash should appear on the portal within a few minutes. Note that the matching dSYM needs to be uploaded as well.

* Do I need to include all the modules? 
  
  No, you can just include Mobile Center modules that interests you but the `MobileCenter` module which contains logic for persistence, forwarding etc. is mandatory.

* Can't see crashes on the portal?   
   * Make sure SDK `start`-API is used correctly and the Crashes service is initialized. Also, you need to restart the app after a crash, and our SDK will forward the crash log only after it's restarted.
   * If you have been debugging your app, crash reporting won't work with a debugger attached because the presence of a debugger makes crash reporting impossible.
   * The user needs to upload the symbols that match the UUID of the build that triggered the crash.
   * Make sure your device is online.
   * Check if the App Secret used to start the SDK matches the App Secret in Mobile Center portal.
   * Don't use any other SDK that provides Crash Reporting functionality.

* What permissions or entitlements are required for the SDK?   
  
  Mobile Center SDK requires no permissions to be set in your app.
  
* The Alert that prompts users for an update doesn't contain strings, but just the keys for them?
  This means that the `MobileCenterDistributeResources.bundle` wasn't added to the project. Make sure you have drag'n'dropped the file into your xcode project, and it appears in your app target's `Copy Bundle Resources` build phase. The later should be the case if you have added the file through drag'n'drop – Xcode does it automatically for you. If the file is missing from the build phase, add it so it get's compiled into your app's bundle. 
  
* Engage with other MobileCenter users and developers on [StackOverflow](http://stackoverflow.com/questions/tagged/mobile-center).

## 9. Contributing

We're looking forward to your contributions via pull requests.

### 9.1 Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact opencode@microsoft.com with any additional questions or comments.

### 9.2 Contributor License

You must sign a [Contributor License Agreement](https://cla.microsoft.com/) before submitting your pull request. To complete the Contributor License Agreement (CLA), you will need to submit a request via the [form](https://cla.microsoft.com/) and then electronically sign the CLA when you receive the email containing the link to the document. You need to sign the CLA only once to cover submission to any Microsoft OSS project. 

## 10. Contact
If you have further questions or are running into trouble that cannot be resolved by any of the steps here, feel free to open a Github issue here or contact us at mobilecentersdk@microsoft.com.

