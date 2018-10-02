#import <Foundation/Foundation.h>

#import "MSIngestionProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSIngestionCall : NSObject

/**
 * Call delegate.
 */
@property(nonatomic, weak) id<MSIngestionCallDelegate> delegate;

/**
 * Whether the request to send data has been submitted or not.
 */
@property(nonatomic) BOOL submitted;

/**
 * Data object to be placed in request body.
 */
@property(nonatomic) NSObject *data;

/**
 * Unique call ID.
 */
@property(nonatomic, copy) NSString *callId;

/**
 * Call completion handler used for communicating with calling component.
 */
@property(nonatomic) MSSendAsyncCompletionHandler completionHandler;

/**
 * A timer source which is used to flush the queue after a certain amount of time.
 */
@property(nonatomic) dispatch_source_t timerSource;

/**
 * Number of retries performed for this call.
 */
@property(nonatomic) NSUInteger retryCount;

/**
 * Retry intervals for each retry.
 */
@property(nonatomic) NSArray *retryIntervals;

/**
 * Initialize a call with specified retry intervals.
 *
 * @param retryIntervals Retry intervals used in case of recoverable errors.
 *
 * @return A retriable call instance.
 */
- (id)initWithRetryIntervals:(NSArray *)retryIntervals;

/**
 * Indicate if the limit of maximum retries has been reached.
 *
 * @return YES if the limit of maximum retries has been reached, NO otherwise.
 */
- (BOOL)hasReachedMaxRetries;

/**
 * Reset and stop retrying.
 */
- (void)resetRetry;

/**
 * Call completed with error/success.
 *
 * @param ingestion ingestion object.
 * @param statusCode status code.
 * @param data response data.
 * @param error call error.
 */
- (void)ingestion:(id<MSIngestionProtocol>)ingestion
    callCompletedWithStatus:(NSUInteger)statusCode
                       data:(nullable NSData *)data
                      error:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
