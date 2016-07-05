/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVALog.h"
#import "AVALogContainer.h"
#import <Foundation/Foundation.h>

typedef void (^loadDataCompletionBlock)(NSArray<NSObject<AVALog> *> *,
                                        NSString *);

/**
 Defines the storage component which is responsible for file i/o and file
 management.
 */
@protocol AVAStorage <NSObject>

NS_ASSUME_NONNULL_BEGIN

/*
 * Defines the maximum count of app logs on the file system.
 *
 * Default: 300
 */
@property(nonatomic) NSUInteger fileCountLimit;

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
- (void)deleteLogsForId:(NSString *)logsId
         withStorageKey:(NSString *)storageKey;

/**
 * Returns the most recent logs for a given storage key.
 *
 * param storageKey The key used for grouping
 *
 * @return a list of logs
 */
- (void)loadLogsForStorageKey:(NSString *)storageKey
               withCompletion:(nullable loadDataCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
