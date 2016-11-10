[![Build Status](https://www.bitrise.io/app/e5b1a2ef546331fb.svg?token=Orwi_AVAExLTuN1ZAzvbFQ&branch=develop)](https://www.bitrise.io/app/e5b1a2ef546331fb)

# Mobile Center SDK for iOS

## Introduction

Add Mobile Center services to your app and collect crash reports and understand user behavior by analyzing the session, user and device information for your app. The SDK is currently in public preview and supports the following services:

1. **Analytics**: Mobile Center Analytics helps you understand user behavior and customer engagement to improve your iOS app. The SDK automatically captures session count, device properties like model, OS version etc. and pages. You can define your own custom events to measure things that matter to your business. All the information captured is available in the Mobile Center portal for you to analyze the data.

2. **Crashes**: The Mobile Center SDK will automatically generate a crash log every time your app crashes. The log is first written to the device's storage and when the user starts the app again, the crash report will be forwarded to Mobile Center. Collecting crashes works for both beta and live apps, i.e. those submitted to App Store. Crash logs contain viable information for you to help resolve the issue. Crashes uses PLCrashReporter 1.3.

This document contains the following sections:

1. [Prerequisites](#1-prerequisites)
2. [Integrate the SDK](#2-add-mobilecenter-sdk-modules)
3. [Start the SDK](#3-start-the-sdk)
4. [Analytics APIs](#4-analytics-apis)
5. [Crashes APIs](#5-crashes-apis)
6. [Advanced APIs](#6-advanced-apis)
7. [Troubleshooting](#7-troubleshooting)

Let's get started with setting up the Mobile Center SDK in your app to use these services.

## 1. Prerequisites

Before you begin, please make sure that the following prerequisites are met:

* An iOS project that is set up in Xcode 8.0 on macOS 10.11 or later.
* The minimum OS target supported by the Mobile Center SDK is iOS 8.0 or later.
* If you are using cocoapods, please use cocoapods 1.1.1 or later.
* This readme assumes that you are using Swift 3 syntax and want to integrate all services.

## 2. Integrate the SDK

The Mobile Center SDK is designed with a modular approach – you only need to integrate the modules of the services that you are interested in.

You can either integrate the MobileCenter SDK by adding it's binaries to your Xcode project (Step 2.1), or by using Cocoapods (Step 2.2).

### 2.1 Integration by copying the binaries into your project

Below are the steps on how to integrate the compiled libraries in your Xcode project to setup the Mobile Center SDK for your iOS app.

1. Download the [Mobile Center SDK](https://aka.ms/ehvc9e) frameworks provided as a zip file.

2. Unzip the file and you will see different frameworks for each Mobile Center service. There is a framework called `MobileCenter`, which is required in the project as it contains the logic for persistence, forwarding,... . 

3. Create a folder in your projects directory in Finder and drag it to Xcode:   
   * Let's create a folder called Vendor (if it doesn't exist) inside your project directory to include all the 3rd-party libraries.  
   * Once created, drag this Vendor folder into Xcode. A dialog will appear. Select "Create groups" and set the checkmark for "Add to targets" for your target. Then click Finish.
   
4. Add the SDK frameworks to the project in Xcode:
    * Make sure the Project Navigator is visible (⌘+1).
    * Now drag and drop `MobileCenter.framework`, `MobileCenterAnalytics.framework`, and `MobileCenterCrashes.framework` in the Vendor folder in Xcode using the Project Navigator on the left side. Note that `MobileCenter.framework` is required to start the SDK. So make sure it's added to your project, otherwise the other modules won't work and your app won't compile.
    * A dialog will appear again. Make sure that "Copy items if needed", "Create groups", and your app target are checked. Then click Finish.
    
Now that you've integrated the frameworks in your application, it's time to start the SDK and make use of the Mobile Center services.

### 2.2 Integration using Cocoapods

[CocoaPods](http://cocoapods.org/) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like Mobile Center in your projects. To learn how to setup CocoaPods for your project, visit [the official CocoaPods website](http://cocoapods.org/).

1. Add the following to your `podfile` to include all services into your app. This will pull in `MobileCenter`, `MobileCenterAnalytics` and `MobileCenterCrashes`. Alternatively, you can specify which services you want to use in your app. Each service has it's own `subspec` and they all rely on `MobileCenter`. It will get pulled in automatically.

	```ruby
 # Use the following line to use all services.
  pod 'MobileCenter', :podspec => 'https://mobilecentersdkdev.blob.core.windows.net/sdk/MobileCenter.podspec'
	  
 # Use the following lines if you want to specify the individual services you want to use.
pod 'MobileCenter/MobileCenterAnalytics', :podspec => 'https://mobilecentersdkdev.blob.core.windows.net/sdk/MobileCenter.podspec'
pod 'MobileCenter/MobileCenterCrashes', :podspec => 'https://mobilecentersdkdev.blob.core.windows.net/sdk/MobileCenter.podspec'
	
	```
	
	**NOTE:** If you are using the individual subspecs, you don't need to include `MobileCenter/MobileCenter' separately as the other subspecs will pull in this as a dependency anyway.

2. Run `pod install` to install your newly defined pod, open your `.xcworkspace` and it's time to start the SDK and make use of the Mobile Center services.

## 3. Start the SDK

To start the Mobile Center SDK in your app, follow these steps:

### 1. Add `import` statements  
You need to add import statements for MobileCenter, MobileCenterAnalytics and MobileCenterCrashes modules before starting the SDK. If you have chosen to only use a subset of Mobile Center's services, just add the import for MobileCenter and the one for the service that you want to use. 
    
**Objective-C**   
Open your AppDelegate.m file and add the following lines at the top of the file below your own import statements.   
    
```objectivec
@import MobileCenter;
@import MobileCenterAnalytics;
@import MobileCenterCrashes;
```

**Swift**   
Open your AppDelegate.swift file and add the following lines.   
    
```swift
import MobileCenter
import MobileCenterAnalytics
import MobileCenterCrashes
``` 

### 2. Start the SDK

Mobile Center provides you with three modules to get started: `MobileCenter` (required), `MobileCenterAnalytics` and `MobileCenterCrashes` (both are optional). In order to use Mobile Center services, you need to opt in for the module(s) that you'd like, meaning by default no modules are started and you will have to explicitly call each of them, both Analytics and Crashes, when starting the SDK.

**Objective-C** 

Add the following line to start the SDK in your app's AppDelegate.m class in the `application:didFinishLaunchingWithOptions:` method.  
    
```objectivec
[MSMobileCenter start:@"{Your App Secret}" withServices:@[[MSAnalytics class], [MSCrashes class]]];
```

**Swift**   

Insert the following line to start the SDK in your app's AppDelegate.swift class in the `application(_:didFinishLaunchingWithOptions:)` method.   
    
```swift
MSMobileCenter.start("{Your App Secret}", withServices: [MSAnalytics.self, MSCrashes.self])
```    
    
You can also copy paste the `start` method call from the Overview page on Mobile Center portal once your app is selected. It already includes the App Secret so that all the data collected by the SDK corresponds to your application. Make sure to replace `{Your App Secret}` text with the actual value for your application.
    
The example above shows how to use the `start` method and include both the Analytics and Crashes module. If you wish not to use Analytics, remove the parameter from the method call above. Note that, unless you explicitly specify each module as parameters in the start method, you can't use that Mobile Center service. Also, the `start` API can be used only once in the lifecycle of your app – all other calls will log a warning to the console and only the modules included in the first call will be available.

## 4. Analytics APIs

### Track Session, Device Properties

Once the Analytics module is included in your app and the SDK is started, it will automatically track sessions, device properties like OS version, model, manufacturer etc. and you don’t need to add any additional code.

Look at the section above on how to [Start the SDK](#3-start-the-sdk) if you haven't started it yet.

### Custom Events

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

You can change the enabled state of the Analytics module at runtime by calling the `setEnabled` method. If you disable it, the SDK will not collect any more analytics information for the app. To re-enable it, pass `true` as a parameter in the same method.

**Objective-C**

```objectivec
[MSAnalytics setEnabled:NO];
```

**Swift**

```swift
MSAnalytics.setEnabled(false)
```

You can also check if the module is enabled or not using the `isEnabled` method:

**Objective-C**

```objectivec
BOOL enabled = [MSAnalytics isEnabled];
```

**Swift**

```swift
var enabled = MSAnalytics.isEnabled()
```
    
## 5. Crashes APIs

Once you set up and start the Mobile Center SDK to use the Crashes module in your application, the SDK will automatically start logging any crashes in the devices local storage. When the user opens the application again after a crash, all pending crash logs will automatically be forwarded to Mobile Center and you can analyze the crash along with the stack trace on the Mobile Center portal. Refer to the section to [Start the SDK](#3-start-the-sdk) if you haven't done so already.

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

### Enable or disable the Crashes module

You can disable and opt out of using the Crashes module by calling the `setEnabled` API and the SDK will collect no more crashes for your app. Use the same API to re-enable it by passing `YES` or `true` as a parameter.

**Objective-C**

```objectivec
[MSCrashes setEnabled:NO];
```

**Swift**

```swift
MSCrashes.setEnabled(false)
```
    
You can also check if the module is enabled or not using the `isEnabled` method:

**Objective-C**

```objectivec
BOOL enabled = [MSCrashes isEnabled];
```

**Swift**

```swift
var enabled = MSCrashes.isEnabled()
```

### Advanced Scenarios

If you are using the Crashes service, you can customize the way the SDK handles crashes. The `MSCrashesDelegate`-protocol describes methods to attach data to a crash, wait for user confirmation and register for callbacks that inform your app about the sending status.

#### Register as a delegate. 

 **Objective-C**
 
```objectivec
[MSCrashes setDelegate:self];
```

**Swift**

```swift
MSCrashes.setDelegate(self)
```

The following delegate methods are provided.  
    
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
        
### User Confirmation

If user privacy is important to you, you might want to get a user's confirmation before sending a crash report to Mobile Center. The SDK exposes a callbacks where you can tell it to await user confirmation before sending any crash reports. This requires two steps:

#### 1. Set a user confirmation handler.
	
Your app is responsible for obtaining confirmation, e.g. through a dialog prompt with one of these options - "Always Send", "Send", and "Don't send". You need inform the SDK about the users input and the crash will handled accordingly. The method takes a block as a parameter, use it to pass in your logic to present the UI to confirm a crash report.

**Objective-C**
	
```objectivec
[MSCrashes setUserConfirmationHandler:(^(NSArray<MSErrorReport *> *errorReports) {
	// Your code to present your UI to the user, e.g. an UIAlertView.
	[[[UIAlertView alloc] initWithTitle:@"Sorry we crashed."
	                            message:@"Do you want to send a report about the crash to the developer?"
	                           delegate:self
	                  cancelButtonTitle:@"Don't send"
	                  otherButtonTitles:@"Always send", @"Send", nil] show];
	
	// 2. You could also iterate over the array of error reports and base your decision on them.
		
return YES; // Return YES if the SDK should await user confirmation, otherwise NO.
}
```
	
**Swift**
	
```swift
 // Crashes Delegate
MSCrashes.setUserConfirmationHandler({ (errorReports: [MSErrorReport]) in
	  
	// Your code to present your UI to the user, e.g. an UIAlertView.
	UIAlertView.init(title: "Sorry we crashed!", message: "Do you want to send a Crash Report?", delegate: self, cancelButtonTitle: "No", otherButtonTitles:"Always send", "Send").show()
	  
	return true // Return true if the SDK should await user confirmation, otherwise return false.
})
```

#### 2. Inform the SDK about the user's choice.
	    
If you return `YES`/`true` in step 1, your app should obtain user permission and message the SDK with the result using the following API. If you are using an alert for this, you would call it from within your implementation of the `alertView:clickedButtonAtIndex:`-callback.

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

### Attaching data to crashes

If you'd like to attach text/binary data to a crash report, implement this callback. Before sending the crash, the SDK will add the attachment to the report and you can view it on the Mobile Center portal.   

**Objective-C**

```objectivec
- (MSErrorAttachment *)attachmentWithCrashes:(MSCrashes *)crashes forErrorReport:(MSErrorReport *)errorReport {
  return [MSErrorAttachment attachmentWithText:@"Text Attachment"
                                  andBinaryData:[@"Hello World" dataUsingEncoding:NSUTF8StringEncoding]
                                       filename:@"binary.txt" mimeType:@"text/plain"];
}
```

**Swift**

```swift
func attachment(with crashes: MSCrashes!, for errorReport: MSErrorReport!) -> MSErrorAttachment! {
	let attachment = MSErrorAttachment.init(text: "TextAttachment", andBinaryData: (String("Hello World")?.data(using: String.Encoding.utf8))!, filename: "binary.txt", mimeType: "text/plain")
	return attachment
}

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
  

## 6. Advanced APIs

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

### Get Install Identifier

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
        
## 7. Troubleshooting

* How long to wait for Analytics data to appear on the portal?  

* How long to wait for crashes to appear on the portal?   
  After restarting the app after the crash and with a working internet connection, the crash should appear on the portal within a few minutes. Note that the matching dSYM needs to be uploaded as well.

* Do I need to include all the libraries? 
  No, you can just include Mobile Center modules that interests you but the core module which contains logic for persistence, forwarding etc. is mandatory.

* Can't see crashes on the portal?   
   * Make sure SDK `start()` API is used correctly and Crashes module is initialized. Also, you need to restart the app after a crash and our SDK will forward the crash log only after it's restarted.
   * The user needs to upload the symbols that match the UUID of the build that triggered the crash.
   * Make sure your device is connected to a working internet.
   * Check if the App Secret used to start the SDK matches the App Secret in Mobile Center portal.
   * Don't use any other SDK that provides Crash Reporting functionality.

* What data does SDK automatically collect for Analytics?

* What permissions are required for the SDK?   
  Mobile Center SDK requires no permissions to be set in your app.

* Any privacy information tracked by SDK?



