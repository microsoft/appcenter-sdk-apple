#import <Foundation/Foundation.h>

#import "MSChannelUnitDefault.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSChannelUnitDefault ()

@property(nonatomic) NSHashTable *pausedIdentifyingObjects;

@property(nonatomic) NSMutableSet<NSString *> *pausedTargetKeys;

/**
 * Check any enqueued logs to send it to ingestion.
 */
- (void)checkPendingLogs;

/**
 * Synchronously pause operations, logs will be stored but not sent.
 *
 * @param identifyingObject Object used to identify the pause request.
 *
 * @discussion The same identifying object must be used to call resume.
 *
 * @see resumeWithIdentifyingObject:
 */
- (void)pauseWithIdentifyingObjectSync:(id<NSObject>)identifyingObject;

/**
 * Synchronously resume operations, logs can be sent again.
 *
 * @param identifyingObject Object used to passed to the pause method.
 *
 * @discussion The channel only resume when all the outstanding identifying objects have been resumed.
 *
 * @see pauseWithIdentifyingObject:
 */
- (void)resumeWithIdentifyingObjectSync:(id<NSObject>)identifyingObject;

@end

NS_ASSUME_NONNULL_END
