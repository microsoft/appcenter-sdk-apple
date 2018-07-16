/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

static NSString *const kPUPLogTag = @"[Puppet]";
static NSString *const kPUPCustomizedUpdateAlertKey = @"kPUPCustomizedUpdateAlertKey";

// Analytics.
static NSString *const kWillSendEventLog = @"willSendEventLog";
static NSString *const kDidSucceedSendingEventLog = @"didSucceedSendingEventLog";
static NSString *const kDidFailSendingEventLog = @"didFailSendingEventLog";

static NSString *const kDidSentEventText = @"Sent event occurred";
static NSString *const kDidFailedToSendEventText = @"Failed to send event occurred";
static NSString *const kDidSendingEventText = @"Sending event occurred";

static NSString *const kMSChildTransmissionTargetTokenKey = @"kMSChildTransmissionTargetToken";
static NSString *const kMSTargetToken1 = @"602c2d529a824339bef93a7b9a035e6a-a0189496-cc3a-41c6-9214-b479e5f44912-6819";
static NSString *const kMSTargetToken2 = @"902923ebd7a34552bd7a0c33207611ab-a48969f4-4823-428f-a88c-eff15e474137-7039";
static NSString *const kMSRuntimeTargetToken = @"b9bb5bcb40f24830aa12f681e6462292-10b4c5da-67be-49ce-936b-8b2b80a83a80-7868";

// Crashes.
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
