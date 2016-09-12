/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "SNMStorage.h"
#import "SNMStorageBucket.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SNMFileStorage : NSObject <SNMStorage>

/**
 * The directory for saving SDK related files within the app's folder.
 */
@property(nonatomic, copy) NSString *baseDirectoryPath;

/**
 * A dictionary containing file names and their status for certain storage keys.
 */
@property(nonatomic, strong) NSMutableDictionary<NSString *, SNMStorageBucket *> *buckets;

/**
 * Returns the file path to a log file based on its id and storage key.
 *
 * @param storageKey A storage key which identifies the group/priority of the
 * log file
 * @param logsId The internal Id of the file
 *
 * @return the file path
 */
- (NSString *)filePathForStorageKey:(NSString *)storageKey logsId:(NSString *)logsId;

/**
 * Returns the bucket for a given storage key or creates a new one if it doesn't exist, yet.
 *
 * @param storageKey The storage key for the bucket.
 *
 * @return The bucket for a given storage key.
 */
- (SNMStorageBucket *)bucketForStorageKey:(NSString *)storageKey;

@end

NS_ASSUME_NONNULL_END
