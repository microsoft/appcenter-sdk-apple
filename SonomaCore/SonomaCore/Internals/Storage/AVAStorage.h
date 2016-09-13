/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVALog.h"
#import "AVALogContainer.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^AVALoadDataCompletionBlock)(NSArray<AVALog> *logArray, NSString *batchId);

/**
 Defines the storage component which is responsible for file i/o and file
 management.
 */
@protocol AVAStorage <NSObject>

/*
 * Defines the maximum count of app log files per storage key on the file system.
 *
 * Default: 7
 */
@property(nonatomic) NSUInteger bucketFileCountLimit;

/*
 * Defines the maximum count of app logs per storage key in a file.
 *
 * Default: 50
 */
@property(nonatomic) NSUInteger bucketFileLogCountLimit;

@required

/**
 * Writes a log to the file system.
 *
 * param log The log item that should be written to disk
 * param storageKey The key used for grouping
 */
- (void)saveLog:(id<AVALog>)log withStorageKey:(NSString *)storageKey;

/**
 * Writes a log to the file system.
 *
 * param log The log item that should be written to disk
 * param storageKey The key used for grouping
 */
- (void)deleteLogsForId:(NSString *)logsId withStorageKey:(NSString *)storageKey;

/**
 * Returns the most recent logs for a given storage key.
 *
 * param storageKey The key used for grouping
 *
 * @return a list of logs
 */
- (void)loadLogsForStorageKey:(NSString *)storageKey withCompletion:(nullable AVALoadDataCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
