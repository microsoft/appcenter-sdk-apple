/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSChannelConfiguration.h"

static MSChannelConfiguration *MSChannelConfigurationDefault;
static MSChannelConfiguration *MSChannelConfigurationHigh;
static MSChannelConfiguration *MSChannelConfigurationBackground;

@implementation MSChannelConfiguration

- (instancetype)initWithPriorityName:(NSString *)name
                       flushInterval:(float)flushInterval
                      batchSizeLimit:(NSUInteger)batchSizeLimit
                 pendingBatchesLimit:(NSUInteger)pendingBatchesLimit {
  if (self = [super init]) {
    _name = name;
    _flushInterval = flushInterval;
    _batchSizeLimit = batchSizeLimit;
    _pendingBatchesLimit = pendingBatchesLimit;
  }
  return self;
}

+ (instancetype)configurationForPriority:(MSPriority)priority {
  switch (priority) {

  case MSPriorityMax:
    if (!MSChannelConfigurationHigh) {
      MSChannelConfigurationHigh = [[self alloc] initWithPriorityName:@"MSPriorityMax"
                                                         flushInterval:1.0
                                                        batchSizeLimit:10
                                                   pendingBatchesLimit:6];
    }
    return MSChannelConfigurationHigh;

  case MSPriorityBackground:
    if (!MSChannelConfigurationBackground) {
      MSChannelConfigurationBackground = [[self alloc] initWithPriorityName:@"MSPriorityBackground"
                                                               flushInterval:60.0
                                                              batchSizeLimit:100
                                                         pendingBatchesLimit:1];
    }
    return MSChannelConfigurationBackground;

  default:
    if (!MSChannelConfigurationDefault) {
      MSChannelConfigurationDefault = [[self alloc] initWithPriorityName:@"MSPriorityDefault"
                                                            flushInterval:3.0
                                                           batchSizeLimit:50
                                                      pendingBatchesLimit:3];
    }
    return MSChannelConfigurationDefault;
  }
}

@end
