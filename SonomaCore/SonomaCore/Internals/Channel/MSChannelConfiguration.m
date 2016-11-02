/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "MSChannelConfiguration.h"

static MSChannelConfiguration *SNMChannelConfigurationDefault;
static MSChannelConfiguration *SNMChannelConfigurationHigh;
static MSChannelConfiguration *SNMChannelConfigurationBackground;

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

  case MSPriorityHigh:
    if (!SNMChannelConfigurationHigh) {
      SNMChannelConfigurationHigh = [[self alloc] initWithPriorityName:@"MSPriorityHigh"
                                                         flushInterval:3.0
                                                        batchSizeLimit:1
                                                   pendingBatchesLimit:6];
    }
    return SNMChannelConfigurationHigh;

  case MSPriorityBackground:
    if (!SNMChannelConfigurationBackground) {
      SNMChannelConfigurationBackground = [[self alloc] initWithPriorityName:@"MSPriorityBackground"
                                                               flushInterval:60.0
                                                              batchSizeLimit:100
                                                         pendingBatchesLimit:1];
    }
    return SNMChannelConfigurationBackground;

  default:
    if (!SNMChannelConfigurationDefault) {
      SNMChannelConfigurationDefault = [[self alloc] initWithPriorityName:@"MSPriorityDefault"
                                                            flushInterval:3.0
                                                           batchSizeLimit:50
                                                      pendingBatchesLimit:3];
    }
    return SNMChannelConfigurationDefault;
  }
}

@end
