/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMErrorReport.h"
#import "SNMFeatureAbstract.h"

#import <UIKit/UIKit.h>

@class SNMCrashesDelegate;

/**
 * Custom block that handles the alert that prompts the user whether crash reports need to be processed or not.
 * @return Returns YES to discard crash reports, otherwise NO.
 */
typedef BOOL (^SNMUserConfirmationHandler)(NSArray<SNMErrorReport *> *_Nonnull errorReports);

/**
 * Error Logging status.
 */
typedef NS_ENUM(NSUInteger, SNMErrorLogSetting) {
  /**
   * Crash reporting is disabled.
   */
      SNMErrorLogSettingDisabled = 0,

  /**
   * User is asked each time before sending error logs.
   */
      SNMErrorLogSettingAlwaysAsk = 1,

  /**
   * Each error log is send automatically.
   */
      SNMErrorLogSettingAutoSend = 2
};

/**
 * Crash Manager alert user input
 */
typedef NS_ENUM(NSUInteger, SNMUserConfirmation) {
  /**
   * User chose not to send the crash report
   */
      SNMUserConfirmationDontSend = 0,
  /**
   * User wants the crash report to be sent
   */
      SNMUserConfirmationSend = 1,
  /**
   * User wants to send all error logs
   */
      SNMUserConfirmationAlways = 2
};

@protocol SNMCrashesDelegate;

@interface SNMCrashes : SNMFeatureAbstract

///-----------------------------------------------------------------------------
/// @name Helper
///-----------------------------------------------------------------------------

/**
 * Lets the app crash for easy testing of the SDK.
 *
 * The best way to use this is to trigger the crash with a button action.
 *
 * Make sure not to let the app crash in `applicationDidFinishLaunching` or any
 * other
 * startup method! Since otherwise the app would crash before the SDK could
 * process it.
 *
 * Note that our SDK provides support for handling crashes that happen early on
 * startup.
 * Check the documentation for more information on how to use this.
 *
 * If the SDK detects an App Store environment, it will _NOT_ cause the app to
 * crash!
 */
+ (void)generateTestCrash;

/**
 * Check if the app has crashed in the last session.
 *
 * @return Returns YES is the app has crashed in the last session.
 */
+ (BOOL)hasCrashedInLastSession;

/**
 * Provides details about the crash that occurred in the last app session
 */
+ (nullable SNMErrorReport *)lastSessionCrashReport;

/**
 * Set the delegate
 *
 * Defines the class that implements the optional protocol
 * `SNMCrashesDelegate`.
 *
 * @see SNMCrashesDelegate
 */
+ (void)setDelegate:(_Nullable id <SNMCrashesDelegate>)delegate;

/**
 * Set a user confirmation handler that is invoked right before processing crash reports to
 * determine whether sending crash reports or not.
 *
 * @param userConfirmationHandler A handler for user confirmation.
 * @see SNMUserConfirmationHandler
 */
+ (void)setUserConfirmationHandler:(_Nullable SNMUserConfirmationHandler)userConfirmationHandler;

/**
 * Notify SDK with a confirmation to handle the crash report.
 *
 * @param userConfirmation A user confirmation.
 * @see SNMUserConfirmation.
 */
+ (void)notifyWithUserConfirmation:(SNMUserConfirmation)userConfirmation;

@end
