#import <Foundation/Foundation.h>

#import "MSChannelConfiguration.h"
#import "MSEnable.h"
#import "MSLog.h"
#import "MSLogManagerDelegate.h"

@protocol MSChannelDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 * Defines A log manager which triggers and manages the processing of log items on different channels.
 */
@protocol MSLogManager <NSObject, MSEnable>

@optional

/**
 *  Add delegate.
 *
 *  @param delegate delegate.
 */
- (void)addDelegate:(id<MSLogManagerDelegate>)delegate;

/**
 *  Remove delegate.
 *
 *  @param delegate delegate.
 */
- (void)removeDelegate:(id<MSLogManagerDelegate>)delegate;

@required

/**
 * Initialize a channel with the given configuration.
 *
 * @param configuration channel configuration.
 */
- (void)initChannelWithConfiguration:(MSChannelConfiguration *)configuration;

/**
 * Change the base URL (schema + authority + port only) used to communicate with the backend.
 *
 * @param logUrl base URL to use for backend communication.
 */
- (void)setLogUrl:(NSString *)logUrl;

/**
 * Triggers processing of a new log item.
 *
 * @param log The log item that should be enqueued.
 * @param groupId The groupId for processing the log.
 */
- (void)processLog:(id<MSLog>)log forGroupId:(NSString *)groupId;

/**
 *  Enable/disable this instance and delete data on disabled state.
 *
 *  @param isEnabled  A boolean value set to YES to enable the instance or NO to disable it.
 *  @param deleteData A boolean value set to YES to delete data or NO to keep it.
 *  @param groupId A groupId to enable/disable.
 */
- (void)setEnabled:(BOOL)isEnabled andDeleteDataOnDisabled:(BOOL)deleteData forGroupId:(NSString *)groupId;

@end

NS_ASSUME_NONNULL_END
