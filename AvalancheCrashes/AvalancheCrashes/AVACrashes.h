/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <UIKit/UIKit.h>
#import "AVAFeature.h"

@class AVAErrorReport;

/**
 * Custom block that handles the alert that prompts the user whether he wants to send crash reports
 */
typedef void(^AVAUserConfirmationHandler)(NSArray<AVAErrorReport *> * _Nonnull errorReports);


/**
 * Error Logging status
 */
typedef NS_ENUM(NSUInteger, AVAErrorLogSetting) {
  /**
   *	Crash reporting is disabled
   */
  AVAErrorLogSettingDisabled = 0,
  /**
   *	User is asked each time before sending error logs
   */
  AVAErrorLogSettingAlwaysAsk = 1,
  /**
   *	Each error log is send automatically
   */
  AVAErrorLogSettingAutoSend = 2
};

/**
 * Crash Manager alert user input
 */
typedef NS_ENUM(NSUInteger, AVAErrorLoggingUserInput) {
  /**
   *  User chose not to send the crash report
   */
  AVAErrorLoggingUserInputDontSend = 0,
  /**
   *  User wants the crash report to be sent
   */
  AVAErrorLoggingUserInputSend = 1,
};

@protocol AVAErrorLoggingDelegate;


@interface AVACrashes: NSObject <AVAFeature>

/**
 Indicates if the app crash in the previous session
 
 Use this on startup, to check if the app starts the first time after it crashed
 previously. You can use this also to disable specific events, like asking
 the user to rate your app.
 
 @warning This property only has a correct value, once the sdk has been properly initialized!
 
 @see lastSessionCrashDetails
 */
@property (nonatomic, readonly) BOOL didCrashInLastSession;


///-----------------------------------------------------------------------------
/// @name Helper
///-----------------------------------------------------------------------------

/**
 *  Detect if a debugger is attached to the app process
 *
 *  This is only invoked once on app startup and can not detect if the debugger is being
 *  attached during runtime!
 *
 *  @return BOOL if the debugger is attached on app startup
 */
+ (BOOL)isDebuggerAttached;

/**
 * Lets the app crash for easy testing of the SDK
 *
 * The best way to use this is to trigger the crash with a button action.
 *
 * Make sure not to let the app crash in `applicationDidFinishLaunching` or any other
 * startup method! Since otherwise the app would crash before the SDK could process it.
 *
 * Note that our SDK provides support for handling crashes that happen early on startup.
 * Check the documentation for more information on how to use this.
 *
 * If the SDK detects an App Store environment, it will _NOT_ cause the app to crash!
 */
+ (void)generateTestCrash;

+ (BOOL)hasCrashedInLastSession;

/**
 Lets you set a custom block which handles showing a custom UI and asking the user
 whether he wants to send the crash report.
 
 You can use this to present any kind of user interface which asks the user for additional information,
 e.g. what they did in the app before the app crashed.
 
 In addition to this you should always ask your users if they agree to send crash reports, send them
 always or not at all and return the result when calling `handleUserInput:withUserProvidedCrashDescription`.
 
 @param alertViewHandler A block that is responsible for loading, presenting and and dismissing your custom user interface which prompts the user if he wants to send crash reports. The block is also responsible for triggering further processing of the crash reports.
 
 @warning Block needs to call the `[BITCrashManager handleUserInput:withUserProvidedMetaData:]` method!
 
 */
+ (void)setUserConfirmationHandler:(_Nullable AVAUserConfirmationHandler)userConfirmationHandler;


/**
 Provides an interface to pass user input from a custom alert to a crash report
 
 @param userInput Defines the users action wether to send, always send, or not to send the crash report.
 @param userProvidedMetaData The content of this optional BITCrashMetaData instance will be attached to the crash report and allows to ask the user for e.g. additional comments or info.
 
 @return Returns YES if the input is a valid option and successfully triggered further processing of the crash report
 
 @see AVAErrorLoggingUserInput
 */
+ (BOOL)handleUserInput:(AVAErrorLoggingUserInput)userInput;

/**
 * Provides details about the crash that occurred in the last app session
 */

+ (AVAErrorReport * _Nullable) lastSessionCrashDetails;


/**
 Set the delegate
 
 Defines the class that implements the optional protocol `AVAErrorLoggingDelegate`.
 
 @see AVAErrorLoggingDelegate

 */
@property (nonatomic, weak, nullable) id<AVAErrorLoggingDelegate> errorLoggingDelegate;


+ (void)setErrorLoggingDelegate:(_Nullable id <AVAErrorLoggingDelegate>) errorLoggingDelegate;

@end
 