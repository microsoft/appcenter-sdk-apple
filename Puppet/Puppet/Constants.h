/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

static NSString *const kPUPLogTag = @"[Puppet]";
static NSString *const kPUPCustomizedUpdateAlertKey = @"kPUPCustomizedUpdateAlertKey";

// Analytics
static NSString *const kWillSendEventLog = @"willSendEventLog";
static NSString *const kDidSucceedSendingEventLog = @"didSucceedSendingEventLog";
static NSString *const kDidFailSendingEventLog = @"didFailSendingEventLog";

static NSString *const kDidSentEventText = @"Sent event occurred";
static NSString *const kDidFailedToSendEventText = @"Failed to send event occurred";
static NSString *const kDidSendingEventText = @"Sending event occurred";

// Crashes
static NSString *const kShouldProcessErrorReportEvent = @"shouldProcessErrorReport";
static NSString *const kWillSendErrorReportEvent = @"willSendErrorReport";
static NSString *const kDidSucceedSendingErrorReportEvent = @"didSucceedSendingErrorReport";
static NSString *const kDidFailSendingErrorReportEvent = @"didFailSendingErrorReport";
static NSString *const kDidShouldAwaitUserConfirmationEvent = @"didShouldAwaitUserConfirmation";

static NSString *const kHasCrashedInLastSessionText = @"HasCrashedInLastSession == true";
static NSString *const kDidSendingErrorReportText = @"SendingErrorReport has occured";
static NSString *const kDidSentErrorReportText = @"SentErrorReport has occured";
static NSString *const kDidFailedToSendErrorReportText = @"FailedToSendErrorReport has occured";
static NSString *const kDidShouldProcessErrorReportText = @"ShouldProcessErrorReport has occured";
static NSString *const kDidShouldAwaitUserConfirmationText = @"ShouldAwaitUserConfirmation has occured";
