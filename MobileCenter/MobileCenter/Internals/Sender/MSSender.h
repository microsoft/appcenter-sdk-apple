#import "MSEnable.h"
#import "MSSenderCallDelegate.h"
#import "MSSenderUtil.h"
#import "MS_Reachability.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MSSenderDelegate;

@protocol MSSender <NSObject, MSSenderCallDelegate, MSEnable>

/**
 *  Reachability library.
 */
@property(nonatomic) MS_Reachability *reachability;

/**
 * A boolean value set to YES if the sender is suspended or NO otherwise.
 */
@property(nonatomic) BOOL suspended;

/**
 * Initialize the Sender.
 *
 * @param baseUrl Base url.
 * @param apiPath Base API path.
 * @param headers Http headers.
 * @param queryStrings An array of query strings.
 * @param reachability Network reachability helper.
 * @param retryIntervals An array for retry intervals in second.
 */
- (id)initWithBaseUrl:(NSString *)baseUrl
              apiPath:(NSString *)apiPath
              headers:(NSDictionary *)headers
         queryStrings:(NSDictionary *)queryStrings
         reachability:(MS_Reachability *)reachability
       retryIntervals:(NSArray *)retryIntervals;

/**
 * Send logs in batch.
 *
 * @param data Instance that will be transformed to request body.
 * @param handler Completion handler.
 */
- (void)sendAsync:(NSObject *)data completionHandler:(MSSendAsyncCompletionHandler)handler;

/**
 *  Add the given delegate to the sender.
 *
 *  @param delegate Sender's delegate.
 */
- (void)addDelegate:(id<MSSenderDelegate>)delegate;

/**
 *  Delete the given delegate from the sender.
 *
 *  @param delegate Sender's delegate.
 */
- (void)removeDelegate:(id<MSSenderDelegate>)delegate;

/**
 * Suspend the sender.
 * A sender is suspended when it becomes disabled or on network issues.
 * A suspended state doesn't impact the current enabled state.
 * @see resume.
 */
- (void)suspend;

/**
 * Resume the sender.
 * @see suspend.
 */
- (void)resume;

@end

NS_ASSUME_NONNULL_END
