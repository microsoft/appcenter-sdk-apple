#import <Foundation/Foundation.h>

#import "MSEnable.h"
#import "MSIngestionCallDelegate.h"
#import "MSIngestionUtil.h"
#import "MS_Reachability.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MSIngestionDelegate;

@protocol MSIngestionProtocol <NSObject, MSIngestionCallDelegate, MSEnable>

/**
 * Reachability library.
 */
@property(nonatomic) MS_Reachability *reachability;

/**
 * A boolean value set to YES if the sender is suspended or NO otherwise.
 */
@property(nonatomic) BOOL suspended;

/**
 * Send data.
 *
 * @param data Instance that will be transformed to request body.
 * @param appSecret The app secret.
 * @param handler Completion handler.
 */
- (void)sendAsync:(nullable NSObject *)data appSecret:(nullable NSString *)appSecret completionHandler:(MSSendAsyncCompletionHandler)handler;

/**
 *  Add the given delegate to the sender.
 *
 *  @param delegate Sender's delegate.
 */
- (void)addDelegate:(id<MSIngestionDelegate>)delegate;

/**
 *  Delete the given delegate from the sender.
 *
 *  @param delegate Sender's delegate.
 */
- (void)removeDelegate:(id<MSIngestionDelegate>)delegate;

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
