/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

@class MSEventLog;
@class MSPageLog;
@class MSAnalytics;

@protocol MSAnalyticsDelegate <NSObject>

@optional

- (void)analytics:(MSAnalytics *)analytics willSendEventLog:(MSEventLog *)eventLog;

- (void)analytics:(MSAnalytics *)analytics didSucceedSendingEventLog:(MSEventLog *)eventLog;

- (void)analytics:(MSAnalytics *)analytics didFailSendingEventLog:(MSEventLog *)eventLog withError:(NSError *)error;

- (void)analytics:(MSAnalytics *)analytics willSendPageLog:(MSPageLog *)pageLog;

- (void)analytics:(MSAnalytics *)analytics didSucceedSendingPageLog:(MSPageLog *)pageLog;

- (void)analytics:(MSAnalytics *)analytics didFailSendingPageLog:(MSPageLog *)pageLog withError:(NSError *)error;

@end
