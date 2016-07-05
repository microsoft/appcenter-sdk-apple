/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAStorage.h"
#import "AVAStorageBucket.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^enqueueCompletionBlock)(BOOL);

@interface AVAFileStorage : NSObject <AVAStorage>

/**
 * The directory for saving SDK related files within the app's folder.
 */
@property(nonatomic, copy) NSString *baseDirectoryPath;

/**
 * A dictionary containing file names and their status for certain storage keys.
 */
@property(nonatomic, strong)
    NSMutableDictionary<NSString *, AVAStorageBucket *> *buckets;

@end

NS_ASSUME_NONNULL_END
