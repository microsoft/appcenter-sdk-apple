# Sonoma SDK for iOS

## Introduction

The Sonoma iOS SDK lets you add Sonoma services to your iOS application.

The SDK is currently in private beta release and we support the following services:

1. **Analytics**: Sonoma Analytics helps you understand user behavior and customer engagement to improve your Android app. The SDK automatically captures session count, device properties like model, OS Version etc. and pages. You can define your own custom events to measure things that matter
    to your business. All the information captured is available in the Sonoma portal for you to analyze the data.

2. **Error Reporting**: The Sonoma SDK will automatically generate a crash log every time your app crashes. The log is first written to the device's storage and when the user starts the app again, the crash report will be forwarded to Sonoma. Collecting crashes works for both beta and live apps, i.e. those submitted to Google Play or other app stores. Crash logs contain viable information for you to help resolve the issue. 

This document contains the following sections:

1. [Prerequisites](#1-prerequisites)
2. [Add Sonoma SDK modules](#2-add-sonoma-sdk-modules)
3. [Start the SDK](#3-start-the-sdk)
4. [Analytics APIs](#4-analytics-apis)
5. [Error Reporting APIs](#5-error-reporting-apis)
6. [Advanced APIs](#6-advanced-apis)
7. [Troubleshooting](#7-troubleshooting)

Let's get started with setting up Sonoma Android SDK in your app to use these services:

## 1. Prerequisites

Before you begin, please make sure that the following prerequisites are met:

* An iOS project that is set up in Xcode.
* SDK supports iOS 8.0 and later.

## 2. Add Sonoma SDK modules

The Sonoma SDK is designed with a modular approach – a developer only needs to integrate the modules of the services that they're interested in.

Below are the steps on how to integrate our compiled libraries in your Xcode project to setup Sonoma SDK for your iOS app.

1. Download the latest [Sonoma iOS SDK](http://bing.com) framework which is provided as a zip file.

2. Unzip the file and you will see a folder called Sonoma iOS SDK.

3. Copy the SDK into your projects directory in Finder: From our experience, 3rd-party libraries usually reside inside a subdirectory (let's call our subdirectory Vendor), so if you don't have your project organized with a subdirectory for libraries, now would be a great start for it. To continue our example, create a folder called Vendor inside your project directory and move the unzipped Sonoma-iOS-SDK folder into it.

4. Add the SDK to the project in Xcode
    * Make sure the Project Navigator is visible (⌘+1).
    * Drag & drop HockeySDK.embeddedframework from your Finder to the Vendor group in Xcode using the Project Navigator on the left side.
    * An overlay will appear. Select Create groups and set the checkmark for your target. Then click Finish.

Now that you've integrated the SDK in your application, it's time to start the SDK and make use of Sonoma services.

## 3. Start the SDK

To start the Sonoma SDK in your app, follow these steps:

1. **Get the App Secret of your application:** Before you call the API to start the SDK, you need to get your app specific Application Secret from the Sonoma portal that needs to be a part of the method call. This will make sure all the data collected by the SDK corresponds to your application.

    Go over to the Sonoma portal, click on "Microsoft Azure Project Sonoma". Under "My apps", click on the app that you want the SDK to set up for. Then click on "Manage app" and make note of the "App Secret" value.

2. **Start the SDK:**  Sonoma provides developers with two modules to get started – Analytics and Error Reporting. In order to use these modules, you need to opt in for the module(s) that you'd like, meaning by default no modules are started and you will have to explicitly call each of them when starting the SDK. Insert the following line inside your app's main activity class' `onCreate` callback.

    **Objective-C**
    ```objectivec
    Sonoma.start(getApplication(), "{Your App Secret}", Analytics.class, ErrorReporting.class);
    ```

    **Swift**
    ```swift
    Sonoma.start(getApplication(), "{Your App Secret}", Analytics.class, ErrorReporting.class);
    ```    
    
The example above shows how to use the `start()` method and include both the Analytics and Error Reporting module. If you wish not to use Analytics, remove the parameter from the method call above. Note that, unless you explicitly specify each module as parameters in the start method, you can't use that Sonoma service. Also, the `start()` API can be used only once in the lifecycle of your app – all other calls will log a warning to the console and only the modules included in the first call will be available.

## 4. Analytics APIs

* **Track Session, Device Properties:**  Once the Analytics module is included in your app and the SDK is started, it will automatically track sessions, device properties like OS Version, model, manufacturer etc. and you don’t need to add any additional code.
    Look at the section above on how to [Start the SDK](#3-start-the-sdk) if you haven't started it yet.

* **Custom Events:** You can track your own custom events with specific properties to know what's happening in your app, understand user actions, and see the aggregates in the Sonoma portal. Once you have started the SDK, use the `trackEvent()` method to track your events with properties.

    **Objective-C**
    ```objectivec
    Map<String, String> properties = new HashMap<String, String>();
    properties.put("Category", "Music");
    properties.put("FileName", "favorite.avi");

    Analytics.trackEvent("Video clicked", properties);
    ```

    **Swift**
    ```swift
     Map<String, String> properties = new HashMap<String, String>();
    properties.put("Category", "Music");
    properties.put("FileName", "favorite.avi");

    Analytics.trackEvent("Video clicked", properties);
    ```    
    
    Of course, properties for events are entirely optional – if you just want to track an event use this sample instead:

    **Objective-C**
    ```objectivec
    Analytics.trackEvent("Video clicked");
    ```

    **Swift**
    ```swift
    Analytics.trackEvent("Video clicked");
    ```

* **Enable or disable Analytics:**  You can change the enabled state of the Analytics module at runtime by calling the `Analytics.setEnabled()` method. If you disable it, the SDK will not collect any more analytics information for the app. To re-enable it, pass `true` as a parameter in the same method.

    **Objective-C**
    ```objectivec
    Analytics.setEnabled(false);
    ```

    **Swift**
    ```swift
    Analytics.setEnabled(false);
    ```

    You can also check, if the module is enabled or not using the `isEnabled()` method:

    **Objective-C**
    ```objectivec
    Analytics.isEnabled();
    ```

    **Swift**
    ```swift
    Analytics.isEnabled();
    ```
    
## 5. Error Reporting APIs

Once you set up and start the Sonoma SDK to use the Error Reporting module in your application, the SDK will automatically start logging any crashes in the device's local storage. When the user opens the application again, all pending crash logs will automatically be forwarded to Sonoma and you can analyze the crash along with the stack trace on the Sonoma portal. Refer to the section to [Start the SDK](#3-start-the-sdk) if you haven't done so already.

* **Generate a test crash:** The SDK provides you with a static API to generate a test crash for easy testing of the SDK:

    **Objective-C**
    ```objectivec
    ErrorReporting.generateTestCrash();
    ```

    **Swift**
    ```swift
    ErrorReporting.generateTestCrash();
    ```

    Note that this API can only be used in test/beta apps and won't work in production apps.

* **Did the app crash in last session:** At any time after starting the SDK, you can check if the app crashed in the previous session:

    **Objective-C**
    ```objectivec
    ErrorReporting.hasCrashedInLastSession();
    ```

    **Swift**
    ```swift
    ErrorReporting.hasCrashedInLastSession();
    ```

* **Details about the last crash:** If your app crashed previously, you can get details about the last crash:

    **Objective-C**
    ```objectivec
    ErrorReporting.getLastSessionErrorReport();
    ```

    **Swift**
    ```swift
    ErrorReporting.getLastSessionErrorReport();
    ```

* **Enable or disable the Error Reporting module:**  You can disable and opt out of using the ErrorReporting module by calling the `setEnabled()` API and the SDK will collect no crashes for your app. Use the same API to re-enable it by passing `true` as a parameter.

    **Objective-C**
    ```objectivec
    ErrorReporting.setEnabled(false);
    ```

    **Swift**
    ```swift
    ErrorReporting.setEnabled(false);
    ```
    
    You can also check if the module is enabled or not using the `isEnabled()` method:

    **Objective-C**
    ```objectivec
    ErrorReporting.isEnabled();
    ```

    **Swift**
    ```swift
    ErrorReporting.isEnabled();
    ```
  
## 6. Advanced APIs

* **Debugging**: You can control the amount of log messages that show up from the Sonoma SDK in LogCat. Use the `Sonoma.setLogLevel()` API to enable additional logging while debugging. The log levels correspond to the ones defined in `android.util.Log`. By default, it is set it to `ASSERT`.

    **Objective-C**
    ```objectivec
    Sonoma.setLogLevel(Log.VERBOSE);
    ```

    **Swift**
    ```swift
    Sonoma.setLogLevel(Log.VERBOSE);
    ```

* **Get Install Identifier**: The Sonoma SDK creates a UUID for each device once the app is installed. This identifier remains the same for a device when the app is updated and a new one is generated only when the app is re-installed. The following API is useful for debugging purposes:

    **Objective-C**
    ```objectivec
    UUID installId = Sonoma.getInstallId();
    ```

    **Swift**
    ```swift
    UUID installId = Sonoma.getInstallId();
    ```

* **Enable/Disable Sonoma SDK:** If you want the Sonoma SDK to be disabled completely, use the `setEnabled()` API. When disabled, the SDK will collect no more information for any of the modules that were added:

    **Objective-C**
    ```objectivec
    Sonoma.setEnabled(false);
    ```

    **Swift**
    ```swift
    Sonoma.setEnabled(false);
    ```
        
## 7. Troubleshooting

* How long to wait for Analytics data to appear on the portal?

* How long to wait for crashes to appear on the portal?

* Do I need to include all the libraries? Is there anything included by default?  
  No, you can just include Sonoma modules that interests you. Once you integrate any module, Sonoma Core module will be included by default which contains logic for persistence, forwarding etc.

* Can't see crashes on the portal

* Check if the App Secret used to start the SDK matches the App Secret in Sonoma portal.

* What data does SDK automatically collect for Analytics?

* What permissions are required for the SDK?

* Any privacy information tracked by SDK?




