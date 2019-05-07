// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import "MSChannelUnitConfiguration.h"

@implementation MSChannelUnitConfiguration

- (instancetype)initWithGroupId:(NSString *)groupId
                       priority:(MSPriority)priority
                  flushInterval:(float)flushInterval
                 batchSizeLimit:(NSUInteger)batchSizeLimit
            pendingBatchesLimit:(NSUInteger)pendingBatchesLimit {
  if ((self = [super init])) {
    _groupId = groupId;
    _priority = priority;
    _flushInterval = flushInterval;
    _batchSizeLimit = batchSizeLimit;
    _pendingBatchesLimit = pendingBatchesLimit;
  }
  return self;
}

- (instancetype)initWithGroupId:(NSString *)groupId flushInterval:(float)flushInterval {
  return [self initWithGroupId:groupId priority:MSPriorityDefault flushInterval:flushInterval batchSizeLimit:50 pendingBatchesLimit:3];
}

- (instancetype)initDefaultConfigurationWithGroupId:(NSString *)groupId {
  return [self initWithGroupId:groupId flushInterval:3.0];
}

@end
