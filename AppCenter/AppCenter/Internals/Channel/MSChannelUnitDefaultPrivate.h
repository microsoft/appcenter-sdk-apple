// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSAuthTokenContextDelegate.h"
#import "MSChannelUnitDefault.h"

NS_ASSUME_NONNULL_BEGIN

@interface MSChannelUnitDefault () <MSAuthTokenContextDelegate>

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

/**
 * If we have flushInterval bigger than 3 seconds, we should subtract an oldest log's timestamp from it.
 * It is needed to avoid situations when the logs not being sent to server cause time interval is too big
 * for a typical user session.
 */
- (NSUInteger)resolveFlushInterval;

/**
 * @return Key for User Defaults file where an oldest log timestamp for this channel is stored.
 */
- (NSString *)startTimeKey;

@end

NS_ASSUME_NONNULL_END
