/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#import "AVAChannelConfiguration.h"

static AVAChannelConfiguration *AVAChannelConfigurationDefault;
static AVAChannelConfiguration *AVAChannelConfigurationHigh;
static AVAChannelConfiguration *AVAChannelConfigurationBackground;

@implementation AVAChannelConfiguration

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

+ (instancetype)configurationForPriority:(AVAPriority)priority {
  switch (priority) {

  case AVAPriorityHigh:
    if (!AVAChannelConfigurationHigh) {
      AVAChannelConfigurationHigh = [[self alloc] initWithPriorityName:@"AVAPriorityHigh"
                                                         flushInterval:3.0
                                                        batchSizeLimit:1
                                                   pendingBatchesLimit:6];
    }
    return AVAChannelConfigurationHigh;

  case AVAPriorityBackground:
    if (!AVAChannelConfigurationBackground) {
      AVAChannelConfigurationBackground = [[self alloc] initWithPriorityName:@"AVAPriorityBackground"
                                                               flushInterval:60.0
                                                              batchSizeLimit:100
                                                         pendingBatchesLimit:1];
    }
    return AVAChannelConfigurationBackground;

  default:
    if (!AVAChannelConfigurationDefault) {
      AVAChannelConfigurationDefault = [[self alloc] initWithPriorityName:@"AVAPriorityDefault"
                                                            flushInterval:30.0
                                                           batchSizeLimit:50
                                                      pendingBatchesLimit:3];
    }
    return AVAChannelConfigurationDefault;
  }
}

@end
