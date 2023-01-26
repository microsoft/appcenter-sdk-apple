// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

@interface MSACNSLogQueueManager : NSObject

+ (MSACNSLogQueueManager *)sharedManager;
@property(nonatomic, strong) dispatch_queue_t loggerDispatchQueue;

@end
