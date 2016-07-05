/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVAStorageBucket : NSObject

/**
 * The Id for the current batch.
 */
@property(nonatomic, copy) NSString *currentLogsId;

/**
 * The path to a file which contains events for the current batch.
 */
@property(nonatomic, copy) NSString *currentFilePath;

/**
 * A list of file names that are currently used by other components.
 */
@property(nonatomic, strong) NSMutableArray *blockedFiles;

/**
 * A list of file names that can be accessed by other components.
 */
@property(nonatomic, strong) NSMutableArray *availableFiles;

@end

NS_ASSUME_NONNULL_END
