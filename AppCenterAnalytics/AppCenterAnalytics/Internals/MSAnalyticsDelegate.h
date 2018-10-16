#import <Foundation/Foundation.h>

@class MSAnalytics;
@class MSEventLog;
@class MSPageLog;

@protocol MSAnalyticsDelegate <NSObject>

@optional

/**
 * Callback method that will be called before each event log is sent to the server.
 *
 * @param analytics The instance of MSAnalytics.
 * @param eventLog The event log that will be sent.
 */
- (void)analytics:(MSAnalytics *)analytics willSendEventLog:(MSEventLog *)eventLog;

/**
 * Callback method that will be called in case the SDK was able to send an event log to the server. Use this method to provide custom
 * behavior.
 *
 * @param analytics The instance of MSAnalytics.
 * @param eventLog The event log that App Center sent.
 */
- (void)analytics:(MSAnalytics *)analytics didSucceedSendingEventLog:(MSEventLog *)eventLog;

/**
 * Callback method that will be called in case the SDK was unable to send an event log to the server.
 *
 * @param analytics The instance of MSAnalytics.
 * @param eventLog The event log that App Center tried to send.
 * @param error The error that occurred.
 */
- (void)analytics:(MSAnalytics *)analytics didFailSendingEventLog:(MSEventLog *)eventLog withError:(NSError *)error;

/**
 * Callback method that will be called before each page log is sent to the server.
 *
 * @param analytics The instance of MSAnalytics.
 * @param pageLog The page log that will be sent.
 */
- (void)analytics:(MSAnalytics *)analytics willSendPageLog:(MSPageLog *)pageLog;

/**
 * Callback method that will be called in case the SDK was able to send a page log to the server. Use this method to provide custom
 * behavior.
 *
 * @param analytics The instance of MSAnalytics.
 * @param pageLog The page log that App Center sent.
 */
- (void)analytics:(MSAnalytics *)analytics didSucceedSendingPageLog:(MSPageLog *)pageLog;

/**
 * Callback method that will be called in case the SDK was unable to send a page log to the server.
 *
 * @param analytics The instance of MSAnalytics.
 * @param pageLog The page log that App Center tried to send.
 * @param error The error that occurred.
 */
- (void)analytics:(MSAnalytics *)analytics didFailSendingPageLog:(MSPageLog *)pageLog withError:(NSError *)error;

@end
